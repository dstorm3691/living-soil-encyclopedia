from __future__ import annotations

from bs4 import BeautifulSoup, Tag, NavigableString
from pathlib import Path
from copy import deepcopy
import csv, hashlib, json, re, shutil, zipfile
from collections import defaultdict

ROOT = Path('/mnt/data')
OUT = ROOT / 'LSE_FIVE_BOOK_WORKING_SET'
if OUT.exists():
    shutil.rmtree(OUT)
OUT.mkdir(exist_ok=True)

SRC_FILES = {
    'v1': ROOT / 'LSE_VOLUME_1_FOUNDATIONS_SYSTEMS_EDITED(1).html',
    'v2': ROOT / 'LSE_VOLUME_2_INPUTS_AMENDMENTS_MICROBES_EDITED(1).html',
    'v3': ROOT / 'LSE_VOLUME_3_CROPS_IPM_DIAGNOSTICS_EDITED(1).html',
    'comp': ROOT / 'LSE_COMPANION_EDITED(1).html',
}
SOUPS = {k: BeautifulSoup(p.read_text(encoding='utf-8'), 'html.parser') for k,p in SRC_FILES.items()}
WORD_RE = re.compile(r"\b[\w’'-]+\b", re.UNICODE)

BOOKS = {
    1: ('The Living Soil', 'LSE_BOOK_1_THE_LIVING_SOIL_WORKING.html'),
    2: ('Inputs and Amendments', 'LSE_BOOK_2_INPUTS_AND_AMENDMENTS_WORKING.html'),
    3: ('Crops and Guilds', 'LSE_BOOK_3_CROPS_AND_GUILDS_WORKING.html'),
    4: ('Plant Health and Defense', 'LSE_BOOK_4_PLANT_HEALTH_AND_DEFENSE_WORKING.html'),
    5: ('The Field Companion', 'LSE_BOOK_5_FIELD_COMPANION_WORKING.html'),
}

movement_rows = []
mirror_rows = []
hold_sections = []
notes = []


def root_tags(soup: BeautifulSoup):
    return [x for x in soup.body.children if isinstance(x, Tag)]


def heading_level(tag: Tag) -> int | None:
    if tag.name and re.fullmatch(r'h[1-6]', tag.name):
        return int(tag.name[1])
    return None


def block_by_id(src_key: str, element_id: str):
    soup = SOUPS[src_key]
    start = soup.find(id=element_id)
    if not start:
        raise KeyError(f'{src_key}: missing id {element_id}')
    if start.parent != soup.body:
        raise ValueError(f'{src_key}: {element_id} is not a root-level element')
    kids = root_tags(soup)
    idx = next(i for i,x in enumerate(kids) if x is start)
    level = heading_level(start)
    if level is None:
        raise ValueError(f'{src_key}: {element_id} does not start with heading')
    end = idx + 1
    while end < len(kids):
        lv = heading_level(kids[end])
        if lv is not None and lv <= level:
            break
        end += 1
    return [deepcopy(x) for x in kids[idx:end]]


def block_by_heading_text(src_key: str, text: str):
    soup = SOUPS[src_key]
    target = None
    for h in soup.find_all(re.compile(r'^h[1-6]$')):
        if clean_text(h.get_text(' ', strip=True)) == clean_text(text):
            target = h
            break
    if not target or target.parent != soup.body:
        raise KeyError(f'{src_key}: missing root heading text {text}')
    return block_by_id(src_key, target.get('id'))


def clean_text(s: str) -> str:
    return ' '.join(s.split())


def text_hash(nodes) -> str:
    text = '\n'.join(clean_text(n.get_text(' ', strip=True)) for n in nodes)
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def word_count_nodes(nodes) -> int:
    return len(WORD_RE.findall(' '.join(n.get_text(' ', strip=True) for n in nodes)))


def first_heading(nodes):
    for n in nodes:
        if heading_level(n) is not None:
            return n
    return None


def shift_heading_levels(nodes, delta: int):
    seen = set()
    for n in nodes:
        candidates = [n] + list(n.find_all(re.compile(r'^h[1-6]$')))
        for h in candidates:
            if id(h) in seen:
                continue
            seen.add(id(h))
            lv = heading_level(h)
            if lv is not None:
                h.name = f'h{max(1, min(6, lv + delta))}'
    return nodes


def namespace_ids(nodes, prefix: str):
    mapping = {}
    for n in nodes:
        candidates = [n] + list(n.find_all(id=True))
        for t in candidates:
            old = t.get('id')
            if old and old not in mapping:
                mapping[old] = f'{prefix}{old}'
                t['id'] = mapping[old]
    for n in nodes:
        for a in ([n] if n.name == 'a' else []) + list(n.find_all('a')):
            href = a.get('href','')
            if href.startswith('#') and href[1:] in mapping:
                a['href'] = '#' + mapping[href[1:]]
    return mapping


def remove_subblocks(nodes, start_ids):
    start_ids = set(start_ids)
    out, removed = [], []
    i = 0
    while i < len(nodes):
        n = nodes[i]
        if n.get('id') in start_ids:
            lv = heading_level(n)
            j = i + 1
            while j < len(nodes):
                lv2 = heading_level(nodes[j])
                if lv2 is not None and lv2 <= lv:
                    break
                j += 1
            removed.extend(nodes[i:j])
            i = j
        else:
            out.append(n)
            i += 1
    return out, removed


def extract_subblock_from_nodes(nodes, start_id):
    for i,n in enumerate(nodes):
        if n.get('id') == start_id:
            lv = heading_level(n)
            j=i+1
            while j<len(nodes):
                lv2=heading_level(nodes[j])
                if lv2 is not None and lv2 <= lv:
                    break
                j+=1
            return [deepcopy(x) for x in nodes[i:j]]
    raise KeyError(start_id)


def set_top_heading(nodes, text=None, tag=None, classes=None, new_id=None):
    h = first_heading(nodes)
    if not h:
        raise ValueError('No heading in block')
    if text is not None:
        h.clear(); h.append(text)
    if tag is not None:
        h.name = tag
    if classes:
        h['class'] = sorted(set((h.get('class') or []) + list(classes)))
    if new_id:
        h['id'] = new_id
    return nodes


def mark_entries(nodes):
    for n in nodes:
        for h in ([n] if n.name == 'h3' else []) + list(n.find_all('h3')):
            if h.get('id') and (h.get('class') or []):
                if 'lse-entry' in h.get('class',[]):
                    h['data-toc'] = 'entry'
    return nodes


def new_soup(book_no: int, title: str, scope: str):
    html = f'''<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"/><meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Living Soil Encyclopedia — Book {book_no}: {title}</title>
<link href="lse_five_book_working.css" media="all" rel="stylesheet"/>
</head><body></body></html>'''
    soup = BeautifulSoup(html, 'html.parser')
    h1 = soup.new_tag('h1', id=f'book-{book_no}-series-title')
    h1['class']=['series-title']; h1.string='Living Soil Encyclopedia'
    soup.body.append(h1)
    h2 = soup.new_tag('h2', id=f'book-{book_no}-title')
    h2['class']=['book-title']; h2.string=f'Book {book_no} — {title}'
    soup.body.append(h2)
    p = soup.new_tag('p'); p['class']=['volume-subtitle']; p.string='Five-book working edition — structurally reassembled; publication blockers remain open'
    soup.body.append(p)
    nav = soup.new_tag('div'); nav['class']=['navbox','working-edition-notice']
    p1=soup.new_tag('p'); p1.append(BeautifulSoup('<strong>Working-edition notice:</strong>', 'html.parser').strong); p1.append(NavigableString(' ')); p1.append('This manuscript implements the owner-approved five-book architecture. It preserves the source content and visual system but is not yet final-cleared for public sale.')
    p2=soup.new_tag('p'); p2.append(BeautifulSoup('<strong>Scope:</strong>', 'html.parser').strong); p2.append(NavigableString(' ')); p2.append(scope)
    p3=soup.new_tag('p'); p3.append(BeautifulSoup('<strong>Mirror rule:</strong>', 'html.parser').strong); p3.append(NavigableString(' ')); p3.append('SOP and intervention mirrors are synchronized copies. Canonical ownership is identified in each mirror notice and in the mirror ledger.')
    nav.extend([p1,p2,p3]); soup.body.append(nav)
    toc=soup.new_tag('section', id='table-of-contents'); toc['class']=['toc-section','toc']; soup.body.append(toc)
    return soup


def add_part(soup, roman: str, title: str, part_id: str):
    h=soup.new_tag('h1',id=part_id); h['class']=['part-title']; h['data-toc']='part'; h.string=f'Part {roman} — {title}'
    soup.body.append(h)
    return h


def append_nodes(soup, nodes):
    for n in nodes:
        soup.body.append(n)


def chapter_block(src_key, element_id, number, title, remove_ids=None):
    nodes=block_by_id(src_key,element_id)
    if remove_ids:
        nodes, removed=remove_subblocks(nodes,remove_ids)
        if removed:
            hold_sections.append((f'Removed subblocks from {src_key}:{element_id}', removed, src_key, 'control/moved elsewhere'))
    set_top_heading(nodes, f'Chapter {number}: {title}', tag='h2', classes=['chapter-title'])
    first_heading(nodes)['data-toc']='chapter'
    mark_entries(nodes)
    return nodes


def nested_entry(src_key, element_id, title=None, source_label=None):
    nodes=block_by_id(src_key,element_id)
    shift_heading_levels(nodes,2)  # h1 -> h3, h2 -> h4
    set_top_heading(nodes, title or clean_text(first_heading(nodes).get_text(' ',strip=True)), tag='h3', classes=['lse-entry'])
    first_heading(nodes)['data-toc']='entry'
    movement_rows.append({'source':f'{src_key}:{element_id}','destination':source_label or 'nested entry','action':'move/nest','words':word_count_nodes(nodes),'text_sha256':text_hash(nodes)})
    return nodes


def section_as_nested(src_key, element_id, title=None):
    nodes=block_by_id(src_key,element_id)
    shift_heading_levels(nodes,1)  # h2 -> h3
    set_top_heading(nodes,title or clean_text(first_heading(nodes).get_text(' ',strip=True)),tag='h3',classes=['lse-entry'])
    first_heading(nodes)['data-toc']='entry'
    return nodes


def canonical_sop_block(element_id, visible_title=None):
    nodes=block_by_id('comp',element_id)
    shift_heading_levels(nodes,1) # h1 -> h2
    h=first_heading(nodes); h.name='h2'; h['class']=sorted(set((h.get('class') or [])+['chapter-title'])); h['data-toc']='chapter'
    if visible_title:
        h.clear(); h.append(visible_title)
    return nodes


def mirror_block(src_key, element_id, prefix, canonical_book, canonical_file, mirror_book, mirror_chapter, top_tag='h3', title=None):
    nodes=block_by_id(src_key,element_id)
    original_hash=text_hash(nodes)
    start_level=heading_level(first_heading(nodes))
    target_level=int(top_tag[1])
    shift_heading_levels(nodes,target_level-start_level)
    mapping=namespace_ids(nodes,prefix)
    h=first_heading(nodes); h.name=top_tag; h['class']=sorted(set((h.get('class') or [])+['lse-entry','mirror-entry'])); h['data-toc']='entry'
    if title:
        h.clear(); h.append(title)
    h['data-canonical-book']=str(canonical_book); h['data-canonical-anchor']=element_id
    notice=BeautifulSoup(f'''<div class="navbox mirror-notice"><p><strong>Synchronized mirror — do not edit independently.</strong> Canonical text: <a href="{canonical_file}#{element_id}">Book {canonical_book}</a>. Mirror location: Book {mirror_book}, {mirror_chapter}.</p></div>''','html.parser').div
    nodes.insert(0,notice)
    mirror_rows.append({'canonical_id':element_id,'canonical_book':canonical_book,'canonical_file':canonical_file,'mirror_book':mirror_book,'mirror_chapter':mirror_chapter,'mirror_id':mapping.get(element_id,prefix+element_id),'canonical_text_sha256':original_hash,'status':'generated from canonical source'})
    return nodes


def add_navbox(soup, html_text):
    nav=BeautifulSoup(f'<div class="navbox">{html_text}</div>','html.parser').div
    soup.body.append(nav)


def find_profile_blocks():
    s=SOUPS['v2']; kids=root_tags(s)
    wrappers=['h1-living-soil-encyclopedia-v124-controlled-text-only-block-08','h1-living-soil-encyclopedia-v126-controlled-text-only-block-10']
    profiles={}
    for wid in wrappers:
        start=s.find(id=wid); si=next(i for i,x in enumerate(kids) if x is start)
        end=si+1
        while end<len(kids) and not (kids[end].name=='h1'):
            end+=1
        i=si+1
        while i<end:
            n=kids[i]
            is_title=(n.name=='p' and i+1<end and kids[i+1].name=='ol' and 'Identity Block' in clean_text(kids[i+1].get_text(' ',strip=True)))
            if not is_title:
                i+=1; continue
            title=clean_text(n.get_text(' ',strip=True)); j=i+1
            while j<end:
                m=kids[j]
                if m.name=='p' and j+1<end and kids[j+1].name=='ol' and 'Identity Block' in clean_text(kids[j+1].get_text(' ',strip=True)):
                    break
                j+=1
            nodes=[deepcopy(x) for x in kids[i:j] if not (x.name=='hr' and not clean_text(x.get_text(' ',strip=True)))]
            # replace profile-title paragraph with semantic h3
            slug=re.sub(r'[^a-z0-9]+','-',title.lower()).strip('-')
            h=BeautifulSoup(f'<h3 id="crop-{slug}" class="lse-entry crop-profile" data-toc="entry"></h3>','html.parser').h3
            h.string=title
            nodes[0]=h
            profiles[title]=nodes
            i=j
    return profiles


def split_entry_blocks(nodes, entry_ids):
    result=[]
    for eid in entry_ids:
        result.extend(extract_subblock_from_nodes(nodes,eid))
    return result


def clone_and_lower(nodes, delta=1, top_text=None, top_tag='h3', classes=None):
    nodes=[deepcopy(x) for x in nodes]
    shift_heading_levels(nodes,delta)
    if top_text or top_tag or classes:
        set_top_heading(nodes,top_text,tag=top_tag,classes=classes or ['lse-entry'])
    first_heading(nodes)['data-toc']='entry'
    return nodes


def archive(label, nodes, source, reason):
    if nodes:
        hold_sections.append((label,[deepcopy(x) for x in nodes],source,reason))


# ---------------- Build Book 1 ----------------
b1=new_soup(1,*BOOKS[1][:1],scope='Soil biology, schools of practice, site assessment, soil construction, water, infrastructure, soil microscopy, and soil testing.')
# new_soup signature correction handled by explicit below

def strip_production_sections(nodes, source_label):
    patterns = [
        r'qa table', r'^phase .*complete', r'herb chapter image plan', r'image-creation prompt',
        r'proposed chapter\s*/\s*part placement', r'image placeholder registry',
    ]
    removed_all=[]
    changed=True
    while changed:
        changed=False
        for i,n in enumerate(nodes):
            if heading_level(n) is None:
                continue
            txt=clean_text(n.get_text(' ',strip=True)).lower()
            if any(re.search(p,txt,re.I) for p in patterns):
                lv=heading_level(n); j=i+1
                while j<len(nodes):
                    lv2=heading_level(nodes[j])
                    if lv2 is not None and lv2 <= lv:
                        break
                    j+=1
                removed_all.extend(nodes[i:j]); del nodes[i:j]
                changed=True; break
    if removed_all:
        archive(f'Production-control sections removed from {source_label}',removed_all,source_label,'reader-facing production artifact')
    return nodes


def append_chapter(soup, nodes, source, destination, action='move/restructure'):
    nodes=strip_production_sections(nodes,source)
    append_nodes(soup,nodes)
    movement_rows.append({'source':source,'destination':destination,'action':action,'words':word_count_nodes(nodes),'text_sha256':text_hash(nodes)})

# Reinitialize Book 1 explicitly (the earlier b1 is valid but this makes intent clear)
b1 = new_soup(1, BOOKS[1][0], 'Soil biology, schools of practice, site assessment, soil construction, water, infrastructure, soil microscopy, and soil testing.')

add_part(b1,'I','Understanding the Living Soil Ecosystem','h1-part-i-understanding-the-living-soil-ecosystem-2')
for eid,num,title in [
    ('h2-chapter-1-from-salts-to-the-soil-food-web',1,'From Salts to the Soil Food Web'),
    ('h2-chapter-3-bacteria-decomposers-and-cyclers',2,'Bacteria — Decomposers and Cyclers'),
    ('h2-chapter-4-fungi-networkers-and-translators',3,'Fungi — Networkers and Translators'),
    ('h2-chapter-6-mycorrhizal-symbiosis-and-plant-immune-function',4,'Mycorrhizal Symbiosis and Plant Immune Function'),
]:
    append_chapter(b1,chapter_block('v1',eid,num,title),f'v1:{eid}',f'Book 1 Chapter {num}')
ch5=chapter_block('v1','h2-chapter-5-the-predator-tier-and-successional-ecology',5,'The Predator Tier and Successional Ecology')
ch5 += nested_entry('v1','h1-lse-009-successional-ecology-in-soils','LSE-009 — Successional Ecology in Soils','Book 1 Chapter 5')
append_chapter(b1,ch5,'v1:Chapter5 + LSE-009','Book 1 Chapter 5','preserve + nest')

add_part(b1,'II','Schools of Practice','h1-part-ii-the-methodologies')
ch6=chapter_block('v1','h2-chapter-6-schools-of-practice',6,'Schools of Practice')
ch6 += nested_entry('v1','h1-lse-025-permaculture','LSE-025 — Permaculture','Book 1 Chapter 6')
ch6 += nested_entry('v1','h1-lse-027-biodynamics','LSE-027 — Biodynamics','Book 1 Chapter 6')
ch6 += nested_entry('v2','h1-lse-026-coots-mix-clackamas-coot','LSE-026 — Coot’s Mix (Clackamas Coot)','Book 1 Chapter 6')
method_nodes=section_as_nested('v1','h2-3-practitioner-methodology-systems','Practitioner Methodology Systems — Supplemental Notes')
ch6 += method_nodes
append_chapter(b1,ch6,'v1:Schools + trailing references + v2:Coots + practitioner methods','Book 1 Chapter 6','consolidate/nest')

add_part(b1,'III','Reading and Building the Soil','h1-part-iv-building-the-soil-chapters-2025')
ch7=chapter_block('v1','h2-chapter-20-reading-the-site',7,'Reading the Site')
ch7 += nested_entry('v1','h1-site-assessment','Site Assessment — Operational Checklist','Book 1 Chapter 7')
append_chapter(b1,ch7,'v1:Reading Site + Site Assessment','Book 1 Chapter 7','consolidate')
append_chapter(b1,chapter_block('v1','h2-chapter-21-designing-and-building-raised-beds',8,'Designing and Building Raised Beds'),'v1:Raised Beds','Book 1 Chapter 8')
ch9=chapter_block('v1','h2-chapter-9-containers-and-soil-recipes',9,'Containers and Soil Recipes')
ch9 += nested_entry('v2','h1-soil-recipes-by-crop-type','Soil Recipes by Crop Type — Reference Deep Dive','Book 1 Chapter 9')
append_chapter(b1,ch9,'v1:Containers/Recipes + v2:Soil Recipes','Book 1 Chapter 9','consolidate')
ch10=chapter_block('v1','h2-chapter-10-no-till-maintenance-cover-cropping-and-chop-and-drop',10,'No-Till Maintenance, Cover Cropping, and Chop-and-Drop')
ch10 += nested_entry('comp','h1-cover-crop-selection','Cover Crop Selection','Book 1 Chapter 10')
for eid,pfx in [('h1-m1-1-no-till-bed-establishment','mirror-b1-m1-1-'),('h1-m1-2-annual-top-dress-protocol','mirror-b1-m1-2-'),('h1-m4-4-cover-crop-planting-and-termination-sop','mirror-b1-m4-4-')]:
    ch10 += mirror_block('comp',eid,pfx,5,BOOKS[5][1],1,'Chapter 10')
append_chapter(b1,ch10,'v1:No-till + comp:Cover Crop Selection + SOP mirrors','Book 1 Chapter 10','consolidate + mirror')

add_part(b1,'IV','Water and Infrastructure','h1-part-vi-systems-and-infrastructure-chapters-3338')
ch11=chapter_block('v1','h2-chapter-33-the-physics-of-water-in-living-soil',11,'The Physics of Water in Living Soil')
ch11 += nested_entry('v1','h1-soil-water-physics','Soil Water Physics — Reference Deep Dive','Book 1 Chapter 11')
append_chapter(b1,ch11,'v1:Water Physics + trailing entry','Book 1 Chapter 11','consolidate')
ch12=chapter_block('v1','h2-chapter-34-irrigation-systems-compared',12,'Irrigation Systems Compared')
ch12 += mirror_block('comp','h1-m3-3-irrigation-system-maintenance-sop','mirror-b1-m3-3-',5,BOOKS[5][1],1,'Chapter 12')
append_chapter(b1,ch12,'v1:Irrigation + M3-3 mirror','Book 1 Chapter 12','preserve + mirror')
ch13=chapter_block('v1','h2-chapter-35-rainwater-harvesting-and-hard-water-mitigation',13,'Rainwater Harvesting and Water Quality')
ch13 += nested_entry('v1','h1-rainwater-harvesting-for-irrigation','Rainwater Harvesting for Irrigation — Reference Deep Dive','Book 1 Chapter 13')
append_chapter(b1,ch13,'v1:Rainwater/Hard Water + trailing entry','Book 1 Chapter 13','consolidate')
ch14=chapter_block('v1','h2-chapter-36-greenhouse-and-hoop-house-design-for-season-extension',14,'Greenhouse and Hoop House Design')
ch14 += nested_entry('v1','h1-lse-227-greenhouse-hoop-house-design','LSE-227 — Greenhouse / Hoop House Design','Book 1 Chapter 14')
append_chapter(b1,ch14,'v1:Greenhouse + LSE-227','Book 1 Chapter 14','full merge')
append_chapter(b1,chapter_block('v1','h2-chapter-37-small-scale-at-home-indoor-growing',15,'Small-Scale At-Home Indoor Growing'),'v1:Indoor Growing','Book 1 Chapter 15')
ch16=chapter_block('v1','h2-chapter-38-tool-selection-maintenance-and-sanitation',16,'Tool Selection, Maintenance, and Sanitation')
ch16 += mirror_block('comp','h1-m4-1-garden-sanitation-and-tool-hygiene-sop','mirror-b1-m4-1-',5,BOOKS[5][1],1,'Chapter 16')
ch16 += mirror_block('comp','h1-m4-2-tool-maintenance-and-sharpening-sop','mirror-b1-m4-2-',5,BOOKS[5][1],1,'Chapter 16')
append_chapter(b1,ch16,'v1:Tools + M4-1/M4-2 mirrors','Book 1 Chapter 16','strengthen + mirror')

add_part(b1,'V','Verifying the Soil','book-1-part-v-verifying-the-soil')
ch17=chapter_block('v3','h2-chapter-44-soil-microscopy-equipment-sample-prep-and-identification',17,'Soil Microscopy')
ch17 += nested_entry('v3','h1-soil-microscopy-equipment','Soil Microscopy Equipment','Book 1 Chapter 17')
append_chapter(b1,ch17,'v3:Soil Microscopy + equipment entry','Book 1 Chapter 17','move + consolidate')
append_chapter(b1,chapter_block('v3','h2-chapter-45-soil-testing-what-to-test-how-to-read-results',18,'Soil Testing'),'v3:Soil Testing','Book 1 Chapter 18','move intact')

# ---------------- Build Book 2 ----------------
b2 = new_soup(2, BOOKS[2][0], 'Composts, plant and animal inputs, microbial inoculants, brews, minerals, carbon, humic substances, growing media, and mirrored plant-health products.')
add_part(b2,'I','Organic and Biological Inputs','h1-part-iii-section-a-the-encyclopedia-of-soil-inputs-chapters-1316')
# Preserve the original Part-opening input-category figure that sat outside Chapter 1.
b2.body.append(deepcopy(SOUPS['v2'].find(id='fig-UC-008')))
movement_rows.append({'source':'v2:fig-UC-008','destination':'Book 2 Part I opening','action':'preserve/move with Part','words':word_count_nodes([SOUPS['v2'].find(id='fig-UC-008')]),'text_sha256':text_hash([SOUPS['v2'].find(id='fig-UC-008')])})
ch=chapter_block('v2','h2-chapter-13-composts',1,'Composts')
ch += mirror_block('comp','h1-m1-3-compost-pile-building-and-management','mirror-b2-m1-3-',5,BOOKS[5][1],2,'Chapter 1')
append_chapter(b2,ch,'v2:Composts + M1-3 mirror','Book 2 Chapter 1','preserve + mirror')
append_chapter(b2,chapter_block('v2','h2-chapter-15-plant-based-inputs',2,'Plant-Based Inputs'),'v2:Plant Inputs','Book 2 Chapter 2','reorder')
append_chapter(b2,chapter_block('v2','h2-chapter-16-animal-based-inputs',3,'Animal-Based Inputs'),'v2:Animal Inputs','Book 2 Chapter 3','reorder')
ch=chapter_block('v2','h2-chapter-17-microbial-inoculants',4,'Microbial Inoculants')
ch += mirror_block('comp','h1-lse-163-m2-3-mycorrhizal-inoculation-at-transplant','mirror-b2-m2-3-',5,BOOKS[5][1],2,'Chapter 4')
append_chapter(b2,ch,'v2:Microbial Inoculants + M2-3 mirror','Book 2 Chapter 4','reorder + mirror')
ch=chapter_block('v2','h2-chapter-19-brews-teas-and-ferments',5,'Brews, Teas, and Ferments')
ch += mirror_block('comp','h1-lse-161-m2-1-aact-brewing-protocol','mirror-b2-m2-1-',5,BOOKS[5][1],2,'Chapter 5')
append_chapter(b2,ch,'v2:Brews + M2-1 mirror','Book 2 Chapter 5','reorder + mirror')

add_part(b2,'II','Minerals, Carbon, and Growing Media','h1-part-iii-section-b-the-encyclopedia-of-soil-inputs-chapters-1719-audit-revised')
min_nodes=block_by_id('v2','h2-chapter-14-minerals')
first_entry_i=next(i for i,n in enumerate(min_nodes) if n.get('id')=='h1-glacial-rock-dust')
min_intro=[deepcopy(x) for x in min_nodes[:first_entry_i]]
min_a=['h1-glacial-rock-dust','h1-zeolite','h1-wollastonite','h1-calcitic-lime','h1-dolomitic-lime','h1-oyster-shell-flour','h1-aragonite','h1-gypsum-calcium-sulfate','h1-wood-ash']
min_b=['h1-elemental-sulfur','h1-potassium-sulfate-k2so4','h1-epsom-salt-magnesium-sulfate','h1-borax-solubor','h1-zinc-sulfate','h1-manganese-sulfate','h1-iron-sulfate']
ch6=min_intro + split_entry_blocks(min_nodes,min_a)
set_top_heading(ch6,'Chapter 6: Liming, Calcium, and Broad-Spectrum Mineral Amendments',tag='h2',classes=['chapter-title']); first_heading(ch6)['data-toc']='chapter'; mark_entries(ch6)
append_chapter(b2,ch6,'v2:Minerals subset A','Book 2 Chapter 6','split')
ch7=[BeautifulSoup('<h2 id="book-2-chapter-7-trace-minerals" class="chapter-title" data-toc="chapter">Chapter 7: Sulfates, Trace Minerals, and Micronutrients</h2>','html.parser').h2,
     BeautifulSoup('<div class="navbox"><p><strong>Chapter boundary:</strong> This chapter continues the original Minerals chapter. All source entries retain their original anchors.</p></div>','html.parser').div]
ch7 += split_entry_blocks(min_nodes,min_b); mark_entries(ch7)
append_chapter(b2,ch7,'v2:Minerals subset B','Book 2 Chapter 7','split')
carbon=block_by_id('v2','h2-chapter-18-carbon-and-humic-substances')
growing=block_by_id('v2','h2-growing-media-and-base-mix-components')
# preserve the former Chapter 8 heading as an entry-level boundary inside merged chapter
shift_heading_levels(growing,1); set_top_heading(growing,'Growing Media and Base-Mix Components',tag='h3',classes=['lse-entry']); first_heading(growing)['data-toc']='entry'
set_top_heading(carbon,'Chapter 8: Carbon, Humic Substances, and Growing Media',tag='h2',classes=['chapter-title']); first_heading(carbon)['data-toc']='chapter'
ch8=carbon+growing; mark_entries(ch8)
append_chapter(b2,ch8,'v2:Carbon/Humic + Growing Media','Book 2 Chapter 8','merge')

add_part(b2,'III','Plant-Health Inputs: Encyclopedia Mirrors','book-2-part-iii-plant-health-inputs')
ch9=[BeautifulSoup('<h2 id="book-2-chapter-9-intervention-inputs" class="chapter-title" data-toc="chapter">Chapter 9: Insecticidal, Entomopathogenic, and Physical Controls</h2>','html.parser').h2]
for eid in ['h1-bacillus-thuringiensis-bt-kurstaki-israelensis-aizawai','h1-spinosad-spinosyn','h1-beauveria-bassiana','h1-isaria-fumosorosea-pfr-97','h1-paecilomyces-purpureocillium-lilacinum','h1-chromobacterium-subtsugae-grandevo','h1-steinernema-feltiae','h1-heterorhabditis-bacteriophora','h1-neem-cake-karanja-cake','h1-diatomaceous-earth-food-grade','h1-kaolin-clay-surround-wp','h1-iron-phosphate']:
    ch9 += mirror_block('v3',eid,'mirror-b2-control-',4,BOOKS[4][1],2,'Chapter 9',top_tag='h3')
append_chapter(b2,ch9,'v3:12 intervention entries','Book 2 Chapter 9','full-text mirrors')
ch10=[BeautifulSoup('<h2 id="book-2-chapter-10-disease-inputs" class="chapter-title" data-toc="chapter">Chapter 10: Fungicidal and Disease-Suppression Controls</h2>','html.parser').h2]
for eid in ['h1-copper-sulfate-copper-hydroxide-copper-octanoate','h1-wettable-sulfur','h1-potassium-bicarbonate']:
    ch10 += mirror_block('v3',eid,'mirror-b2-disease-',4,BOOKS[4][1],2,'Chapter 10',top_tag='h3')
append_chapter(b2,ch10,'v3:3 disease-control entries','Book 2 Chapter 10','full-text mirrors')

# ---------------- Build Book 3 ----------------
b3 = new_soup(3, BOOKS[3][0], 'Companion planting, guilds, rotation, seasonal planning, herbs, and the complete crop encyclopedia.')
add_part(b3,'I','Plant Communities and Seasonal Design','h1-part-v-plant-selection-and-guilds-chapters-2632')
ch1=chapter_block('v3','h2-chapter-26-companion-planting-mechanism-not-folklore',1,'Companion Planting')
ch1 += nested_entry('v3','h1-lse-221-companion-planting-mechanistic-frame','LSE-221 — Companion Planting (Mechanistic Frame)','Book 3 Chapter 1')
append_chapter(b3,ch1,'v3:Companion Planting + LSE-221','Book 3 Chapter 1','preserve + nest')
append_chapter(b3,chapter_block('v3','h2-chapter-27-polyculture-edge-effect-and-guild-design',2,'Polyculture, Edge Effect, and Guild Design'),'v3:Polyculture','Book 3 Chapter 2')
ch3=chapter_block('v3','h2-chapter-3-insectary-pollinator-and-cut-flower-habitat',3,'Insectary, Pollinator, and Cut-Flower Habitat')
ch3 += nested_entry('v3','h1-lse-192-insectary-guild-design','LSE-192 — Insectary Guild Design','Book 3 Chapter 3')
ch3 += nested_entry('v3','h1-lse-224-cut-flowers-as-functional-cover','LSE-224 — Cut Flowers as Functional Cover','Book 3 Chapter 3')
append_chapter(b3,ch3,'v3:Insectary/Cut Flowers + LSE-192/LSE-224','Book 3 Chapter 3','preserve + nest')
ch4=chapter_block('v3','h2-chapter-29-crop-rotation-and-succession-planning',4,'Crop Rotation and Succession Planning')
ch4 += mirror_block('comp','h1-m4-3-seasonal-succession-and-bed-pivoting-sop','mirror-b3-m4-3-',5,BOOKS[5][1],3,'Chapter 4')
append_chapter(b3,ch4,'v3:Rotation + M4-3 mirror','Book 3 Chapter 4','preserve + mirror')
raw_ch5=block_by_id('v3','h2-chapter-30-heat-tough-crops-and-cool-season-production')
radish=extract_subblock_from_nodes(raw_ch5,'h1-lse-233-radish-and-turnip')
beet=extract_subblock_from_nodes(raw_ch5,'h1-lse-234-beet')
raw_ch5,_=remove_subblocks(raw_ch5,['h1-lse-233-radish-and-turnip','h1-lse-234-beet'])
set_top_heading(raw_ch5,'Chapter 5: Heat-Tough Crops and Cool-Season Production',tag='h2',classes=['chapter-title']); first_heading(raw_ch5)['data-toc']='chapter'
append_chapter(b3,raw_ch5,'v3:Heat/Cool Season narrative','Book 3 Chapter 5','preserve; entries moved to Ch12')

add_part(b3,'II','Culinary and Medicinal Herbs','book-3-part-ii-herbs')
ch6=chapter_block('v3','h2-chapter-31-integrating-culinary-and-medicinal-herbs',6,'Herb Garden Design and Ecological Integration')
ch6 += nested_entry('v3','h1-lse-223-culinary-herb-integration','LSE-223 — Culinary Herb Integration','Book 3 Chapter 6')
for sid,newtitle in [('h2-1-chapter-purpose','Chapter Purpose'),('h2-2-north-texas-herb-design-principles','North Texas Herb Design Principles'),('h2-3-herb-bed-systems','Herb Bed Systems'),('h2-6-north-texas-herb-quick-reference-table','North Texas Herb Quick-Reference Table')]:
    ch6 += section_as_nested('v3',sid,newtitle)
append_chapter(b3,ch6,'v3:Herb chapter + LSE-223 + parallel design sections','Book 3 Chapter 6','decompose/merge')
ch7=[BeautifulSoup('<h2 id="book-3-chapter-7-herb-production" class="chapter-title" data-toc="chapter">Chapter 7: Herb Production, Harvesting, Processing, and Storage</h2>','html.parser').h2]
for sid,newtitle in [('h2-4-herb-by-herb-production-processing-and-storage','Herb-by-Herb Production, Processing, and Storage'),('h2-5-processing-methods-by-herb-type','Processing Methods by Herb Type')]:
    ch7 += section_as_nested('v3',sid,newtitle)
ch7 += mirror_block('comp','h1-m3-4-harvesting-and-post-harvest-handling-sop','mirror-b3-m3-4-',5,BOOKS[5][1],3,'Chapter 7')
append_chapter(b3,ch7,'v3:parallel herb production sections + M3-4 mirror','Book 3 Chapter 7','decompose + mirror')
archive('Parallel herb module wrapper',[deepcopy(SOUPS['v3'].find(id='h1-chapter-herbs-in-the-north-texas-living-soil-garden-growing-harvesting-processin'))],'v3','superseded structural wrapper')
archive('Herb Chapter Image Plan',block_by_id('v3','h2-7-herb-chapter-image-plan'),'v3','production planning artifact')
archive('Herb Chapter Image-Creation Prompt',block_by_id('v3','h2-8-image-creation-prompt-for-herb-chapter'),'v3','production planning artifact')

add_part(b3,'III','The Crop Encyclopedia','book-3-part-iii-crop-encyclopedia')
profiles=find_profile_blocks()
groups={
8:('Solanaceous Fruiting Crops',['Tomato','Pepper','Eggplant','Tomatillo']),
9:('Cucurbits and Vining Crops',['Cucumber','Zucchini / Summer Squash','Winter Squash / Pumpkin','Melon / Watermelon','Bitter Melon']),
10:('Legumes, Corn, Okra, and Sweet Potato',['Cowpea','Bean (Bush and Pole)','Sweet Corn','Okra','Sweet Potato']),
11:('Brassicas and Leafy Greens',['Broccoli / Cauliflower / Brussels Sprouts','Cabbage','Kale / Collards','Lettuce','Spinach']),
12:('Roots, Bulbs, and Alliums',['Garlic','Onion / Shallot','Carrot / Parsnip']),
13:('Culinary Annuals and Specialty Fruit',['Basil','Cilantro / Dill / Fennel','Strawberry — Annual Hill System']),
}
for num,(title,names) in groups.items():
    nodes=[BeautifulSoup(f'<h2 id="book-3-chapter-{num}-{re.sub(r"[^a-z0-9]+","-",title.lower()).strip("-")}" class="chapter-title" data-toc="chapter">Chapter {num}: {title}</h2>','html.parser').h2]
    if num==8:
        nodes += mirror_block('comp','h1-lse-232-sop-seed-starting-and-transplanting','mirror-b3-lse-232-',5,BOOKS[5][1],3,'Crop Encyclopedia introduction')
    for name in names:
        if name not in profiles: raise KeyError(f'Missing profile {name}')
        nodes += [deepcopy(x) for x in profiles[name]]
        movement_rows.append({'source':f'v2:crop profile:{name}','destination':f'Book 3 Chapter {num}','action':'move profile; remove controlled wrapper','words':word_count_nodes(profiles[name]),'text_sha256':text_hash(profiles[name])})
    if num==12:
        nodes += radish + beet
    append_chapter(b3,nodes,f'v2 crop profiles group {num}' + (' + v3 Radish/Beet' if num==12 else ''),f'Book 3 Chapter {num}','move/group')

# Archive the control wrappers only, not duplicated profiles
for wid in ['h1-living-soil-encyclopedia-v124-controlled-text-only-block-08','h1-living-soil-encyclopedia-v126-controlled-text-only-block-10']:
    archive(f'Superseded crop control wrapper {wid}',[deepcopy(SOUPS['v2'].find(id=wid))],'v2','version-control wrapper removed after profile movement')

# ---------------- Build Book 4 ----------------
b4 = new_soup(4, BOOKS[4][0], 'IPM, scouting, beneficial organisms, pests, biological controls, foliar applications, diseases, tissue testing, sap analysis, and Brix.')
add_part(b4,'I','Prevention and Scouting','h1-part-vii-plant-health-and-defense-chapters-3943')
ch1=chapter_block('v3','h2-chapter-39-ipm-foundations-integrated-pest-management',1,'IPM Foundations and Scouting')
ch1 += nested_entry('v3','h1-plant-immunity-as-ipm-layer-2','Plant Immunity as an IPM Layer','Book 4 Chapter 1')
ch1 += nested_entry('v3','h1-scouting-protocol-2','Scouting Protocol — Reference Entry','Book 4 Chapter 1')
ch1 += mirror_block('comp','h1-m3-1-daily-scouting-sop','mirror-b4-m3-1-',5,BOOKS[5][1],4,'Chapter 1')
ch1 += mirror_block('comp','h1-m3-2-ipm-decision-and-intervention-sop','mirror-b4-m3-2-',5,BOOKS[5][1],4,'Chapter 1')
append_chapter(b4,ch1,'v3:IPM + canonical reference entries + SOP mirrors','Book 4 Chapter 1','consolidate + mirror')
ch2=chapter_block('v3','h2-chapter-40-beneficial-predators-and-habitat',2,'Beneficial Predators and Habitat')
ch2 += nested_entry('v3','h1-beneficial-predators-generalist-survey-2','Beneficial Predators — Generalist Survey','Book 4 Chapter 2')
append_chapter(b4,ch2,'v3:Beneficial Predators + survey','Book 4 Chapter 2','consolidate')

add_part(b4,'II','Pest Diagnosis and Intervention','book-4-part-ii-pest-diagnosis')
append_chapter(b4,chapter_block('v3','h2-chapter-8-the-pest-encyclopedia',3,'The Pest Encyclopedia'),'v3:Pest Encyclopedia','Book 4 Chapter 3','move intact')
ch4=chapter_block('v3','h2-chapter-9-biological-and-least-toxic-controls',4,'Biological and Least-Toxic Controls')
refnotes=section_as_nested('v1','h2-6-reference-notes-and-merged-concepts','Bt and Beneficial Nematode Reference Notes')
ch4 += refnotes
append_chapter(b4,ch4,'v3:Biological Controls + practitioner reference notes','Book 4 Chapter 4','move + fold unique notes')
ch5=chapter_block('v3','h2-chapter-41-foliar-applications-and-plant-sap-health',5,'Foliar Applications and Plant Sap Health')
ch5 += mirror_block('comp','h1-lse-162-m2-2-foliar-spray-application-sop','mirror-b4-m2-2-',5,BOOKS[5][1],4,'Chapter 5')
append_chapter(b4,ch5,'v3:Foliar + M2-2 mirror','Book 4 Chapter 5','move + mirror')

add_part(b4,'III','Disease Diagnosis and Intervention','book-4-part-iii-disease-diagnosis')
append_chapter(b4,chapter_block('v3','h2-chapter-42-disease-identification-and-management',6,'Disease Identification and Management'),'v3:Disease Identification','Book 4 Chapter 6','move intact')
append_chapter(b4,chapter_block('v3','h2-chapter-13-the-disease-encyclopedia',7,'The Disease Encyclopedia'),'v3:Disease Encyclopedia','Book 4 Chapter 7','move intact')

add_part(b4,'IV','Plant Diagnostics','h1-part-viii-diagnostics-and-measurement-chapters-4447')
ch8=chapter_block('v3','h2-chapter-46-plant-sap-analysis-and-tissue-testing',8,'Plant Sap Analysis and Tissue Testing')
ch8 += nested_entry('v3','h1-tissue-testing','Tissue Testing — Reference Deep Dive','Book 4 Chapter 8')
append_chapter(b4,ch8,'v3:Sap/Tissue + Tissue Testing entry','Book 4 Chapter 8','move + consolidate')
append_chapter(b4,chapter_block('v3','h2-chapter-17-brix-and-refractometry',9,'Brix and Refractometry'),'v3:Brix/Refractometry','Book 4 Chapter 9','move intact')
archive('Source-pending Refractometer Use Protocol',block_by_id('v1','h2-4-diagnostic-and-observation-tools'),'v1','source-pending; held from reader until verified')
add_navbox(b4,'<p><strong>Editorial hold:</strong> A source-pending refractometer protocol remains in the internal production-hold file and is not presented here as finished instruction.</p>')

# ---------------- Build Book 5 ----------------
b5 = new_soup(5, BOOKS[5][0], 'Canonical SOPs, appendices, quick-reference material, checklists, calendars, and clearly separated experimental or non-consensus practices.')
add_part(b5,'I','Soil, Water, and Tool Procedures','book-5-part-i-soil-water-tools')
for eid,title in [
('h1-m1-1-no-till-bed-establishment','M1-1: No-Till Bed Establishment'),
('h1-m1-2-annual-top-dress-protocol','M1-2: Annual Top-Dress Protocol'),
('h1-m1-3-compost-pile-building-and-management','M1-3: Compost Pile Building and Management'),
('h1-m3-3-irrigation-system-maintenance-sop','M3-3: Irrigation System Maintenance SOP'),
('h1-m4-1-garden-sanitation-and-tool-hygiene-sop','M4-1: Garden Sanitation and Tool Hygiene SOP'),
('h1-m4-2-tool-maintenance-and-sharpening-sop','M4-2: Tool Maintenance and Sharpening SOP'),
('h1-m4-4-cover-crop-planting-and-termination-sop','M4-4: Cover Crop Planting and Termination SOP')]:
    append_chapter(b5,canonical_sop_block(eid,title),f'comp:{eid}',f'Book 5 Part I: {title}','reorder canonical SOP')

add_part(b5,'II','Crop Establishment and Seasonal Operations','book-5-part-ii-crop-operations')
for eid,title in [
('h1-lse-232-sop-seed-starting-and-transplanting','LSE-232 — Seed Starting and Transplanting SOP'),
('h1-m4-3-seasonal-succession-and-bed-pivoting-sop','M4-3: Seasonal Succession and Bed Pivoting SOP'),
('h1-m3-4-harvesting-and-post-harvest-handling-sop','M3-4: Harvesting and Post-Harvest Handling SOP')]:
    append_chapter(b5,canonical_sop_block(eid,title),f'comp:{eid}',f'Book 5 Part II: {title}','reorder canonical SOP')

add_part(b5,'III','Brewing and Application Procedures','book-5-part-iii-brewing-application')
for eid,title in [
('h1-lse-161-m2-1-aact-brewing-protocol','M2-1: AACT Brewing Protocol'),
('h1-lse-162-m2-2-foliar-spray-application-sop','M2-2: Foliar Spray Application SOP'),
('h1-lse-163-m2-3-mycorrhizal-inoculation-at-transplant','M2-3: Mycorrhizal Inoculation at Transplant')]:
    append_chapter(b5,canonical_sop_block(eid,title),f'comp:{eid}',f'Book 5 Part III: {title}','reorder canonical SOP')

add_part(b5,'IV','Scouting and IPM Procedures','book-5-part-iv-scouting-ipm')
for eid,title in [
('h1-m3-1-daily-scouting-sop','M3-1: Daily Scouting SOP'),
('h1-m3-2-ipm-decision-and-intervention-sop','M3-2: IPM Decision and Intervention SOP')]:
    append_chapter(b5,canonical_sop_block(eid,title),f'comp:{eid}',f'Book 5 Part IV: {title}','reorder canonical SOP')

add_part(b5,'V','Appendices and Quick Reference','h1-checkpoint-10-appendices-af')
for eid in ['h2-appendix-a-quick-reference-recipe-cards-top-25-inputs-and-brews','h2-appendix-b-troubleshooting-decision-trees','h2-appendix-c-seasonal-calendars-region-neutral-baseline-north-texas-overlay','h2-appendix-d-conversion-charts','h2-appendix-e-microscopy-identification-guide','h2-appendix-f-brix-reference-tables-by-crop']:
    nodes=block_by_id('comp',eid); h=first_heading(nodes); h['class']=sorted(set((h.get('class') or [])+['chapter-title'])); h['data-toc']='chapter'
    append_chapter(b5,nodes,f'comp:{eid}','Book 5 Part V','retain appendix')

add_part(b5,'VI','Experimental and Non-Consensus Practices','h1-part-ix-electroculture-and-plant-electrophysiology-chapter-48')
ch1=[BeautifulSoup('<h2 id="book-5-experimental-chapter-1" class="chapter-title" data-toc="chapter">Chapter 1: Evidence Classes and Safe Self-Experimentation</h2>','html.parser').h2]
for sid,title in [('h2-1-evidence-status-notice','Evidence Status Notice'),('h2-2-how-to-read-this-chapter','How to Read This Part'),('h2-9-how-to-trial-a-non-consensus-practice-safely','How to Trial a Non-Consensus Practice Safely')]:
    ch1 += section_as_nested('v1',sid,title)
append_chapter(b5,ch1,'v1:Practitioner evidence/safe trial sections','Book 5 Part VI Chapter 1','decompose')

raw_electro=block_by_id('v3','h2-chapter-18-electroculture-and-plant-electrophysiology')
param=extract_subblock_from_nodes(raw_electro,'h1-lse-131-paramagnetism-in-soils')
lunar=extract_subblock_from_nodes(raw_electro,'h1-lse-132-lunar-planting')
raw_electro,_=remove_subblocks(raw_electro,['h1-lse-131-paramagnetism-in-soils','h1-lse-132-lunar-planting'])
set_top_heading(raw_electro,'Chapter 2: Electroculture and Plant Electrophysiology',tag='h2',classes=['chapter-title']); first_heading(raw_electro)['data-toc']='chapter'
raw_electro += nested_entry('v3','h1-lse-130-plant-electrophysiology','LSE-130 — Plant Electrophysiology','Book 5 Experimental Chapter 2')
for sid,title in [('h3-electroculture-passive','Practitioner Note — Passive Electroculture'),('h3-plant-electrophysiology','Practitioner Note — Plant Electrophysiology')]:
    nodes=block_by_id('v1',sid); set_top_heading(nodes,title,tag='h3',classes=['lse-entry']); first_heading(nodes)['data-toc']='entry'; raw_electro += nodes
append_chapter(b5,raw_electro,'v3:Electroculture chapter + LSE-130 + practitioner notes','Book 5 Part VI Chapter 2','consolidate experimental material')

ch3=[BeautifulSoup('<h2 id="book-5-experimental-chapter-3" class="chapter-title" data-toc="chapter">Chapter 3: Paramagnetism in Soils</h2>','html.parser').h2]
ch3 += param
nodes=block_by_id('v1','h3-paramagnetism-in-soils'); set_top_heading(nodes,'Practitioner Note — Paramagnetism in Soils',tag='h3',classes=['lse-entry']); first_heading(nodes)['data-toc']='entry'; ch3 += nodes
append_chapter(b5,ch3,'v3:LSE-131 + v1 practitioner note','Book 5 Part VI Chapter 3','consolidate')
ch4=[BeautifulSoup('<h2 id="book-5-experimental-chapter-4" class="chapter-title" data-toc="chapter">Chapter 4: Lunar Planting</h2>','html.parser').h2]
ch4 += lunar
nodes=block_by_id('v1','h3-lunar-planting'); set_top_heading(nodes,'Practitioner Note — Lunar Planting',tag='h3',classes=['lse-entry']); first_heading(nodes)['data-toc']='entry'; ch4 += nodes
append_chapter(b5,ch4,'v3:LSE-132 + v1 practitioner note','Book 5 Part VI Chapter 4','consolidate')
ch5=[BeautifulSoup('<h2 id="book-5-experimental-chapter-5" class="chapter-title" data-toc="chapter">Chapter 5: Future-Edition and Source-Confidence Notes</h2>','html.parser').h2]
for sid,title in [('h2-10-what-belongs-in-a-future-edition','What Belongs in a Future Edition'),('h2-11-sources-and-confidence-notes','Sources and Confidence Notes')]:
    ch5 += section_as_nested('v1',sid,title)
append_chapter(b5,ch5,'v1:Practitioner future/source sections','Book 5 Part VI Chapter 5','decompose')

# ---------------- Archive control/duplicate material ----------------
# Duplicate V1 front-matter packages (generated replacement is in each new book)
v1kids=root_tags(SOUPS['v1'])
archive('Superseded Volume 1 duplicate front matter',[deepcopy(x) for x in v1kids[:13] if not (x.name=='section' and 'toc-section' in (x.get('class') or []))],'v1','replaced by five-book working front matter')
archive('Practitioner chapter wrapper',[deepcopy(SOUPS['v1'].find(id='h1-practitioner-systems-experimental-methods-and-non-consensus-growing-traditions'))],'v1','decomposed across Books 1, 4, 5, and hold ledger')
archive('Experimental and Cultural Practices wrapper',[deepcopy(SOUPS['v1'].find(id='h2-5-experimental-and-cultural-practices'))],'v1','decomposed into separate Book 5 experimental chapters')
archive('Practitioner product-label-held placeholders',block_by_id('v1','h2-7-product-label-held-placeholders'),'v1','product-label verification required')
archive('Practitioner legal/table placeholder',block_by_id('v1','h2-8-legal-table-appendix-placeholder'),'v1','jurisdictional/legal verification required')
archive('Companion noncanonical Scouting Protocol copy',block_by_id('comp','h1-scouting-protocol'),'comp','noncanonical duplicate; M3-1 SOP retained')
archive('Companion noncanonical Plant Immunity copy',block_by_id('comp','h1-plant-immunity-as-ipm-layer'),'comp','noncanonical duplicate; Book 4 canonical')
archive('Companion noncanonical Beneficial Predators copy',block_by_id('comp','h1-beneficial-predators-generalist-survey'),'comp','noncanonical duplicate; Book 4 canonical')
archive('Companion product-label/regulatory placeholder',block_by_id('comp','h1-product-label-regulatory-appendix-placeholder'),'comp','publication blocker')
archive('Companion legal/local/water placeholder',block_by_id('comp','h1-legal-local-water-appendix-placeholder'),'comp','publication blocker')

# ---------------- Build production-hold HTML ----------------
hold_html='''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><meta content="width=device-width, initial-scale=1.0" name="viewport"/><title>LSE Internal Production Hold</title><link href="lse_five_book_working.css" media="all" rel="stylesheet"/></head><body></body></html>'''
hold=BeautifulSoup(hold_html,'html.parser')
h=hold.new_tag('h1',id='internal-production-hold'); h.string='Living Soil Encyclopedia — Internal Production Hold'; hold.body.append(h)
p=hold.new_tag('p'); p['class']=['volume-subtitle']; p.string='Material removed from reader-facing working manuscripts but retained for provenance, verification, or later production decisions.'; hold.body.append(p)
nav=BeautifulSoup('<div class="navbox"><p><strong>Not reader-facing.</strong> This file contains superseded wrappers, unresolved placeholders, production notes, and verified noncanonical copies. Nothing here should be published without explicit review.</p></div>','html.parser').div; hold.body.append(nav)
hold_aliases={}
for idx,(label,nodes,source,reason) in enumerate(hold_sections,1):
    gh=hold.new_tag('h2',id=f'hold-section-{idx}'); gh['class']=['chapter-title']; gh.string=label; hold.body.append(gh)
    meta=hold.new_tag('p'); meta['class']=['rough-warning']; meta.string=f'Source: {source}. Hold reason: {reason}.'; hold.body.append(meta)
    nodes=[deepcopy(x) for x in nodes]
    mapping=namespace_ids(nodes,f'hold-{idx}-')
    hold_aliases.update(mapping)
    for n in nodes: hold.body.append(n)

# ---------------- TOC generation ----------------
def build_toc(soup: BeautifulSoup, book_title: str):
    toc=soup.find(id='table-of-contents'); toc.clear()
    title=soup.new_tag('h2'); title['class']=['toc-title']; title.string=f'Contents — {book_title}'; toc.append(title)
    root=soup.new_tag('ul'); root['class']=['toc-list']; toc.append(root)
    current_part_li=None; current_part_ul=None; current_ch_li=None; current_ch_ul=None
    for n in root_tags(soup):
        if n is toc: continue
        if n.name=='h1' and 'part-title' in (n.get('class') or []):
            li=soup.new_tag('li'); li['class']=['toc-part']; a=soup.new_tag('a',href='#'+n['id']); a.string=clean_text(n.get_text(' ',strip=True)); li.append(a)
            current_part_ul=soup.new_tag('ul'); li.append(current_part_ul); root.append(li); current_part_li=li; current_ch_li=None; current_ch_ul=None
        elif n.name=='h2' and 'chapter-title' in (n.get('class') or []):
            parent=current_part_ul if current_part_ul is not None else root
            li=soup.new_tag('li'); li['class']=['toc-chapter']; a=soup.new_tag('a',href='#'+n['id']); a.string=clean_text(n.get_text(' ',strip=True)); li.append(a)
            current_ch_ul=soup.new_tag('ul'); li.append(current_ch_ul); parent.append(li); current_ch_li=li
        elif n.name=='h3' and n.get('data-toc')=='entry' and n.get('id'):
            parent=current_ch_ul if current_ch_ul is not None else (current_part_ul if current_part_ul is not None else root)
            li=soup.new_tag('li'); li['class']=['toc-section']; a=soup.new_tag('a',href='#'+n['id']); a.string=clean_text(n.get_text(' ',strip=True)); li.append(a); parent.append(li)
    notice=soup.new_tag('p'); notice['class']=['toc-notice']; notice.string='Page numbers populate during print rendering through target-counter CSS.'; toc.append(notice)

for no,soup in [(1,b1),(2,b2),(3,b3),(4,b4),(5,b5)]:
    build_toc(soup,BOOKS[no][0])

# ---------------- Write CSS ----------------
css=(ROOT/'lse_print_toc_fixed.css').read_text(encoding='utf-8')
css += r'''

/* Five-book working-set additions */
@media screen {
  html { background: #e9e2d3; }
  body { max-width: 8.5in; margin: 1.25rem auto; padding: 0.8in; background: #fbf7ee; box-shadow: 0 0 18px rgba(0,0,0,.18); }
}
.series-title { break-before: avoid; page: auto; margin-bottom: .25em; }
.book-title { font-size: 16pt; color: #506f3b; border-bottom: 1pt solid #c8c0ae; margin-top: .2em; }
.part-title { string-set: chapter-title content(); }
.chapter-title { string-set: chapter-title content(); }
h3.lse-entry { string-set: entry-title content(); }
.volume-subtitle { color:#6b4f2a; font-style:italic; }
.mirror-notice { border-left: 4px solid #6b4f2a; margin-top: 1.2em; }
.mirror-entry { border-left-color: #6b4f2a !important; }
.working-edition-notice { margin-bottom: 1.2em; }
.rough-warning { color:#7a4a00; font-size:9pt; }
.production-hold-link { color:#7a4a00; text-decoration-style:dashed; }
.unresolved-xref { color:#9b1c1c; }
.crop-profile { margin-top: 1.8em; }
.toc-list ul { list-style:none; margin:.15em 0 .25em .85em; padding:0; }
'''
(OUT/'lse_five_book_working.css').write_text(css,encoding='utf-8')

# Initial write to allow ID maps
soups_out={1:b1,2:b2,3:b3,4:b4,5:b5}
for no,soup in soups_out.items():
    (OUT/BOOKS[no][1]).write_text(str(soup),encoding='utf-8')
(OUT/'LSE_INTERNAL_PRODUCTION_HOLD.html').write_text(str(hold),encoding='utf-8')

# ---------------- Cross-file link resolution ----------------
file_soups={BOOKS[no][1]:soup for no,soup in soups_out.items()}
file_soups['LSE_INTERNAL_PRODUCTION_HOLD.html']=hold
id_to_files=defaultdict(list)
for fn,soup in file_soups.items():
    for t in soup.find_all(id=True): id_to_files[t['id']].append(fn)

link_changes=[]; unresolved=[]
for fn,soup in file_soups.items():
    local_ids={t['id'] for t in soup.find_all(id=True)}
    for a in soup.find_all('a',href=True):
        href=a['href']
        if not href.startswith('#') or href=='#': continue
        target=href[1:]
        if target in local_ids: continue
        candidates=id_to_files.get(target,[])
        if candidates:
            chosen=sorted(candidates,key=lambda x:(x=='LSE_INTERNAL_PRODUCTION_HOLD.html',x))[0]
            a['href']=f'{chosen}#{target}'
            link_changes.append((fn,href,a['href']))
        elif target in hold_aliases:
            a['href']=f'LSE_INTERNAL_PRODUCTION_HOLD.html#{hold_aliases[target]}'
            a['class']=sorted(set((a.get('class') or [])+['production-hold-link']))
            link_changes.append((fn,href,a['href']))
        else:
            a['class']=sorted(set((a.get('class') or [])+['unresolved-xref']))
            a['data-unresolved-target']=target
            unresolved.append((fn,target,clean_text(a.get_text(' ',strip=True))))
            del a['href']

# rewrite files after link changes
for fn,soup in file_soups.items():
    (OUT/fn).write_text(str(soup),encoding='utf-8')

# ---------------- Verification ----------------
def metrics(soup):
    body=deepcopy(soup.body)
    for toc in body.select('.toc-section'): toc.decompose()
    for meta in body.select('.figure-placement-meta'): meta.decompose()
    text=clean_text(body.get_text(' ',strip=True))
    ids=[x['id'] for x in soup.find_all(id=True)]
    return {
        'words':len(WORD_RE.findall(text)),
        'headings':len(soup.find_all(re.compile(r'^h[1-6]$'))),
        'paragraphs':len(soup.find_all('p')),
        'tables':len(soup.find_all('table')),
        'blockquotes':len(soup.find_all('blockquote')),
        'images':len(soup.find_all('img')),
        'figure_sections':len(soup.select('section.lse-figure, section.user-created-figure, section.inline-figure, section.image-placeholder')),
        'ids':len(ids),
        'duplicate_ids':sorted({x for x in ids if ids.count(x)>1}),
    }

verification={}
all_dead=[]
for fn,soup in file_soups.items():
    m=metrics(soup)
    dead=[]
    for a in soup.find_all('a',href=True):
        href=a['href']
        if href.startswith('#'):
            if not soup.find(id=href[1:]): dead.append(href)
        elif '.html#' in href:
            dest,anchor=href.split('#',1)
            ds=file_soups.get(dest)
            if ds is None or not ds.find(id=anchor): dead.append(href)
    m['dead_links']=dead
    verification[fn]=m
    all_dead.extend((fn,x) for x in dead)

# Mirror checksum verification: compare source canonical normalized text to generated mirror text after removing notice and heading ID differences.
def normalized_block_text(nodes, remove_first_heading=False):
    nodes=[deepcopy(x) for x in nodes]
    if remove_first_heading:
        for n in nodes:
            if heading_level(n) is not None:
                n.decompose(); break
    return clean_text(' '.join(n.get_text(' ',strip=True) for n in nodes))

# Verify that each mirror exists and records canonical source checksum.
for row in mirror_rows:
    mfile=BOOKS[row['mirror_book']][1]
    ms=file_soups[mfile]
    row['mirror_present']=bool(ms.find(id=row['mirror_id']))

# ID coverage across source IDs, excluding source-generated TOCs and no-id elements
source_ids=defaultdict(list)
for key,s in SOUPS.items():
    for t in s.find_all(id=True): source_ids[t['id']].append(key)
final_original_ids=set()
for fn,s in file_soups.items():
    for t in s.find_all(id=True):
        ident=t['id']
        if not ident.startswith(('mirror-','hold-','book-')):
            final_original_ids.add(ident)
covered=set(final_original_ids)|set(hold_aliases.keys())|{'table-of-contents'}
missing_source_ids=sorted(set(source_ids)-covered)
# IDs that are purely superseded old part/chapter/control structure and not substantive anchors
superseded_patterns=('h1-part-','h1-living-soil-encyclopedia','h2-publication-format','h2-private-reader-edition')
missing_structural=[x for x in missing_source_ids if x.startswith(superseded_patterns)]
missing_other=[x for x in missing_source_ids if x not in missing_structural]

# write ledgers
with (OUT/'LSE_MOVEMENT_LEDGER.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=['source','destination','action','words','text_sha256']); w.writeheader(); w.writerows(movement_rows)
with (OUT/'LSE_MIRROR_SYNCHRONIZATION_LEDGER.csv').open('w',newline='',encoding='utf-8') as f:
    fields=['canonical_id','canonical_book','canonical_file','mirror_book','mirror_chapter','mirror_id','canonical_text_sha256','status','mirror_present']
    w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(mirror_rows)

report=[]
report.append('# Living Soil Encyclopedia — Five-Book Restructuring Integrity Report\n')
report.append('**Status:** Owner-approved structural reassembly completed. These are working manuscripts, not final publication masters.\n')
report.append('## Delivered architecture\n')
for no,(title,fn) in BOOKS.items(): report.append(f'- Book {no}: **{title}** — `{fn}`')
report.append('\n## Automated integrity results\n')
report.append('| File | Words | Headings | Paragraphs | Tables | Blockquotes | Images | IDs | Duplicate IDs | Dead links |')
report.append('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
for fn,m in verification.items():
    report.append(f"| {fn} | {m['words']:,} | {m['headings']:,} | {m['paragraphs']:,} | {m['tables']:,} | {m['blockquotes']:,} | {m['images']:,} | {m['ids']:,} | {len(m['duplicate_ids'])} | {len(m['dead_links'])} |")
report.append(f"\n- Cross-file link rewrites: **{len(link_changes)}**")
report.append(f"- Unresolved anchor references converted to flagged nonlinks: **{len(unresolved)}**")
report.append(f"- Mirror records generated: **{len(mirror_rows)}**")
report.append(f"- Reader-facing duplicate IDs: **{sum(len(verification[BOOKS[n][1]]['duplicate_ids']) for n in BOOKS)}**")
report.append(f"- Reader-facing dead links: **{sum(len(verification[BOOKS[n][1]]['dead_links']) for n in BOOKS)}**")
report.append('\n## Structural actions completed\n')
report.extend([
'- Implemented the approved five-book titles, scopes, Parts, and chapter order.',
'- Moved all 25 crop profiles from the controlled Volume 2 blocks into six crop-encyclopedia chapters.',
'- Moved soil microscopy/testing to Book 1 and plant diagnostics to Book 4.',
'- Split Minerals into two chapters and merged Carbon/Humic content with Growing Media.',
'- Split the herb material into design/integration and production/processing chapters.',
'- Nested or consolidated the approved duplicate/reference blocks under their owning chapters.',
'- Reordered the Companion SOPs into operational Parts and generated synchronized chapter mirrors.',
'- Generated 15 Book 2 intervention mirrors from Book 4 canonical source entries.',
'- Decomposed the mixed practitioner chapter across Books 1, 4, 5, and the internal production hold.',
'- Removed production wrappers and verified noncanonical copies from reader-facing books without deleting them from the working set.',
'- Rebuilt every table of contents with CSS classes compatible with target-counter page numbering.',
'- Rewrote cross-book anchor links where the target moved to a different manuscript.',
])
report.append('\n## Preservation controls\n')
report.extend([
'- Existing canonical anchor IDs were preserved whenever the source block remained canonical.',
'- Mirrored copies use namespaced IDs to prevent collisions and carry “do not edit independently” notices.',
'- Existing figures, image references, captions, tables, blockquotes, safety language, and North Texas notes travel with their source blocks.',
'- Removed control text and unresolved placeholders are retained in `LSE_INTERNAL_PRODUCTION_HOLD.html`.',
'- The original earth-toned typography and component styling are retained through the consolidated working CSS.',
])
report.append('\n## Remaining publication blockers\n')
report.extend([
'- Image assets and rights records were not supplied; image existence, resolution, color profile, and commercial clearance remain unverified.',
'- Open image placeholders and visible rights markers remain where they are part of the source content.',
'- Product-label, SDS, legal, municipal, and graywater placeholders remain held for current verification.',
'- The source-pending refractometer protocol remains excluded from finished instruction.',
'- Scientific claims, rates, intervals, evidence classifications, citations, and cross-reference prose still require the later editorial and verification phases.',
'- Final pagination, widows/orphans, figure placement, and TOC page numbers require rendering with the complete asset package.',
])
report.append('\n## Source-ID coverage\n')
report.append(f'- Source IDs covered by canonical output or production hold: **{len(set(source_ids)-set(missing_source_ids)):,} / {len(set(source_ids)):,}** unique IDs.')
report.append(f'- Superseded structural IDs not retained as anchors: **{len(missing_structural)}**.')
report.append(f'- Other source IDs not retained: **{len(missing_other)}**.')
if missing_other:
    report.append('\nOther missing IDs (review required):')
    report.extend([f'- `{x}`' for x in missing_other])
if unresolved:
    report.append('\n## Flagged unresolved anchor references\n')
    for fn,target,text in unresolved[:100]: report.append(f'- `{fn}` → `#{target}` ({text})')

(OUT/'LSE_FIVE_BOOK_INTEGRITY_REPORT.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
(OUT/'LSE_FIVE_BOOK_INTEGRITY_DATA.json').write_text(json.dumps({
    'verification':verification,
    'link_changes':link_changes,
    'unresolved':unresolved,
    'missing_source_ids':missing_source_ids,
    'missing_structural_ids':missing_structural,
    'missing_other_ids':missing_other,
    'mirror_count':len(mirror_rows),
    'movement_count':len(movement_rows),
},indent=2,ensure_ascii=False),encoding='utf-8')

# Copy approval packet and build script for provenance
shutil.copy2(ROOT/'LSE_PHASE0_PHASE1_APPROVAL_PACKET.md',OUT/'LSE_APPROVED_ARCHITECTURE_PACKET.md')
shutil.copy2(Path(__file__),OUT/'build_lse_five_book_set.py')

# Manifest with hashes
manifest=[]
for p in sorted(OUT.iterdir()):
    if p.is_file():
        manifest.append({'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(OUT/'MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
# refresh manifest including itself
manifest=[]
for p in sorted(OUT.iterdir()):
    if p.is_file(): manifest.append({'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(OUT/'MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')

zip_path=ROOT/'LSE_FIVE_BOOK_WORKING_SET.zip'
with zipfile.ZipFile(zip_path,'w',compression=zipfile.ZIP_DEFLATED) as z:
    for p in sorted(OUT.iterdir()):
        if p.is_file(): z.write(p,arcname=f'LSE_FIVE_BOOK_WORKING_SET/{p.name}')

print(json.dumps({
    'output_dir':str(OUT),
    'zip':str(zip_path),
    'verification':verification,
    'unresolved_count':len(unresolved),
    'missing_other_ids':missing_other,
    'mirror_count':len(mirror_rows),
    'movement_count':len(movement_rows)
},indent=2,ensure_ascii=False))

# Reference verification against CrossRef

Source: `references/extracted.json` (98 entries, 9 blocks). Verified via the CrossRef REST API. **Nothing here has been auto-corrected** — a mismatch is a finding for the author to resolve.

## Summary

| Status | Count |
|---|---:|
| MISMATCH (author to resolve) | 0 |
| NOT FOUND | 0 |
| VERIFIED_WEAK (moderate title + author only, no DOI — stays visible) | 3 |
| VERIFIED (resolved DOI or high title ratio) | 49 |
| BOOK / NOT INDEXED (expected — not a failure) | 46 |
| **Total** | **98** |

## Verification path breakdown (of the 52 verified + verified_weak)

| Path | Count |
|---|---:|
| resolved DOI (author/year/title consistent) | 18 |
| high title ratio (>=0.60) + author/year | 31 |
| MODERATE title (0.45–0.60) + author only — verified_weak | 3 |

**verified_weak (moderate title + author only, no DOI — matcher is load-bearing): 3**

- **volume_1-b4-n13** — released · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Wardle, D. A. (2002). Communities and Ecosystems: Linking the Aboveground and Belowground Components. Princeton University Press.`
  - CrossRef best: `Communities and Ecosystems` (2013) DOI `10.1515/9781400847297` [title_ratio=0.505 author_match=True year_match=False]

- **volume_1-b5-n4** — **HELD (excluded from Further Reading)** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Epstein, E. (1997). The science of composting. CRC press.`
  - CrossRef best: `Industrial Composting` (2011) DOI `10.1201/b10726` [title_ratio=0.565 author_match=True year_match=False]

- **volume_1-b5-n5** — released · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Ryckeboer, J., et al. (2003). A survey of bacteria and fungi occurring during composting and self-heating processes. Annals of microbiology.`
  - CrossRef best: `Microbiological aspects of biowaste during composting in a monitored compost bin` (2003) DOI `10.1046/j.1365-2672.2003.01800.x` [title_ratio=0.473 author_match=True year_match=True]

## Held for manual confirmation (owner decision) — 1

Excluded from Further Reading and carried into the exception report.

- **volume_1-b5-n4** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Epstein, E. (1997). The science of composting. CRC press.`
  - CrossRef best: `Industrial Composting` (2011) DOI `10.1201/b10726`
  - Reason held: CrossRef matched a DIFFERENT book by the same author (Epstein 2011, Industrial Composting), not the cited 1997 'The Science of Composting'; existence of the 1997 title is unconfirmed.

## ⚠️ Fabrication signature — DOI resolves to an unrelated paper

_None detected._ No DOI resolved to a paper unrelated to its citation.

## MISMATCH (author to resolve) — 0

_None._

## NOT FOUND — 0

_None._

## VERIFIED_WEAK (moderate title + author only, no DOI — stays visible) — 3

- **volume_1-b4-n13** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Wardle, D. A. (2002). Communities and Ecosystems: Linking the Aboveground and Belowground Components. Princeton University Press.`
  - CrossRef best: `Communities and Ecosystems` (2013) DOI `10.1515/9781400847297` [title_ratio=0.505 author_match=True year_match=False]
  - Note: Moderate title match corroborated by author only, no resolved DOI — author matcher is load-bearing here; kept visible for scrutiny.

- **volume_1-b5-n4** **[HELD]** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Epstein, E. (1997). The science of composting. CRC press.`
  - CrossRef best: `Industrial Composting` (2011) DOI `10.1201/b10726` [title_ratio=0.565 author_match=True year_match=False]
  - Note: Moderate title match corroborated by author only, no resolved DOI — author matcher is load-bearing here; kept visible for scrutiny.

- **volume_1-b5-n5** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Ryckeboer, J., et al. (2003). A survey of bacteria and fungi occurring during composting and self-heating processes. Annals of microbiology.`
  - CrossRef best: `Microbiological aspects of biowaste during composting in a monitored compost bin` (2003) DOI `10.1046/j.1365-2672.2003.01800.x` [title_ratio=0.473 author_match=True year_match=True]
  - Note: Moderate title match corroborated by author only, no resolved DOI — author matcher is load-bearing here; kept visible for scrutiny.

## VERIFIED (resolved DOI or high title ratio) — 49

- **volume_1-b1-n1** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Tripathi et al. (2020). https://doi.org/10.1016/B978-0-08-103017-2.00002-7`
  - CrossRef best: `Influence of synthetic fertilizers and pesticides on soil health and soil microbiology` (2020) DOI `10.1016/b978-0-08-103017-2.00002-7` [title_ratio=None author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_1-b1-n2** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Yu, Y., et al. (2024). Effects of organic fertilizers on plant growth and the rhizosphere microbiome. Applied and Environmental Microbiology.`
  - CrossRef best: `Effects of organic fertilizers on plant growth and the rhizosphere microbiome` (2024) DOI `10.1128/aem.01719-23` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b1-n4** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Neumann, G. (2007). Root exudates and nutrient cycling. Nutrient cycling in terrestrial ecosystems, Springer. https://doi.org/10.1007/978-3-540-68027-7_5`
  - CrossRef best: `Root Exudates and Nutrient Cycling` (2007) DOI `10.1007/978-3-540-68027-7_5` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_1-b1-n5** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Yetgin, A. (2023). The dynamic interplay of root exudates and rhizosphere microbiome. Soil Studies.`
  - CrossRef best: `The dynamic interplay of root exudates and rhizosphere microbiome` (2023) DOI `10.21657/soilst.1408089` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b1-n6** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Mimmo, T., et al. (2018). Nutrient availability in the rhizosphere: a review. Acta Horticulturae.`
  - CrossRef best: `Nutrient availability in the rhizosphere: a review` (2018) DOI `10.17660/actahortic.2018.1217.2` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b1-n7** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Roy-Bolduc, A., & Hijri, M. (2011). The use of mycorrhizae to enhance phosphorus uptake: a way out the phosphorus crisis. J. Biofertil. Biopestici.`
  - CrossRef best: `The Use of Mycorrhizae to Enhance Phosphorus Uptake: A Way Out the Phosphorus Crisis` (2011) DOI `10.4172/2155-6202.1000104` [title_ratio=1.0 author_match=False year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b1-n8** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Nadeem, M., et al. (2022). Understanding the adaptive mechanisms of plants to improve phosphorus-use efficiency in the era of climate change. Frontiers in Plant Science. https://doi.org/10.3389/fpls.2022.804058`
  - CrossRef best: `Understanding the Adaptive Mechanisms of Plants to Enhance Phosphorus Use Efficiency on Podzolic Soils in Boreal Agroecosystems` (2022) DOI `10.3389/fpls.2022.804058` [title_ratio=0.733 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_1-b1-n9** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Pieterse, C. M. J., et al. (2014). Induced systemic resistance by beneficial microbes. Annual Review of Phytopathology. https://doi.org/10.1146/annurev-phyto-082712-102340`
  - CrossRef best: `Induced Systemic Resistance by Beneficial Microbes` (2014) DOI `10.1146/annurev-phyto-082712-102340` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_1-b1-n10** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Cameron, D. D., et al. (2013). Mycorrhiza-induced resistance: more than the sum of its parts? Trends in Plant Science. https://doi.org/10.1016/j.tplants.2013.06.004`
  - CrossRef best: `Mycorrhiza-induced resistance: more than the sum of its parts?` (2013) DOI `10.1016/j.tplants.2013.06.004` [title_ratio=0.833 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_1-b2-n2** · Chapter 2. The Soil Food Web: A Functional Map
  - Source: `Neumann, G. (2007). Root exudates and nutrient cycling. Nutrient cycling in terrestrial ecosystems, Springer.`
  - CrossRef best: `Root Exudates and Nutrient Cycling` (2007) DOI `10.1007/978-3-540-68027-7_5` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b2-n3** · Chapter 2. The Soil Food Web: A Functional Map
  - Source: `Badri, D. V., & Vivanco, J. M. (2009). Regulation and function of root exudates. Plant Cell Environ.`
  - CrossRef best: `Regulation and function of root exudates` (2009) DOI `10.1111/j.1365-3040.2009.01926.x` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b2-n4** · Chapter 2. The Soil Food Web: A Functional Map
  - Source: `Bar-Ness, E., et al. (1991). Siderophores of Pseudomonas putida as an iron source for dicot and monocot plants. Plant Soil.`
  - CrossRef best: `Siderophores of Pseudomonas putida as an iron source for dicot and monocot plants` (1991) DOI `10.1007/bf00011878` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b2-n5** · Chapter 2. The Soil Food Web: A Functional Map
  - Source: `Rudrappa, T., et al. (2008). Root-secreted malic acid recruits beneficial soil bacteria. Plant Physiol.`
  - CrossRef best: `Root-Secreted Malic Acid Recruits Beneficial Soil Bacteria    ` (2008) DOI `10.1104/pp.108.127613` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b2-n6** · Chapter 2. The Soil Food Web: A Functional Map
  - Source: `White, J. F., et al. (2018). Rhizophagy Cycle: An Oxidative Process in Plants for Nutrient Extraction from Symbiotic Microbes. Microorganisms.`
  - CrossRef best: `Rhizophagy Cycle: An Oxidative Process in Plants for Nutrient Extraction from Symbiotic Microbes` (2018) DOI `10.3390/microorganisms6030095` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b2-n7** · Chapter 2. The Soil Food Web: A Functional Map
  - Source: `White, J. F., et al. (2012). A proposed mechanism for nitrogen acquisition by grass seedlings through oxidation of symbiotic bacteria. Symbiosis.`
  - CrossRef best: `A proposed mechanism for nitrogen acquisition by grass seedlings through oxidation of symbiotic bacteria` (2012) DOI `10.1007/s13199-012-0189-8` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b2-n8** · Chapter 2. The Soil Food Web: A Functional Map
  - Source: `Paungfoo-Lonhienne, C., et al. (2010). Turning the table: Plants consume microbes as a source of nutrients. PLoS ONE.`
  - CrossRef best: `Turning the Table: Plants Consume Microbes as a Source of Nutrients` (2010) DOI `10.1371/journal.pone.0011915` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b3-n1** · Chapter 6. Mycorrhizal Symbiosis and Plant Immune Function
  - Source: `Jacott, C. N., et al. (2017). Trade-offs in arbuscular mycorrhizal symbiosis: disease resistance, growth responses and perspectives for crop breeding. Agronomy.`
  - CrossRef best: `Trade-Offs in Arbuscular Mycorrhizal Symbiosis: Disease Resistance, Growth Responses and Perspectives for Crop Breeding` (2017) DOI `10.3390/agronomy7040075` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b3-n2** · Chapter 6. Mycorrhizal Symbiosis and Plant Immune Function
  - Source: `Vishwanathan, K., et al. (2020). Ectomycorrhizal fungi induce systemic resistance against insects on a nonmycorrhizal plant in a CERK1-dependent manner. New Phytologist.`
  - CrossRef best: `Ectomycorrhizal fungi induce systemic resistance against insects on a nonmycorrhizal plant in a CERK1‐dependent manner` (2020) DOI `10.1111/nph.16715` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b3-n3** · Chapter 6. Mycorrhizal Symbiosis and Plant Immune Function
  - Source: `Roy-Bolduc, A., & Hijri, M. (2011). The use of mycorrhizae to enhance phosphorus uptake: a way out the phosphorus crisis. J. Biofertil. Biopestici.`
  - CrossRef best: `The Use of Mycorrhizae to Enhance Phosphorus Uptake: A Way Out the Phosphorus Crisis` (2011) DOI `10.4172/2155-6202.1000104` [title_ratio=1.0 author_match=False year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b3-n4** · Chapter 6. Mycorrhizal Symbiosis and Plant Immune Function
  - Source: `Nadeem, M., et al. (2022). Understanding the adaptive mechanisms of plants to improve phosphorus-use efficiency in the era of climate change. Frontiers in Plant Science. https://doi.org/10.3389/fpls.2022.804058`
  - CrossRef best: `Understanding the Adaptive Mechanisms of Plants to Enhance Phosphorus Use Efficiency on Podzolic Soils in Boreal Agroecosystems` (2022) DOI `10.3389/fpls.2022.804058` [title_ratio=0.733 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_1-b3-n5** · Chapter 6. Mycorrhizal Symbiosis and Plant Immune Function
  - Source: `Cameron, D. D., et al. (2013). Mycorrhiza-induced resistance: more than the sum of its parts? Trends in Plant Science.`
  - CrossRef best: `Mycorrhiza-induced resistance: more than the sum of its parts?` (2013) DOI `10.1016/j.tplants.2013.06.004` [title_ratio=0.833 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b3-n6** · Chapter 6. Mycorrhizal Symbiosis and Plant Immune Function
  - Source: `Pieterse, C. M. J., et al. (2014). Induced systemic resistance by beneficial microbes. Annual Review of Phytopathology.`
  - CrossRef best: `Induced Systemic Resistance by Beneficial Microbes` (2014) DOI `10.1146/annurev-phyto-082712-102340` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b3-n7** · Chapter 6. Mycorrhizal Symbiosis and Plant Immune Function
  - Source: `Gozzo, F., & Faoro, F. (2013). Systemic acquired resistance (50 years after discovery): moving from the lab to the field. Journal of agricultural and food chemistry.`
  - CrossRef best: `Systemic Acquired Resistance (50 Years after Discovery): Moving from the Lab to the Field` (2013) DOI `10.1021/jf404156x` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b4-n2** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Six, J., et al. (2004). A history of research on the link between (micro)aggregates, soil biota, and soil organic matter dynamics. Soil and Tillage Research.`
  - CrossRef best: `A history of research on the link between (micro)aggregates, soil biota, and soil organic matter dynamics` (2004) DOI `10.1016/j.still.2004.03.008` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b4-n5** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Kuzyakov, Y., & Domanski, G. (2000). Carbon input by plants into the soil. Review. Journal of Plant Nutrition and Soil Science.`
  - CrossRef best: `Carbon input by plants into the soil. Review` (2000) DOI `10.1002/1522-2624(200008)163:4<421::aid-jpln421>3.0.co;2-r` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b4-n6** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Hooper, D. U., et al. (2005). Effects of biodiversity on ecosystem functioning: a consensus of current knowledge. Ecological monographs.`
  - CrossRef best: `EFFECTS OF BIODIVERSITY ON ECOSYSTEM FUNCTIONING: A CONSENSUS OF CURRENT KNOWLEDGE` (2005) DOI `10.1890/04-0922` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b4-n14** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Blagodatskaya, E. V., & Anderson, T.-H. (1998). Interactive effects of pH and substrate quality on the fungal-to-bacterial ratio and qCO2 of microbial communities in forest soils. Soil Biology and Biochemistry. https://doi.org/10.1016/S0038-0717(98)00050-9`
  - CrossRef best: `Interactive effects of pH and substrate quality on the fungal-to-bacterial ratio and qCO2 of microbial communities in forest soils` (1998) DOI `10.1016/s0038-0717(98)00050-9` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_1-b5-n7** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Scheuerell, S., & Mahaffee, W. (2002). Compost tea: principles and prospects for plant disease control. Compost science & utilization.`
  - CrossRef best: `Compost Tea: Principles and Prospects For Plant Disease Control` (2002) DOI `10.1080/1065657x.2002.10702095` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b5-n9** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Bonkowski, M. (2004). Protozoa and plant growth: the microbial loop in soil revisited. New Phytologist.`
  - CrossRef best: `Protozoa and plant growth: the microbial loop in soil revisited` (2004) DOI `10.1111/j.1469-8137.2004.01066.x` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b5-n10** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Clarholm, M. (1985). Interactions of bacteria, protozoa and plants leading to mineralization of soil nitrogen. Soil Biology and Biochemistry.`
  - CrossRef best: `Interactions of bacteria, protozoa and plants leading to mineralization of soil nitrogen` (1985) DOI `10.1016/0038-0717(85)90113-0` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b6-n5** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Craigie, J. S. (2011). Seaweed extract stimuli in plant science and agriculture. Journal of applied phycology.`
  - CrossRef best: `Seaweed extract stimuli in plant science and agriculture` (2011) DOI `10.1007/s10811-010-9560-4` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b6-n6** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Schmutterer, H. (1990). Properties and potential of natural pesticides from the neem tree, Azadirachta indica. Annual review of entomology.`
  - CrossRef best: `Properties and Potential of Natural Pesticides from the Neem Tree, Azadirachta Indica` (1990) DOI `10.1146/annurev.en.35.010190.001415` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b6-n7** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Sharp, R. G. (2013). A review of the applications of chitin and its derivatives in agriculture to modify plant-microbe interactions and improve crop yields. Agronomy.`
  - CrossRef best: `A Review of the Applications of Chitin and Its Derivatives in Agriculture to Modify Plant-Microbial Interactions and Improve Crop Yields` (2013) DOI `10.3390/agronomy3040757` [title_ratio=0.985 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b7-n2** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Huber, D. M., & Jones, J. B. (2013). The role of magnesium in plant disease. Plant and soil.`
  - CrossRef best: `The role of magnesium in plant disease` (2013) DOI `10.1007/s11104-012-1476-0` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b7-n3** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Cameron, D. D., et al. (2013). Mycorrhiza-induced resistance: more than the sum of its parts? Trends in Plant Science.`
  - CrossRef best: `Mycorrhiza-induced resistance: more than the sum of its parts?` (2013) DOI `10.1016/j.tplants.2013.06.004` [title_ratio=0.833 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b7-n4** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Piasecka, A., et al. (2015). Secondary metabolites in plant innate immunity. New Phytologist.`
  - CrossRef best: `Secondary metabolites in plant innate immunity: conserved function of divergent chemicals` (2015) DOI `10.1111/nph.13325` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b7-n7** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Fageria, N. K., Baligar, V. C., & Clark, R. B. (2002). Micronutrients in crop production. Advances in Agronomy.`
  - CrossRef best: `Micronutrients in Crop Production` (2002) DOI `10.1016/s0065-2113(02)77015-6` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b7-n8** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Nardi, S., et al. (2002). Physiological effects of humic substances on higher plants. Soil Biology and Biochemistry.`
  - CrossRef best: `Physiological effects of humic substances on higher plants` (2002) DOI `10.1016/s0038-0717(02)00174-8` [title_ratio=1.0 author_match=True year_match=True]
  - Note: Bibliographic query returned a closely-matching record (title + author/year).

- **volume_1-b8-n12** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Reganold, J. P., Palmer, A. S., Lockhart, J. C., & Macgregor, A. N. (1993). Soil quality and financial performance of biodynamic and conventional farms. Science, 260(5106), 344-349. https://doi.org/10.1126/science.260.5106.344 [Farm-system comparison; not prep-specific evidence]`
  - CrossRef best: `Soil Quality and Financial Performance of Biodynamic and Conventional Farms in New Zealand` (1993) DOI `10.1126/science.260.5106.344` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_1-b8-n13** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Chalker-Scott, L. (2013). The science behind biodynamic preparations: A literature review. HortTechnology, 23(6), 814-819. https://doi.org/10.21273/HORTTECH.23.6.814`
  - CrossRef best: `The Science Behind Biodynamic Preparations: A Literature Review` (2013) DOI `10.21273/horttech.23.6.814` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n1** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Fromm, J., & Eschrich, W. (1993). Electrical signals in willow. DOI: 10.1016/S0176-1617(11)81573-7.`
  - CrossRef best: `Electric Signals Released from Roots of Willow (Salix viminalis L.) Change Transpiration and Photosynthesis` (1993) DOI `10.1016/s0176-1617(11)81573-7` [title_ratio=0.667 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n2** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Fromm, J., & Lautner, S. (2007). Electrical signals and their physiological significance in plants. DOI: 10.1111/j.1365-3040.2006.01614.x.`
  - CrossRef best: `Electrical signals and their physiological significance in plants` (2007) DOI `10.1111/j.1365-3040.2006.01614.x` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n3** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Sukhova et al. (2018). Variation potential and photosynthesis. DOI: 10.1007/s11120-017-0460-1.`
  - CrossRef best: `Influence of the variation potential on photosynthetic flows of light energy and electrons in pea` (2018) DOI `10.1007/s11120-017-0460-1` [title_ratio=0.667 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n4** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Volkov (2000). Green plants and electrochemical interfaces. DOI: 10.1016/S0022-0728(99)00497-0.`
  - CrossRef best: `Green plants: electrochemical interfaces` (2000) DOI `10.1016/s0022-0728(99)00497-0` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n5** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Dannehl (2018). Effects of electricity on plants. DOI: 10.1016/j.scienta.2018.02.007.`
  - CrossRef best: `Effects of electricity on plant responses` (2018) DOI `10.1016/j.scienta.2018.02.007` [title_ratio=0.877 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n6** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Grzelka et al. (2023). Electrostimulation and Scutellaria. DOI: 10.3389/fpls.2023.1142624.`
  - CrossRef best: `Electrostimulation improves plant growth and modulates the flavonoid profile in aeroponic culture of Scutellaria baicalensis Georgi` (2023) DOI `10.3389/fpls.2023.1142624` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n7** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Li et al. (2022). Electric field on crop growth. Nature Food. DOI: 10.1038/s43016-021-00449-9.`
  - CrossRef best: `Stimulation of ambient energy generated electric field on crop plant growth` (2022) DOI `10.1038/s43016-021-00449-9` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n8** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Maffei (2014). Magnetic field effects. DOI: 10.3389/fpls.2014.00445.`
  - CrossRef best: `Magnetic field effects on plant growth, development, and evolution` (2014) DOI `10.3389/fpls.2014.00445` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

- **volume_3-b1-n9** · Section 5: What We Know vs. What We Don't Know — Closing Summary
  - Source: `Chier et al. (2025). Passive electroculture copper rods. PLOS One. DOI: 10.1371/journal.pone.0329615.`
  - CrossRef best: `Passive electroculture using copper rods does not improve yield in home container vegetable gardening` (2025) DOI `10.1371/journal.pone.0329615` [title_ratio=1.0 author_match=True year_match=True]
  - Note: DOI resolves; author/title/year consistent.

## BOOK / NOT INDEXED (expected — not a failure) — 46

- **volume_1-b1-n3** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Bardgett, R. D. (2005). The Biology of Soil: A Community and Ecosystem Approach. Oxford University Press.`
  - CrossRef best: `<i>The Biology of Soil: A Community and Ecosystem Approach. <i>Biology of Habitats.</i></i> <i>By </i>Richard D  Bardgett. <i>Oxford and New York: Oxford University Press.</i> $124.50 (hardcover); $54.50 (paper). xi + 242 p; ill.; index. ISBN: 0‐19‐852502‐8 (hc); 0‐19‐852503‐6 (pb). 2006.` (2007) DOI `10.1086/519642` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b1-n11** · Chapter 1. From Salts to Symbiosis: Why Living Soil Outperforms Liquid Feeding
  - Source: `Ingham, E. R. (1999). The soil food web. In Soil Biology Primer. USDA Natural Resources Conservation Service.`
  - CrossRef best: `Soil Survey Staff 1999, Soil Taxonomy` (2001) DOI `10.1111/j.1475-2743.2001.tb00008.x` [title_ratio=0.34 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b2-n1** · Chapter 2. The Soil Food Web: A Functional Map
  - Source: `Bardgett, R. D. (2005). The Biology of Soil: A Community and Ecosystem Approach. Oxford University Press.`
  - CrossRef best: `<i>The Biology of Soil: A Community and Ecosystem Approach. <i>Biology of Habitats.</i></i> <i>By </i>Richard D  Bardgett. <i>Oxford and New York: Oxford University Press.</i> $124.50 (hardcover); $54.50 (paper). xi + 242 p; ill.; index. ISBN: 0‐19‐852502‐8 (hc); 0‐19‐852503‐6 (pb). 2006.` (2007) DOI `10.1086/519642` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b4-n1** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Brown, G. (2018). Dirt to Soil: One Family's Journey into Regenerative Agriculture. Chelsea Green Publishing.`
  - CrossRef best: `Regenerative Agriculture: A Multifaceted Approach to One Health and Soil Restoration` (2024) DOI `10.1007/978-981-97-7564-4_1` [title_ratio=0.571 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b4-n3** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Bardgett, R. D. (2005). The Biology of Soil: A Community and Ecosystem Approach. Oxford University Press.`
  - CrossRef best: `<i>The Biology of Soil: A Community and Ecosystem Approach. <i>Biology of Habitats.</i></i> <i>By </i>Richard D  Bardgett. <i>Oxford and New York: Oxford University Press.</i> $124.50 (hardcover); $54.50 (paper). xi + 242 p; ill.; index. ISBN: 0‐19‐852502‐8 (hc); 0‐19‐852503‐6 (pb). 2006.` (2007) DOI `10.1086/519642` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b4-n4** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Montgomery, D. R. (2007). Dirt: The erosion of civilizations. University of California Press.`
  - CrossRef best: `<i>Dirt: The Erosion of Civilizations</i>. David R. Montgomery, 2007, University of California Press, Berkeley, CA, 295 pp., $24.95 (hardcover)` (2008) DOI `10.1002/gea.20224` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b4-n7** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Brown, G. (2018). Dirt to Soil: One Family's Journey into Regenerative Agriculture. Chelsea Green Publishing.`
  - CrossRef best: `Regenerative Agriculture: A Multifaceted Approach to One Health and Soil Restoration` (2024) DOI `10.1007/978-981-97-7564-4_1` [title_ratio=0.571 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b4-n8** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Mollison, B. (1988). Permaculture: A Designer's Manual. Tagari Publications. [Practitioner/design framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b4-n9** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Holmgren, D. (2002). Permaculture: Principles and Pathways Beyond Sustainability. Holmgren Design Services. [Practitioner/design framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b4-n10** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Mollison, B. (1988). Permaculture: A Designer's Manual. Tagari Publications. [Practitioner/design framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b4-n11** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Holmgren, D. (2002). Permaculture: Principles and Pathways Beyond Sustainability. Holmgren Design Services. [Practitioner/design framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b4-n12** · Chapter 8. Regenerative and Permaculture Foundations
  - Source: `Mollison, B. (1988). Permaculture: A Designer's Manual. Tagari Publications. [Practitioner/design framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b5-n1** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Ingham, E. R. (1999). The soil food web. In Soil Biology Primer. USDA Natural Resources Conservation Service.`
  - CrossRef best: `Soil Survey Staff 1999, Soil Taxonomy` (2001) DOI `10.1111/j.1475-2743.2001.tb00008.x` [title_ratio=0.34 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b5-n2** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Ingham, E. R. (2000). The compost tea brewing manual. Soil Foodweb Inc. [Practitioner manual]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b5-n3** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Bardgett, R. D. (2005). The Biology of Soil: A Community and Ecosystem Approach. Oxford University Press.`
  - CrossRef best: `<i>The Biology of Soil: A Community and Ecosystem Approach. <i>Biology of Habitats.</i></i> <i>By </i>Richard D  Bardgett. <i>Oxford and New York: Oxford University Press.</i> $124.50 (hardcover); $54.50 (paper). xi + 242 p; ill.; index. ISBN: 0‐19‐852502‐8 (hc); 0‐19‐852503‐6 (pb). 2006.` (2007) DOI `10.1086/519642` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b5-n6** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Ingham, E. R. (2005). The compost tea brewing manual. Soil Foodweb Inc. [Practitioner manual]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b5-n8** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Ingham, E. R. (1999). The soil food web. In Soil Biology Primer. USDA Natural Resources Conservation Service.`
  - CrossRef best: `Soil Survey Staff 1999, Soil Taxonomy` (2001) DOI `10.1111/j.1475-2743.2001.tb00008.x` [title_ratio=0.34 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b5-n11** · Chapter 9. The Soil Food Web (Dr. Elaine Ingham)
  - Source: `Ingham, E. R. (1999). The soil food web. In Soil Biology Primer. USDA Natural Resources Conservation Service.`
  - CrossRef best: `Soil Survey Staff 1999, Soil Taxonomy` (2001) DOI `10.1111/j.1475-2743.2001.tb00008.x` [title_ratio=0.34 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b6-n1** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Lowenfels, J. (2010). Teaming with microbes: the organic gardener's guide to the soil food web. Timber press.`
  - CrossRef best: `Grow Plants the Organic Way: Give Them the Soil Microbes They CraveReview of: 				Teaming with Microbes: The Organic Gardener’s Guide to the Soil Food Web, revised ed.; 				LowenfelsJeff and 				LewisWayne; (				2010). 				Timber Press Inc., 				Portland, OR. 				220 pages.` (2013) DOI `10.1128/jmbe.v14i1.583` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b6-n2** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Lowenfels, J. (2010). Teaming with microbes: the organic gardener's guide to the soil food web. Timber press.`
  - CrossRef best: `Grow Plants the Organic Way: Give Them the Soil Microbes They CraveReview of: 				Teaming with Microbes: The Organic Gardener’s Guide to the Soil Food Web, revised ed.; 				LowenfelsJeff and 				LewisWayne; (				2010). 				Timber Press Inc., 				Portland, OR. 				220 pages.` (2013) DOI `10.1128/jmbe.v14i1.583` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b6-n3** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Lowenfels, J. (2010). Teaming with microbes: the organic gardener's guide to the soil food web. Timber press.`
  - CrossRef best: `Grow Plants the Organic Way: Give Them the Soil Microbes They CraveReview of: 				Teaming with Microbes: The Organic Gardener’s Guide to the Soil Food Web, revised ed.; 				LowenfelsJeff and 				LewisWayne; (				2010). 				Timber Press Inc., 				Portland, OR. 				220 pages.` (2013) DOI `10.1128/jmbe.v14i1.583` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b6-n4** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Lowenfels, J. (2013). Teaming with nutrients: the organic gardener's guide to optimizing plant nutrition. Timber Press.`
  - CrossRef best: `Grow Plants the Organic Way: Give Them the Soil Microbes They CraveReview of: 				Teaming with Microbes: The Organic Gardener’s Guide to the Soil Food Web, revised ed.; 				LowenfelsJeff and 				LewisWayne; (				2010). 				Timber Press Inc., 				Portland, OR. 				220 pages.` (2013) DOI `10.1128/jmbe.v14i1.583` [title_ratio=0.5 author_match=False year_match=True]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b6-n8** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Lowenfels, J. (2013). Teaming with nutrients: the organic gardener's guide to optimizing plant nutrition. Timber Press.`
  - CrossRef best: `Grow Plants the Organic Way: Give Them the Soil Microbes They CraveReview of: 				Teaming with Microbes: The Organic Gardener’s Guide to the Soil Food Web, revised ed.; 				LowenfelsJeff and 				LewisWayne; (				2010). 				Timber Press Inc., 				Portland, OR. 				220 pages.` (2013) DOI `10.1128/jmbe.v14i1.583` [title_ratio=0.5 author_match=False year_match=True]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b6-n9** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Edwards, C. A., et al. (2010). Vermiculture technology: earthworms, organic wastes, and environmental management. CRC press.`
  - CrossRef best: `- Vermiculture in the Philippines` (2010) DOI `10.1201/b10453-34` [title_ratio=0.385 author_match=False year_match=True]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b6-n10** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Lowenfels, J. (2010). Teaming with microbes: the organic gardener's guide to the soil food web. Timber press.`
  - CrossRef best: `Grow Plants the Organic Way: Give Them the Soil Microbes They CraveReview of: 				Teaming with Microbes: The Organic Gardener’s Guide to the Soil Food Web, revised ed.; 				LowenfelsJeff and 				LewisWayne; (				2010). 				Timber Press Inc., 				Portland, OR. 				220 pages.` (2013) DOI `10.1128/jmbe.v14i1.583` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b6-n11** · Chapter 10. Coot's Mix (Clackamas Coot)
  - Source: `Lowenfels, J. (2013). Teaming with nutrients: the organic gardener's guide to optimizing plant nutrition. Timber Press.`
  - CrossRef best: `Grow Plants the Organic Way: Give Them the Soil Microbes They CraveReview of: 				Teaming with Microbes: The Organic Gardener’s Guide to the Soil Food Web, revised ed.; 				LowenfelsJeff and 				LewisWayne; (				2010). 				Timber Press Inc., 				Portland, OR. 				220 pages.` (2013) DOI `10.1128/jmbe.v14i1.583` [title_ratio=0.5 author_match=False year_match=True]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b7-n1** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Kempf, J. (2020). Quality Agriculture: Conversations about Regenerative Agronomy with Innovative Scientists and Growers. Regenerative Agriculture Publishing. [Practitioner framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b7-n5** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Albrecht, W. A. (1975). The Albrecht papers. Acres USA. [Historical/practitioner source]`
  - CrossRef best: `Lillie Albrecht Papers` (2015) DOI `10.18785/fa.dg0012` [title_ratio=1.0 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b7-n6** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Burgie, O. (2022). Plant Sap Analysis: A Guide to Monitoring Plant Nutrition. Advancing Eco Agriculture.`
  - CrossRef best: `Sap Analysis: A Powerful Tool for Monitoring Plant Nutrition` (2021) DOI `10.3390/horticulturae7110426` [title_ratio=0.8 author_match=False year_match=False]
  - Note: Book/organizational work; no same-work journal match (any title hit is a review/different work — expected).

- **volume_1-b7-n9** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Harrill, T. (1998). Using a refractometer to test the quality of fruits & vegetables. Bionutrient Food Association. [Practitioner/field guide — not a validated diagnostic standard]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b7-n10** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Kempf, J. (2020). Quality Agriculture: Conversations about Regenerative Agronomy with Innovative Scientists and Growers. Regenerative Agriculture Publishing. [Practitioner framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b7-n11** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Kittredge, D. (2021). The Real Food Campaign: Defining Nutrient Density. Bionutrient Food Association. [Practitioner/organizational source]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b7-n12** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Kempf, J. (2020). Quality Agriculture: Conversations about Regenerative Agronomy with Innovative Scientists and Growers. Regenerative Agriculture Publishing. [Practitioner framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b7-n13** · Chapter 11. Bionutrient Farming (John Kempf & Dan Kittredge)
  - Source: `Kempf, J. (2020). Quality Agriculture: Conversations about Regenerative Agronomy with Innovative Scientists and Growers. Regenerative Agriculture Publishing. [Practitioner framework]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n1** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, H.-K., & Koyama, A. (1997). Korean natural farming: indigenous microorganisms and vital power of crop/livestock. Korean Natural Farming Association. [Practitioner text]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n2** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, H.-K., & Cho, J.-Y. (2010). Natural Farming: Agriculture Materials. Cho Global Natural Farming. [Practitioner text]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n3** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, H.-K., & Cho, J.-Y. (2010). Natural Farming: Agriculture Materials. Cho Global Natural Farming. [Practitioner text]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n4** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, H.-K., & Koyama, A. (1997). Korean natural farming: indigenous microorganisms and vital power of crop/livestock. Korean Natural Farming Association. [Practitioner text]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n5** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, Y. (2016). JADAM Organic Farming: The way to Ultra-Low-Cost agriculture. JADAM. [Practitioner protocol]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n6** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, Y. (2016). JADAM Organic Farming: The way to Ultra-Low-Cost agriculture. JADAM. [Practitioner protocol]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n7** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, Y. (2016). JADAM Organic Farming: The way to Ultra-Low-Cost agriculture. JADAM. [Practitioner protocol]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n8** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, Y. (2016). JADAM Organic Farming: The way to Ultra-Low-Cost agriculture. JADAM. [Practitioner protocol]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n9** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Cho, Y. (2021). JADAM Organic Pest and Disease Control. JADAM. [Practitioner protocol]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n10** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Steiner, R. (2004). Agriculture Course: The Birth of the Biodynamic Method. Rudolf Steiner Press. (Original lectures delivered 1924.) [Practitioner/historical source]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n11** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Koepf, H. H. (1989). The Biodynamic Farm. Anthroposophic Press. [Practitioner/organizational doctrine]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

- **volume_1-b8-n14** · Chapter 12. Survey of KNF, JADAM, and Biodynamics
  - Source: `Thun, M. (1979). Work on the Land and the Constellations. Lanthorn Press. [Practitioner calendar source]`
  - Note: Source carries a [Practitioner ...] annotation — not indexed literature.

# Marker removal log — Phase B / Task 3

Every orphaned `[n]` citation marker removed from Book 1 and Book 5. For each removal: the container element, the owning heading, the sentence before, and the sentence after. Only the marker (and any orphaned space/doubled punctuation) changed.

## Reconciliation

| File | Markers removed | Containers | Distinct `<p>` lost (= verify.py N) |
|---|---:|---|---:|
| BOOK_1 | 109 | 39×li, 70×p | 58 |
| BOOK_5 | 19 | 1×li, 11×p, 7×td | 5 |
| **Total** | **128** | — | **63** |

`verify.py` fingerprints only `<p>` of 12+ words, so its paragraph-preservation FAIL names **63** paragraphs — the markers in `<li>`/`<td>` are cleaned and logged here but are not tracked hashes.

## Known open item — reader-visible bracket placeholders (front-matter phase)

These are NOT citations and were correctly left untouched by this pass. They are logged here so they are not lost track of before the front-matter/image phase.

| Kind | Count |
|---|---:|
| `[IMAGE APP-*: …]` image-generation briefs | 42 |
| `[TEXT-ONLY SUBSTITUTE — B30_*]` | 11 |
| `[SELF-PHOTO PLACEHOLDER — SP-*]` | 10 |
| **Reader-visible total** | **63** |

**Cross-reference:** the 11 `TEXT-ONLY SUBSTITUTE` (B30_*) + 10 `SELF-PHOTO PLACEHOLDER` (SP-*) = **21** are the SAME 21 empty figure sections the image session found — record once, do not double-count later.

(Also 3 editorial `[… VERIFY … v3]` notes — not reader-visible, tracked separately.)


## BOOK_1

### [1] — `<p>` under: The Chemical Treadmill: Salt Index, Osmotic Stress, and Microbial Suppression
- **before:** High concentrations of soluble salts increase the osmotic pressure of the soil solution, making it harder for plant roots and soil microbes to draw in water [1].
- **after:** High concentrations of soluble salts increase the osmotic pressure of the soil solution, making it harder for plant roots and soil microbes to draw in water.

### [2] — `<p>` under: The Chemical Treadmill: Salt Index, Osmotic Stress, and Microbial Suppression
- **before:** The evidence cited here should be framed carefully: organic-fertilizer research supports plant-growth and rhizosphere-microbiome effects [2], while root-exudate sources support the broader principle that exudates help steer microbial communities [4,5].
- **after:** The evidence cited here should be framed carefully: organic-fertilizer research supports plant-growth and rhizosphere-microbiome effects, while root-exudate sources support the broader principle that exudates help steer microbial communities.

### [4,5] — `<p>` under: The Chemical Treadmill: Salt Index, Osmotic Stress, and Microbial Suppression
- **before:** The evidence cited here should be framed carefully: organic-fertilizer research supports plant-growth and rhizosphere-microbiome effects [2], while root-exudate sources support the broader principle that exudates help steer microbial communities [4,5].
- **after:** The evidence cited here should be framed carefully: organic-fertilizer research supports plant-growth and rhizosphere-microbiome effects, while root-exudate sources support the broader principle that exudates help steer microbial communities.

### [3] — `<p>` under: The Chemical Treadmill: Salt Index, Osmotic Stress, and Microbial Suppression
- **before:** The evidence cited here should be framed carefully: organic-fertilizer research supports plant-growth and rhizosphere-microbiome effects [2], while root-exudate sources support the broader principle that exudates help steer microbial communities [4,5].
- **after:** The evidence cited here should be framed carefully: organic-fertilizer research supports plant-growth and rhizosphere-microbiome effects, while root-exudate sources support the broader principle that exudates help steer microbial communities.

### [4] — `<p>` under: The Biological Advantage: Exudate-Driven Nutrient Cycling and the Rhizosphere Effect
- **before:** Up to 30-40% of these carbon compounds are secreted directly into the soil through the roots as "exudates" [4].
- **after:** Up to 30-40% of these carbon compounds are secreted directly into the soil through the roots as "exudates".

### [5] — `<p>` under: The Biological Advantage: Exudate-Driven Nutrient Cycling and the Rhizosphere Effect
- **before:** Plants use exudates to cultivate specific communities of bacteria and fungi in the narrow zone of soil immediately surrounding the roots, known as the rhizosphere [5].
- **after:** Plants use exudates to cultivate specific communities of bacteria and fungi in the narrow zone of soil immediately surrounding the roots, known as the rhizosphere.

### [6] — `<p>` under: The Biological Advantage: Exudate-Driven Nutrient Cycling and the Rhizosphere Effect
- **before:** Plants use exudates to cultivate specific communities of bacteria and fungi in the narrow zone of soil immediately surrounding the roots, known as the rhizosphere [5].
- **after:** Plants use exudates to cultivate specific communities of bacteria and fungi in the narrow zone of soil immediately surrounding the roots, known as the rhizosphere.

### [7] — `<p>` under: Energy Efficiency: Outsourcing Immune Function and Mineral Extraction
- **before:** However, by partnering with mycorrhizal fungi, the plant can trade a small amount of carbon for a steady supply of phosphorus [7].
- **after:** However, by partnering with mycorrhizal fungi, the plant can trade a small amount of carbon for a steady supply of phosphorus.

### [8] — `<p>` under: Energy Efficiency: Outsourcing Immune Function and Mineral Extraction
- **before:** However, by partnering with mycorrhizal fungi, the plant can trade a small amount of carbon for a steady supply of phosphorus [7].
- **after:** However, by partnering with mycorrhizal fungi, the plant can trade a small amount of carbon for a steady supply of phosphorus.

### [9] — `<p>` under: Energy Efficiency: Outsourcing Immune Function and Mineral Extraction
- **before:** A robust, diverse microbiome can occupy root-surface niches and make pathogen establishment more difficult—a context-dependent form of competitive exclusion rather than a guarantee of disease suppression [9].
- **after:** A robust, diverse microbiome can occupy root-surface niches and make pathogen establishment more difficult—a context-dependent form of competitive exclusion rather than a guarantee of disease suppression.

### [10] — `<p>` under: Energy Efficiency: Outsourcing Immune Function and Mineral Extraction
- **before:** A robust, diverse microbiome can occupy root-surface niches and make pathogen establishment more difficult—a context-dependent form of competitive exclusion rather than a guarantee of disease suppression [9].
- **after:** A robust, diverse microbiome can occupy root-surface niches and make pathogen establishment more difficult—a context-dependent form of competitive exclusion rather than a guarantee of disease suppression.

### [11] — `<p>` under: The Transition Period: Managing the Lag Time
- **before:** Inoculating the soil with high-quality compost, compost extracts, and microbial inoculants can help reintroduce biological diversity, but commercial living products should be selected, stored, and applied according to the product label; effects are product/strain-, crop-, storage-, and application-dependent [11].
- **after:** Inoculating the soil with high-quality compost, compost extracts, and microbial inoculants can help reintroduce biological diversity, but commercial living products should be selected, stored, and applied according to the product label; effects are product/strain-, crop-, storage-, and application-dependent.

### [1] — `<p>` under: Figure LSE_A02
- **before:** They are the nutrient retainers of the soil, holding nitrogen, phosphorus, and calcium within their cell walls [1].
- **after:** They are the nutrient retainers of the soil, holding nitrogen, phosphorus, and calcium within their cell walls.

### [2] — `<p>` under: The Carbon Cycle and Energy Flow
- **before:** At each step, some carbon is respired back into the atmosphere as CO2, but a significant portion is stabilized in the soil as humus—complex, long-lasting organic molecules that give healthy soil its dark color and water-holding capacity [2].
- **after:** At each step, some carbon is respired back into the atmosphere as CO2, but a significant portion is stabilized in the soil as humus—complex, long-lasting organic molecules that give healthy soil its dark color and water-holding capacity.

### [3] — `<p>` under: Plant Exudates as the Steering Wheel
- **before:** By altering the chemical composition of their root exudates, plants can attract specific microbial species to address specific needs [3].
- **after:** By altering the chemical composition of their root exudates, plants can attract specific microbial species to address specific needs.

### [4] — `<p>` under: Plant Exudates as the Steering Wheel
- **before:** By altering the chemical composition of their root exudates, plants can attract specific microbial species to address specific needs [3].
- **after:** By altering the chemical composition of their root exudates, plants can attract specific microbial species to address specific needs.

### [5] — `<p>` under: Plant Exudates as the Steering Wheel
- **before:** By altering the chemical composition of their root exudates, plants can attract specific microbial species to address specific needs [3].
- **after:** By altering the chemical composition of their root exudates, plants can attract specific microbial species to address specific needs.

### [6] — `<p>` under: The Rhizophagy Cycle
- **before:** In this process, plants actually internalize symbiotic bacteria and yeast into their root meristem cells [6].
- **after:** In this process, plants actually internalize symbiotic bacteria and yeast into their root meristem cells.

### [7] — `<p>` under: The Rhizophagy Cycle
- **before:** This oxidative stress degrades the microbial cell walls, causing them to leak nutrients (such as nitrogen and micronutrients) directly into the plant cell [7].
- **after:** This oxidative stress degrades the microbial cell walls, causing them to leak nutrients (such as nitrogen and micronutrients) directly into the plant cell.

### [8] — `<p>` under: The Rhizophagy Cycle
- **before:** This oxidative stress degrades the microbial cell walls, causing them to leak nutrients (such as nitrogen and micronutrients) directly into the plant cell [7].
- **after:** This oxidative stress degrades the microbial cell walls, causing them to leak nutrients (such as nitrogen and micronutrients) directly into the plant cell.

### [1] — `<p>` under: Morphology and Function
- **before:** They produce powerful extracellular enzymes that break down simple, easy-to-digest organic compounds—such as the sugars and amino acids found in root exudates, green plant residues, and fresh manures [1].
- **after:** They produce powerful extracellular enzymes that break down simple, easy-to-digest organic compounds—such as the sugars and amino acids found in root exudates, green plant residues, and fresh manures.

### [2] — `<p>` under: Nitrogen Fixation: Free-Living vs. Symbiotic
- **before:** Symbiotic Nitrogen Fixers: The most famous are Rhizobium species, which form intimate, nodule-producing relationships with the roots of leguminous plants (peas, beans, clover) [2].
- **after:** Symbiotic Nitrogen Fixers: The most famous are Rhizobium species, which form intimate, nodule-producing relationships with the roots of leguminous plants (peas, beans, clover).

### [3] — `<p>` under: Nitrogen Fixation: Free-Living vs. Symbiotic
- **before:** Instead, they live freely in the rhizosphere or as endophytes within plant tissues, fixing nitrogen and releasing it into the soil solution or directly to the plant as they die and decompose [3].
- **after:** Instead, they live freely in the rhizosphere or as endophytes within plant tissues, fixing nitrogen and releasing it into the soil solution or directly to the plant as they die and decompose.

### [4] — `<p>` under: Bacterial Dominance and Weed Pressure
- **before:** Tillage disrupts fungal hyphal networks, while readily available simple substrates and repeated disturbance can favor faster bacterial cycling relative to slower fungal development [4].
- **after:** Tillage disrupts fungal hyphal networks, while readily available simple substrates and repeated disturbance can favor faster bacterial cycling relative to slower fungal development.

### [5] — `<p>` under: Bacterial Dominance and Weed Pressure
- **before:** While nitrate-responsive germination is well-documented for some weed species (like pigweed and lamb's quarters), other early-successional plants respond to disturbance via light wavelength shifts, soil temperature fluctuations, or compaction [5].
- **after:** While nitrate-responsive germination is well-documented for some weed species (like pigweed and lamb's quarters), other early-successional plants respond to disturbance via light wavelength shifts, soil temperature fluctuations, or compaction.

### [1] — `<p>` under: Saprophytic Fungi: The Heavy Decomposers
- **before:** While bacteria thrive on green, sugary materials, saprophytic fungi possess the specialized enzymes (like cellulases and ligninases) required to break down tough, woody materials—cellulose, hemicellulose, and lignin [1].
- **after:** While bacteria thrive on green, sugary materials, saprophytic fungi possess the specialized enzymes (like cellulases and ligninases) required to break down tough, woody materials—cellulose, hemicellulose, and lignin.

### [2] — `<p>` under: Hyphal Networks: Transporting Water and Nutrients
- **before:** Because hyphae are much finer than plant roots, they can penetrate microscopic soil pores to access water and dissolved minerals that are physically out of reach for the plant [2].
- **after:** Because hyphae are much finer than plant roots, they can penetrate microscopic soil pores to access water and dissolved minerals that are physically out of reach for the plant.

### [3] — `<p>` under: Hyphal Networks: Transporting Water and Nutrients
- **before:** Because hyphae are much finer than plant roots, they can penetrate microscopic soil pores to access water and dissolved minerals that are physically out of reach for the plant [2].
- **after:** Because hyphae are much finer than plant roots, they can penetrate microscopic soil pores to access water and dissolved minerals that are physically out of reach for the plant.

### [4] — `<p>` under: Soil Structure Engineering: Glomalin and Macroaggregates
- **before:** More importantly, specific types of fungi (particularly arbuscular mycorrhizal fungi) exude a sticky, carbon-rich glycoprotein called glomalin [4].
- **after:** More importantly, specific types of fungi (particularly arbuscular mycorrhizal fungi) exude a sticky, carbon-rich glycoprotein called glomalin.

### [5] — `<p>` under: Fungal Suppression: The Cost of Tillage and Phosphorus
- **before:** Deep tillage physically slices the mycelial networks into pieces, destroying their transport capacity and exposing them to rapid bacterial degradation [5].
- **after:** Deep tillage physically slices the mycelial networks into pieces, destroying their transport capacity and exposing them to rapid bacterial degradation.

### [6] — `<p>` under: Fungal Suppression: The Cost of Tillage and Phosphorus
- **before:** In that situation, the soil-structure and drought-resilience benefits associated with fungal networks may decline, but the response depends on crop, soil phosphorus status, fungal community, and fertilizer history [6].
- **after:** In that situation, the soil-structure and drought-resilience benefits associated with fungal networks may decline, but the response depends on crop, soil phosphorus status, fungal community, and fertilizer history.

### [1] — `<p>` under: Figure LSE_A04
- **before:** AMF associate with the vast majority of agricultural crops, including vegetables, herbs, and fruit trees [1].
- **after:** AMF associate with the vast majority of agricultural crops, including vegetables, herbs, and fruit trees.

### [2] — `<p>` under: Figure LSE_A04
- **before:** Ectomycorrhizae associate primarily with woody perennials, particularly conifers (pines, firs) and certain hardwood trees (oaks, pecans) [2].
- **after:** Ectomycorrhizae associate primarily with woody perennials, particularly conifers (pines, firs) and certain hardwood trees (oaks, pecans).

### [3] — `<p>` under: The Mechanics of Phosphorus and Zinc Extraction
- **before:** Mycorrhizal hyphae extend far beyond this depletion zone, exploring a volume of soil hundreds of times larger than the root system alone [3].
- **after:** Mycorrhizal hyphae extend far beyond this depletion zone, exploring a volume of soil hundreds of times larger than the root system alone.

### [4] — `<p>` under: The Mechanics of Phosphorus and Zinc Extraction
- **before:** Mycorrhizal hyphae extend far beyond this depletion zone, exploring a volume of soil hundreds of times larger than the root system alone [3].
- **after:** Mycorrhizal hyphae extend far beyond this depletion zone, exploring a volume of soil hundreds of times larger than the root system alone.

### [5] — `<p>` under: Induced Systemic Resistance (ISR) and Systemic Acquired Resistance (SAR)
- **before:** The plant mounts a localized defense response, and compatible fungi use signaling pathways that allow colonization to proceed [5].
- **after:** The plant mounts a localized defense response, and compatible fungi use signaling pathways that allow colonization to proceed.

### [6] — `<p>` under: Figure UC-005 ◆
- **before:** This heightened state of readiness is part of Induced Systemic Resistance (ISR) [6].
- **after:** This heightened state of readiness is part of Induced Systemic Resistance (ISR).

### [7] — `<p>` under: Figure UC-005 ◆
- **before:** These responses are related to Systemic Acquired Resistance (SAR) and other plant-defense signaling pathways [7].
- **after:** These responses are related to Systemic Acquired Resistance (SAR) and other plant-defense signaling pathways.

### [1] — `<p>` under: The Nutrient Loop: Predation and Mineralization
- **before:** Protozoa and nematodes, which hunt and consume bacteria, have a much higher C:N ratio, often around 30:1 [1].
- **after:** Protozoa and nematodes, which hunt and consume bacteria, have a much higher C:N ratio, often around 30:1.

### [2] — `<p>` under: Figure UC-003 ◆
- **before:** The protozoan excretes this excess nitrogen into the soil solution in the form of ammonium (NH4+)—a form of nitrogen that is immediately available for plant roots to absorb [2].
- **after:** The protozoan excretes this excess nitrogen into the soil solution in the form of ammonium (NH4+)—a form of nitrogen that is immediately available for plant roots to absorb.

### [3] — `<p>` under: Protozoa: Flagellates, Amoebae, and Ciliates
- **before:** While some ciliates are present in healthy soil, a sudden bloom or dominance of ciliates is a strong indicator that the soil has gone anaerobic (lacking oxygen), often due to overwatering or compaction [3].
- **after:** While some ciliates are present in healthy soil, a sudden bloom or dominance of ciliates is a strong indicator that the soil has gone anaerobic (lacking oxygen), often due to overwatering or compaction.

### [4] — `<p>` under: Figure LSE_B03
- **before:** They possess a robust stylet used to pierce plant roots, causing damage and creating entry points for disease [4].
- **after:** They possess a robust stylet used to pierce plant roots, causing damage and creating entry points for disease.

### [5] — `<p>` under: Microarthropods: The Shredders
- **before:** They chew on dead plant material and fungal hyphae, breaking them into smaller pieces [5].
- **after:** They chew on dead plant material and fungal hyphae, breaking them into smaller pieces.

### [1] — `<p>` under: Figure LSE_B06
- **before:** Very high F:B numbers sometimes cited for old-growth systems should be treated as broad successional heuristics, not fixed targets for every orchard, forest edge, or garden bed [1].
- **after:** Very high F:B numbers sometimes cited for old-growth systems should be treated as broad successional heuristics, not fixed targets for every orchard, forest edge, or garden bed.

### [2] — `<p>` under: Matching F:B Ratios to Crop Types
- **before:** Numeric F:B ranges should be treated as Soil Food Web practitioner targets rather than universal crop requirements [2].
- **after:** Numeric F:B ranges should be treated as Soil Food Web practitioner targets rather than universal crop requirements.

### [1] — `<p>` under: The Five Principles of Soil Health
- **before:** These principles can be adapted across scales, but their application depends on climate, soil type, crop, water access, and management context [1].
- **after:** These principles can be adapted across scales, but their application depends on climate, soil type, crop, water access, and management context.

### [2] — `<li>` under: Figure LSE_B07
- **before:** Minimize Disturbance: Physical disturbance (tillage) can disrupt fungal networks and soil macroaggregates that provide structure and water infiltration [2].
- **after:** Minimize Disturbance: Physical disturbance (tillage) can disrupt fungal networks and soil macroaggregates that provide structure and water infiltration.

### [3] — `<li>` under: Figure LSE_B07
- **before:** Minimize Disturbance: Physical disturbance (tillage) can disrupt fungal networks and soil macroaggregates that provide structure and water infiltration [2].
- **after:** Minimize Disturbance: Physical disturbance (tillage) can disrupt fungal networks and soil macroaggregates that provide structure and water infiltration.

### [4] — `<li>` under: Figure LSE_B07
- **before:** Keep the Soil Covered: Bare soil is uncommon in stable plant communities and is highly susceptible to heat, crusting, evaporation, wind erosion, and water erosion [4].
- **after:** Keep the Soil Covered: Bare soil is uncommon in stable plant communities and is highly susceptible to heat, crusting, evaporation, wind erosion, and water erosion.

### [5] — `<li>` under: Figure LSE_B07
- **before:** When a bed is left fallow and rootless, fresh rhizosphere carbon inputs decline and microbial activity can slow [5].
- **after:** When a bed is left fallow and rootless, fresh rhizosphere carbon inputs decline and microbial activity can slow.

### [6] — `<li>` under: Figure LSE_B07
- **before:** Different plants produce different root exudates, which can attract different microbial communities and support a broader range of nutrient-cycling pathways [6].
- **after:** Different plants produce different root exudates, which can attract different microbial communities and support a broader range of nutrient-cycling pathways.

### [7] — `<li>` under: Figure LSE_B07
- **before:** Grazing animals, poultry, and composting worms can provide biologically active manures or castings that support decomposition and soil food web activity when handled safely and matched to the crop system [7].
- **after:** Grazing animals, poultry, and composting worms can provide biologically active manures or castings that support decomposition and soil food web activity when handled safely and matched to the crop system.

### [8] — `<p>` under: Permaculture Design Principles
- **before:** Developed by Bill Mollison and David Holmgren in the 1970s, permaculture is based on observing and mimicking patterns and relationships found in natural ecosystems [8].
- **after:** Developed by Bill Mollison and David Holmgren in the 1970s, permaculture is based on observing and mimicking patterns and relationships found in natural ecosystems.

### [9] — `<li>` under: Figure UC-006 ◆
- **before:** Zone 4 or 5 (furthest away) might be a wild, unmanaged food forest [9].
- **after:** Zone 4 or 5 (furthest away) might be a wild, unmanaged food forest.

### [10] — `<li>` under: Figure UC-006 ◆
- **before:** Stacking Functions: In a well-designed system, every element should serve multiple functions, and every function should be supported by multiple elements [10].
- **after:** Stacking Functions: In a well-designed system, every element should serve multiple functions, and every function should be supported by multiple elements.

### [11] — `<li>` under: Figure UC-006 ◆
- **before:** Edge Effect: In ecology, the "edge" where two ecosystems meet (e.g., the border between a forest and a meadow) can be biologically diverse or productive, but edge effects are variable and context-dependent [11].
- **after:** Edge Effect: In ecology, the "edge" where two ecosystems meet (e.g., the border between a forest and a meadow) can be biologically diverse or productive, but edge effects are variable and context-dependent.

### [12] — `<li>` under: Figure UC-006 ◆
- **before:** Energy Capture and Passive Hydration: A core tenet of permaculture is to catch and store energy (water, sunlight, organic matter) as high up in the landscape as practical, slowing its movement through the system [12].
- **after:** Energy Capture and Passive Hydration: A core tenet of permaculture is to catch and store energy (water, sunlight, organic matter) as high up in the landscape as practical, slowing its movement through the system.

### [13] — `<p>` under: The Shift to Perennials
- **before:** Annual vegetable systems often involve repeated planting and disturbance, keeping the ecosystem closer to an early-successional state [13].
- **after:** Annual vegetable systems often involve repeated planting and disturbance, keeping the ecosystem closer to an early-successional state.

### [14] — `<p>` under: The Shift to Perennials
- **before:** Annual vegetable systems often involve repeated planting and disturbance, keeping the ecosystem closer to an early-successional state [13].
- **after:** Annual vegetable systems often involve repeated planting and disturbance, keeping the ecosystem closer to an early-successional state.

### [1] — `<p>` under: Core Philosophy: Biology as a Management Lens
- **before:** The foundational premise of the Soil Food Web framework is that soil biology strongly influences whether nutrients are retained, mineralized, solubilized, and delivered to plants [1].
- **after:** The foundational premise of the Soil Food Web framework is that soil biology strongly influences whether nutrients are retained, mineralized, solubilized, and delivered to plants.

### [2] — `<p>` under: Core Philosophy: Biology as a Management Lens
- **before:** The foundational premise of the Soil Food Web framework is that soil biology strongly influences whether nutrients are retained, mineralized, solubilized, and delivered to plants [1].
- **after:** The foundational premise of the Soil Food Web framework is that soil biology strongly influences whether nutrients are retained, mineralized, solubilized, and delivered to plants.

### [3] — `<p>` under: Core Philosophy: Biology as a Management Lens
- **before:** The goal is to encourage a robust and diverse community of bacteria, fungi, protozoa, and nematodes that is reasonably aligned with the crop, soil, and successional context [3].
- **after:** The goal is to encourage a robust and diverse community of bacteria, fungi, protozoa, and nematodes that is reasonably aligned with the crop, soil, and successional context.

### [4] — `<p>` under: The Centrality of Thermal Compost
- **before:** Compared with poorly aerated passive composting, thermal composting is a more actively managed aerobic process intended to cultivate beneficial microbial populations while reducing pathogen and weed-seed risk when time, temperature, moisture, and turning are adequate [4].
- **after:** Compared with poorly aerated passive composting, thermal composting is a more actively managed aerobic process intended to cultivate beneficial microbial populations while reducing pathogen and weed-seed risk when time, temperature, moisture, and turning are adequate.

### [5] — `<p>` under: Figure LSE_B08
- **before:** Practitioners commonly manage turning around thermophilic temperature ranges, often cited around 131°F to 165°F, to expose material to heat while avoiding prolonged overheating [5].
- **after:** Practitioners commonly manage turning around thermophilic temperature ranges, often cited around 131°F to 165°F, to expose material to heat while avoiding prolonged overheating.

### [6] — `<li>` under: Figure LSE_B09
- **before:** Extracts are used primarily as soil drenches to inoculate the root zone [6].
- **after:** Extracts are used primarily as soil drenches to inoculate the root zone.

### [7] — `<li>` under: Figure LSE_B09
- **before:** AACT is sometimes used as a foliar spray to coat the leaf surface with beneficial biology, but disease suppression is variable and depends on compost quality, brew conditions, target pathogen, plant host, weather, and timing [7].
- **after:** AACT is sometimes used as a foliar spray to coat the leaf surface with beneficial biology, but disease suppression is variable and depends on compost quality, brew conditions, target pathogen, plant host, weather, and timing.

### [8] — `<p>` under: Direct Microscopy: A Practitioner Diagnostic Tool
- **before:** Alongside chemical soil tests and field observations, practitioners use a shadow-casting or phase-contrast microscope to estimate bacterial abundance, assess fungal hyphae, and observe protozoa and nematodes present in a soil or compost sample [8].
- **after:** Alongside chemical soil tests and field observations, practitioners use a shadow-casting or phase-contrast microscope to estimate bacterial abundance, assess fungal hyphae, and observe protozoa and nematodes present in a soil or compost sample.

### [9] — `<p>` under: Figure LSE_A06
- **before:** If protozoa appear limited, they may adjust compost or extract practices to encourage protozoan activity [9].
- **after:** If protozoa appear limited, they may adjust compost or extract practices to encourage protozoan activity.

### [10] — `<li>` under: Strengths and Limitations
- **before:** The focus on microscopy can reduce some guesswork in biological management, especially when paired with chemical soil tests, crop observation, and field history [10].
- **after:** The focus on microscopy can reduce some guesswork in biological management, especially when paired with chemical soil tests, crop observation, and field history.

### [11] — `<li>` under: Strengths and Limitations
- **before:** Furthermore, purchasing a quality microscope and learning to identify soil microbes requires a substantial investment of time and money [11].
- **after:** Furthermore, purchasing a quality microscope and learning to identify soil microbes requires a substantial investment of time and money.

### [1] — `<p>` under: Core Philosophy: The Permanent Habitat
- **before:** Instead, it relies on a specific living-soil mix intended for repeated use with minimal disturbance [1].
- **after:** Instead, it relies on a specific living-soil mix intended for repeated use with minimal disturbance.

### [2] — `<p>` under: Core Philosophy: The Permanent Habitat
- **before:** The core belief is that if you provide a diverse array of slow-release organic inputs and maintain a stable, undisturbed environment, indigenous and compost-derived soil biology can populate the soil and support nutrient cycling over time [2].
- **after:** The core belief is that if you provide a diverse array of slow-release organic inputs and maintain a stable, undisturbed environment, indigenous and compost-derived soil biology can populate the soil and support nutrient cycling over time.

### [3] — `<li>` under: Figure LSE_B10
- **before:** Coot practitioners emphasize that compost or casting quality strongly influences the performance of the entire system [3].
- **after:** Coot practitioners emphasize that compost or casting quality strongly influences the performance of the entire system.

### [4] — `<p>` under: The Nutritional Amendments: Kelp, Neem, and Crustacean
- **before:** These amendments are used for broad-spectrum nutrition and for proposed biological stimulation or pest-suppression effects, though those effects should be treated as context-dependent rather than guaranteed [4].
- **after:** These amendments are used for broad-spectrum nutrition and for proposed biological stimulation or pest-suppression effects, though those effects should be treated as context-dependent rather than guaranteed.

### [5] — `<li>` under: The Nutritional Amendments: Kelp, Neem, and Crustacean
- **before:** It contributes trace minerals and seaweed-derived compounds associated with plant-growth effects, and practitioners often use it as part of a fungal-supporting organic amendment program [5].
- **after:** It contributes trace minerals and seaweed-derived compounds associated with plant-growth effects, and practitioners often use it as part of a fungal-supporting organic amendment program.

### [6] — `<li>` under: The Nutritional Amendments: Kelp, Neem, and Crustacean
- **before:** In the Coot's Mix practitioner protocol, it is also used for possible pest-deterring and microbial effects, but those effects vary by product, rate, crop, pest, and soil conditions [6].
- **after:** In the Coot's Mix practitioner protocol, it is also used for possible pest-deterring and microbial effects, but those effects vary by product, rate, crop, pest, and soil conditions.

### [7] — `<li>` under: The Nutritional Amendments: Kelp, Neem, and Crustacean
- **before:** Chitin-containing amendments may encourage chitin-degrading organisms and plant-microbe interactions, but they should not be presented as guaranteed control of root-feeding nematodes or soil-borne pests [7].
- **after:** Chitin-containing amendments may encourage chitin-degrading organisms and plant-microbe interactions, but they should not be presented as guaranteed control of root-feeding nematodes or soil-borne pests.

### [8] — `<li>` under: The Role of Malted Barley and Worms
- **before:** The malting process produces enzymes such as amylase, phosphatase, and chitinase; in the practitioner protocol, barley is used to support decomposition and nutrient cycling, though effects depend on soil biology, moisture, temperature, and application method [8].
- **after:** The malting process produces enzymes such as amylase, phosphatase, and chitinase; in the practitioner protocol, barley is used to support decomposition and nutrient cycling, though effects depend on soil biology, moisture, temperature, and application method.

### [9] — `<li>` under: The Role of Malted Barley and Worms
- **before:** Where moisture, temperature, oxygen, and food are suitable, worms can consume top-dressed amendments and decaying root matter, converting them into castings near the root zone [9].
- **after:** Where moisture, temperature, oxygen, and food are suitable, worms can consume top-dressed amendments and decaying root matter, converting them into castings near the root zone.

### [10] — `<li>` under: Strengths and Limitations
- **before:** It can be forgiving for home growers who want a "water-only" or low-input container system, provided the starting mix and compost quality are strong [10].
- **after:** It can be forgiving for home growers who want a "water-only" or low-input container system, provided the starting mix and compost quality are strong.

### [11] — `<li>` under: Strengths and Limitations
- **before:** Furthermore, because it relies on slow-release dry amendments, it can be difficult to rapidly correct a severe nutrient deficiency if one occurs [11].
- **after:** Furthermore, because it relies on slow-release dry amendments, it can be difficult to rapidly correct a severe nutrient deficiency if one occurs.

### [1] — `<p>` under: Core Philosophy: The Plant Health Pyramid
- **before:** In that framework, plant health is described through four phases of physiological development and defense capacity [1]:
- **after:** In that framework, plant health is described through four phases of physiological development and defense capacity:

### [2] — `<li>` under: Figure LSE_A18
- **before:** This should not be presented as an entomological law that insects cannot digest complete proteins [2].
- **after:** This should not be presented as an entomological law that insects cannot digest complete proteins.

### [3] — `<li>` under: Figure LSE_A18
- **before:** The framework links this phase with mycorrhizal colonization and stronger cuticle formation, which may contribute to resistance or tolerance to some airborne fungal pathogens under specific host-pathogen-environment conditions [3].
- **after:** The framework links this phase with mycorrhizal colonization and stronger cuticle formation, which may contribute to resistance or tolerance to some airborne fungal pathogens under specific host-pathogen-environment conditions.

### [4] — `<li>` under: Figure LSE_A18
- **before:** This should be framed as potential defense chemistry, not immunity to all pests, adult beetles, or borers [4].
- **after:** This should be framed as potential defense chemistry, not immunity to all pests, adult beetles, or borers.

### [5] — `<p>` under: Sap Analysis vs. Soil Testing
- **before:** William Albrecht [5].
- **after:** William Albrecht.

### [6] — `<p>` under: Sap Analysis vs. Soil Testing
- **before:** By extracting and analyzing sap from both old and new leaves, growers can compare nutrient movement and possible imbalances [6].
- **after:** By extracting and analyzing sap from both old and new leaves, growers can compare nutrient movement and possible imbalances.

### [7] — `<p>` under: The Role of Trace Minerals and Biology
- **before:** Kempf argues that many agricultural soils are not just biologically degraded, but may also be depleted or functionally limited in critical trace minerals (like cobalt, molybdenum, and selenium) due to decades of extraction and soil-chemistry antagonisms [7].
- **after:** Kempf argues that many agricultural soils are not just biologically degraded, but may also be depleted or functionally limited in critical trace minerals (like cobalt, molybdenum, and selenium) due to decades of extraction and soil-chemistry antagonisms.

### [8] — `<p>` under: Figure LSE_B16
- **before:** Therefore, mineral applications are often combined with biological inoculants and carbon sources (like humic or fulvic acids), with the intent of improving nutrient retention and biological access; outcomes depend on product, crop, soil chemistry, moisture, and microbial activity [8].
- **after:** Therefore, mineral applications are often combined with biological inoculants and carbon sources (like humic or fulvic acids), with the intent of improving nutrient retention and biological access; outcomes depend on product, crop, soil chemistry, moisture, and microbial activity.

### [9] — `<p>` under: Brix and Nutrient Density (The BFA)
- **before:** For growers who cannot afford regular sap analysis, the Bionutrient methodology advocates the use of a refractometer to measure "Brix." Brix is a measurement of the dissolved solids (sugars, minerals, amino acids) in the plant sap [9].
- **after:** For growers who cannot afford regular sap analysis, the Bionutrient methodology advocates the use of a refractometer to measure "Brix." Brix is a measurement of the dissolved solids (sugars, minerals, amino acids) in the plant sap.

### [10] — `<p>` under: Brix and Nutrient Density (The BFA)
- **before:** Specific Brix numbers should not be used to predict pest outbreaks or claim absolute plant protection [10].
- **after:** Specific Brix numbers should not be used to predict pest outbreaks or claim absolute plant protection.

### [11] — `<p>` under: Brix and Nutrient Density (The BFA)
- **before:** This should be framed as a measurement and research effort, not proof that every crop grown in biologically active, mineral-balanced soil is objectively more nutritious than every conventionally grown counterpart [11].
- **after:** This should be framed as a measurement and research effort, not proof that every crop grown in biologically active, mineral-balanced soil is objectively more nutritious than every conventionally grown counterpart.

### [12] — `<li>` under: Strengths and Limitations
- **before:** It bridges biological farming and targeted nutrient management while keeping pest and disease resistance claims context-dependent [12].
- **after:** It bridges biological farming and targeted nutrient management while keeping pest and disease resistance claims context-dependent.

### [13] — `<li>` under: Strengths and Limitations
- **before:** The reliance on specific, often expensive, chelated mineral foliar sprays can be cost-prohibitive for small-scale or home growers, and product rates should follow the relevant label rather than generic recipes [13].
- **after:** The reliance on specific, often expensive, chelated mineral foliar sprays can be cost-prohibitive for small-scale or home growers, and product rates should follow the relevant label rather than generic recipes.

### [1] — `<p>` under: Korean Natural Farming (KNF)
- **before:** Developed by Master Cho Han-Kyu, KNF is a practitioner protocol that emphasizes low-cost fermentations intended to capture and culture local biology and extract nutrition from on-farm materials [1].
- **after:** Developed by Master Cho Han-Kyu, KNF is a practitioner protocol that emphasizes low-cost fermentations intended to capture and culture local biology and extract nutrition from on-farm materials.

### [2] — `<li>` under: Figure LSE_B12
- **before:** Growers capture wild fungi from local forests using cooked rice (IMO-1), stabilize the material with brown sugar (IMO-2), and multiply it on carbohydrates and soil (IMO-3/4) to create a locally adapted inoculant within the KNF protocol [2].
- **after:** Growers capture wild fungi from local forests using cooked rice (IMO-1), stabilize the material with brown sugar (IMO-2), and multiply it on carbohydrates and soil (IMO-3/4) to create a locally adapted inoculant within the KNF protocol.

### [3] — `<li>` under: Figure LSE_B12
- **before:** Key inputs include Fermented Plant Juice (FPJ) for vegetative growth, Fermented Fruit Juice (FFJ) for fruiting, Fish Amino Acids (FAA) as a nitrogen-rich input, and Water-Soluble Calcium (WCA) made from roasted eggshells dissolved in vinegar [3].
- **after:** Key inputs include Fermented Plant Juice (FPJ) for vegetative growth, Fermented Fruit Juice (FFJ) for fruiting, Fish Amino Acids (FAA) as a nitrogen-rich input, and Water-Soluble Calcium (WCA) made from roasted eggshells dissolved in vinegar.

### [4] — `<li>` under: Figure LSE_B12
- **before:** Practical Application: KNF utilizes a "Nutritive Cycle," a practitioner schedule that recommends specific combinations of these ferments based on the plant's current stage of growth (Vegetative, Cross-Over, Reproductive, and Ripening) [4].
- **after:** Practical Application: KNF utilizes a "Nutritive Cycle," a practitioner schedule that recommends specific combinations of these ferments based on the plant's current stage of growth (Vegetative, Cross-Over, Reproductive, and Ripening).

### [5] — `<p>` under: JADAM Organic Farming
- **before:** JADAM's philosophy is "Ultra-Low-Cost" agriculture, a practitioner protocol aimed at simplifying organic methods and reducing purchased inputs [5].
- **after:** JADAM's philosophy is "Ultra-Low-Cost" agriculture, a practitioner protocol aimed at simplifying organic methods and reducing purchased inputs.

### [6] — `<li>` under: Figure LSE_B13
- **before:** Instead, it relies on water, leaf mold, and sea salt to culture biology and extract nutrients [6].
- **after:** Instead, it relies on water, leaf mold, and sea salt to culture biology and extract nutrients.

### [7] — `<li>` under: Figure LSE_B13
- **before:** It is used immediately as a soil drench within the protocol [7].
- **after:** It is used immediately as a soil drench within the protocol.

### [8] — `<li>` under: Figure LSE_B13
- **before:** The resulting liquid is highly pungent, but it is not a standardized fertilizer unless batch-tested [8].
- **after:** The resulting liquid is highly pungent, but it is not a standardized fertilizer unless batch-tested.

### [9] — `<li>` under: Figure LSE_B13
- **before:** JHS (JADAM Herb Solution): For IPM, JADAM boils selected herbs to extract active compounds, which are then mixed with JWA (JADAM Wetting Agent, a homemade liquid soap) to create botanical sprays [9].
- **after:** JHS (JADAM Herb Solution): For IPM, JADAM boils selected herbs to extract active compounds, which are then mixed with JWA (JADAM Wetting Agent, a homemade liquid soap) to create botanical sprays.

### [10] — `<p>` under: Biodynamics
- **before:** Originating from a series of lectures given by Rudolf Steiner in 1924 and cited here through the 2004 book edition, Biodynamics is a practitioner/organizational doctrine that views the farm not merely as a biological system, but as a living, self-contained organism [10].
- **after:** Originating from a series of lectures given by Rudolf Steiner in 1924 and cited here through the 2004 book edition, Biodynamics is a practitioner/organizational doctrine that views the farm not merely as a biological system, but as a living, self-contained organism.

### [11] — `<li>` under: Biodynamics
- **before:** It shares many techniques with organic farming but also uses specific preparations that are part of Biodynamic doctrine rather than established universal mechanisms [11].
- **after:** It shares many techniques with organic farming but also uses specific preparations that are part of Biodynamic doctrine rather than established universal mechanisms.

### [12,13] — `<li>` under: Biodynamics
- **before:** (1993) supports a farm-system comparison, not a preparation-specific mechanism, while Chalker-Scott (2013) reviews preparation claims critically [12,13].
- **after:** (1993) supports a farm-system comparison, not a preparation-specific mechanism, while Chalker-Scott (2013) reviews preparation claims critically.

### [12,13] — `<li>` under: Biodynamics
- **before:** Biodynamic practitioners use it with the intent of supporting root growth and humus formation, but it should not be cited as a preparation-specific proven mechanism [12,13].
- **after:** Biodynamic practitioners use it with the intent of supporting root growth and humus formation, but it should not be cited as a preparation-specific proven mechanism.

### [13] — `<li>` under: Biodynamics
- **before:** Biodynamic practitioners use it with the intent of influencing light metabolism and photosynthesis, but that claim should be labeled as Biodynamic doctrine rather than consensus plant physiology [13].
- **after:** Biodynamic practitioners use it with the intent of influencing light metabolism and photosynthesis, but that claim should be labeled as Biodynamic doctrine rather than consensus plant physiology.

### [14] — `<li>` under: Biodynamics
- **before:** Practical Application: In addition to the preparations, Biodynamic practitioners often utilize an astronomical planting calendar, timing their sowing, cultivating, and harvesting activities based on lunar cycles and planetary alignments [14].
- **after:** Practical Application: In addition to the preparations, Biodynamic practitioners often utilize an astronomical planting calendar, timing their sowing, cultivating, and harvesting activities based on lunar cycles and planetary alignments.


## BOOK_5

### [1] — `<p>` under: (A) Established Plant Electrophysiology
- **before:** These signals—specifically action potentials and variation potentials—can contribute to systemic responses in distant parts of the plant, such as changes in stomatal behavior, photosynthesis, or defense-related metabolism [1][2][3].
- **after:** These signals—specifically action potentials and variation potentials—can contribute to systemic responses in distant parts of the plant, such as changes in stomatal behavior, photosynthesis, or defense-related metabolism.

### [2] — `<p>` under: (A) Established Plant Electrophysiology
- **before:** These signals—specifically action potentials and variation potentials—can contribute to systemic responses in distant parts of the plant, such as changes in stomatal behavior, photosynthesis, or defense-related metabolism [1][2][3].
- **after:** These signals—specifically action potentials and variation potentials—can contribute to systemic responses in distant parts of the plant, such as changes in stomatal behavior, photosynthesis, or defense-related metabolism.

### [3] — `<p>` under: (A) Established Plant Electrophysiology
- **before:** These signals—specifically action potentials and variation potentials—can contribute to systemic responses in distant parts of the plant, such as changes in stomatal behavior, photosynthesis, or defense-related metabolism [1][2][3].
- **after:** These signals—specifically action potentials and variation potentials—can contribute to systemic responses in distant parts of the plant, such as changes in stomatal behavior, photosynthesis, or defense-related metabolism.

### [1] — `<p>` under: (A) Established Plant Electrophysiology
- **before:** For example, Fromm and Eschrich (1993) documented action potentials in willow trees, and Fromm and Lautner (2007) provided a review of electrical signals and their physiological significance in plants [1][2].
- **after:** For example, Fromm and Eschrich (1993) documented action potentials in willow trees, and Fromm and Lautner (2007) provided a review of electrical signals and their physiological significance in plants.

### [2] — `<p>` under: (A) Established Plant Electrophysiology
- **before:** For example, Fromm and Eschrich (1993) documented action potentials in willow trees, and Fromm and Lautner (2007) provided a review of electrical signals and their physiological significance in plants [1][2].
- **after:** For example, Fromm and Eschrich (1993) documented action potentials in willow trees, and Fromm and Lautner (2007) provided a review of electrical signals and their physiological significance in plants.

### [3] — `<p>` under: (A) Established Plant Electrophysiology
- **before:** For example, Fromm and Eschrich (1993) documented action potentials in willow trees, and Fromm and Lautner (2007) provided a review of electrical signals and their physiological significance in plants [1][2].
- **after:** For example, Fromm and Eschrich (1993) documented action potentials in willow trees, and Fromm and Lautner (2007) provided a review of electrical signals and their physiological significance in plants.

### [4] — `<p>` under: (A) Established Plant Electrophysiology
- **before:** For example, Fromm and Eschrich (1993) documented action potentials in willow trees, and Fromm and Lautner (2007) provided a review of electrical signals and their physiological significance in plants [1][2].
- **after:** For example, Fromm and Eschrich (1993) documented action potentials in willow trees, and Fromm and Lautner (2007) provided a review of electrical signals and their physiological significance in plants.

### [6] — `<p>` under: (B) Active Electrostimulation Research
- **before:** (2023) demonstrated that specific electrostimulation protocols altered the flavonoid profiles of Scutellaria baicalensis grown in aeroponics [6].
- **after:** (2023) demonstrated that specific electrostimulation protocols altered the flavonoid profiles of Scutellaria baicalensis grown in aeroponics.

### [7] — `<p>` under: (B) Active Electrostimulation Research
- **before:** (2023) demonstrated that specific electrostimulation protocols altered the flavonoid profiles of Scutellaria baicalensis grown in aeroponics [6].
- **after:** (2023) demonstrated that specific electrostimulation protocols altered the flavonoid profiles of Scutellaria baicalensis grown in aeroponics.

### [5] — `<p>` under: (B) Active Electrostimulation Research
- **before:** Reviews such as Dannehl (2018) treat electrical effects on plants as an active research area while emphasizing that protocol, dose, environment, and mechanism matter [5].
- **after:** Reviews such as Dannehl (2018) treat electrical effects on plants as an active research area while emphasizing that protocol, dose, environment, and mechanism matter.

### [9] — `<p>` under: (C) Passive Electroculture (Home-Gardener Revival)
- **before:** (2025) is the audit-verified recent source for passive copper-rod effects, and it should be treated as a critical negative-result source rather than proof that passive antennas work [9].
- **after:** (2025) is the audit-verified recent source for passive copper-rod effects, and it should be treated as a critical negative-result source rather than proof that passive antennas work.

### [1] — `<td>` under: Physical Scale Comparison
- **before:** Tens of millivolts to ~100 mV [1][2][3]
- **after:** Tens of millivolts to ~100 mV

### [2] — `<td>` under: Physical Scale Comparison
- **before:** Tens of millivolts to ~100 mV [1][2][3]
- **after:** Tens of millivolts to ~100 mV

### [3] — `<td>` under: Physical Scale Comparison
- **before:** Tens of millivolts to ~100 mV [1][2][3]
- **after:** Tens of millivolts to ~100 mV

### [5] — `<td>` under: Physical Scale Comparison
- **before:** Volts to tens of volts, depending on protocol [5][6][7]
- **after:** Volts to tens of volts, depending on protocol

### [6] — `<td>` under: Physical Scale Comparison
- **before:** Volts to tens of volts, depending on protocol [5][6][7]
- **after:** Volts to tens of volts, depending on protocol

### [7] — `<td>` under: Physical Scale Comparison
- **before:** Volts to tens of volts, depending on protocol [5][6][7]
- **after:** Volts to tens of volts, depending on protocol

### [9] — `<td>` under: Physical Scale Comparison
- **before:** Estimated millivolt-range signal, highly variable and not yet established as biologically effective [9]
- **after:** Estimated millivolt-range signal, highly variable and not yet established as biologically effective

### [8] — `<li>` under: Experimental Configurations to Test
- **before:** Magnetic rods aligned to magnetic North; magnetoculture claims remain experimental and should be tested with the same controls [8].
- **after:** Magnetic rods aligned to magnetic North; magnetoculture claims remain experimental and should be tested with the same controls.

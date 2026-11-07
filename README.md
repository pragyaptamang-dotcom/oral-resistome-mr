# oral-resistome-mr

A learning project on **public data** that combines three small modules: Mendelian randomization (MR), shotgun metagenomics of the oral microbiome, and bacterial genome analysis (AMR and typing). It was built step by step to learn these methods, not to make new discoveries.

**Author:** Pragya Tamang (MSc)

## What is in this project

| Module | Question | Data (all public) | Main tools |
|---|---|---|---|
| 1. Mendelian randomization | Does genetically higher BMI or triglycerides affect periodontitis or dental caries? | OpenGWAS: BMI `ieu-b-40`, triglycerides `ieu-b-111`; FinnGen periodontitis and caries outcomes | R, TwoSampleMR, ieugwasr |
| 2. Oral shotgun metagenomics | How do the oral microbiome and resistance genes differ between healthy and periodontitis samples? | 8 public SRA runs (4 healthy, 4 periodontitis), BioProject listed in `data/raw/samples.csv` | fastp, MultiQC, MetaPhlAn, MEGAHIT, AMRFinderPlus (Galaxy), R (vegan) |
| 3. Bacterial isolate genomics | What are the sequence types and resistance genes of 9 *Klebsiella* isolates? | 9 public ENA isolate runs (Nepal and India) | Shovill, AMRFinderPlus, MLST, Prokka (Galaxy) |
| Database | Make all results searchable | Outputs of modules 1 and 2 | SQLite, SQL (`scripts/08_build_database.R`) |

The modules use **different public datasets**. They are not integrated and no link between the host genetics and the microbes is claimed.

## Results in brief

**Module 1: MR (IVW as the main method)**
- BMI to periodontitis: no evidence of an effect (OR about 1.03, p = 0.73).
- Triglycerides to periodontitis: no evidence (p = 0.92).
- Triglycerides to caries: no evidence (p = 0.27).
- BMI to caries: OR about 1.19 (1.03 to 1.38), p = 0.015. This is **suggestive only**. Other methods disagreed, the Egger intercept was borderline (p = 0.047), and it does not survive correction for 4 tests (about 0.0125).
- Checks run: Cochran's Q, MR-Egger intercept, leave-one-out, scatter and funnel plots.

**Module 2: Metagenomics**
- 4 vs 4 samples, so this is descriptive. Plots are in `results/figures/` (Shannon diversity, Bray-Curtis PCoA, top species, AMR presence).
- Statistical test results: TODO (add Wilcoxon and PERMANOVA values here).

**Module 3: Klebsiella isolates**
- 9 isolates: 8 *K. pneumoniae* and 1 *K. quasipneumoniae* (used as an outgroup). 4 from Nepal (including the outgroup) and 5 from India.
- **Sequence types (MLST):** ST14 (BA2138, BA12464), ST15 (2725), ST231 (BA13599), ST307 (BA13406), ST985 (BA1335). Isolate 1370 matched the ST14 allele profile at 6 of 7 loci, with an unassigned phoE allele, so no ST was called. Isolate 1379 has no reliable ST (see limitations). The outgroup 1429 has no ST because its alleles are novel for the *K. pneumoniae* scheme. The 8 isolates are therefore **not one clone**: at least 5 different sequence types.
- **Resistance genes (AMRFinderPlus):** 138 hits in total. The 8 *K. pneumoniae* isolates carried 14 to 21 hits each; the outgroup carried only 4 (intrinsic genes: fosA, oqxA/oqxB, blaOKP).
  - **Extended-spectrum beta-lactamase:** blaCTX-M-15 in 7 of the 8 *K. pneumoniae* isolates (6 exact; 1 partial CTX-M hit in BA13599). Not found in 1370.
  - **Carbapenemase genes:** blaOXA-232 in 3 isolates (BA13599, BA12464, 2725) and blaNDM-1 in 1 (2725, which also carried blaOXA-232).
  - **16S rRNA methyltransferases (high-level aminoglycoside resistance):** rmtC in 2725, rmtF1 in BA13599, and a partial rmtF hit in 2725.
  - **Plasmid-mediated quinolone resistance:** qnrB1 (3 isolates), qnrS1 (1), plus aac(6')-Ib-cr5 in several.
  - These are gene detections from draft assemblies. They show which resistance genes are present, not that the isolates are phenotypically resistant.
- Core-genome phylogeny: Roary (core gene alignment) followed by IQ-TREE (maximum likelihood, 1000 ultrafast bootstraps), run on Galaxy and drawn in R (`results/figures/kleb_tree.png`), rooted on the *K. quasipneumoniae* isolate. With 9 isolates this shows relatedness only and is not an outbreak or transmission analysis.

## Limitations (please read)

- **Small samples:** 4 vs 4 metagenomes and 9 isolates. Nothing here is statistically powered.
- **Most reads are human or unclassified** in the oral samples, so the microbial signal is limited.
- **AMR counts depend on assembly depth.** Fewer genes found does not mean fewer genes present.
- **Isolate 1379 (ERR3162531) has a very fragmented assembly** (contig numbering reaches about 4,000, against 37 to 372 for the others). The MLST tool picked an *E. coli* scheme for it with uncertain alleles, so that result is **not used**. Its position inside the *K. pneumoniae* group on the tree supports the species label, but its ST is unresolved and some of its AMR hits are partial.
- Species labels come from the public records' metadata and were not independently confirmed beyond the tree and MLST.
- **MR outcome data are European (Finnish).** Results may not apply to Indian populations. Case numbers are modest (about 3,046 periodontitis, 4,170 caries), so a null result is not proof of no effect.
- **Not yet done in MR:** instrument strength (F-statistics), checking exposure units, and confirming sample overlap in each source paper.
- The MR outcomes share the same FinnGen controls, so they are not fully independent.
- Public data only. No individual-level data. This is a learning and replication-style project.

## Reproducibility

- Local analysis: R scripts in `scripts/`, conda environment in `envs/environment.yml`.
- Read QC (fastp, MultiQC) was run locally in WSL2 Ubuntu with Conda/Bioconda.
- MetaPhlAn, MEGAHIT, AMRFinderPlus, Shovill, MLST and Prokka were run on **Galaxy** (a web platform), not on a local cluster.
- MetaPhlAn database: `mpa_vOct22`.
- Tool and database versions: TODO (read them from the info icon of each Galaxy job).

## Folder layout

```
data/raw/        small input tables (large downloads are git-ignored)
data/processed/
results/         tables, SQLite database, figures
scripts/         numbered R scripts
docs/            notes and concept explainers
envs/            conda environment
```

## How to run

Open the `.Rproj` file in RStudio first, so paths like `data/raw/...` resolve. Then run script 01 once (installs packages; adds your own OpenGWAS token to `.Renviron`, which is never uploaded). After that:

```r
source("scripts/run_all.R")   # runs scripts 02 to 08 in order
```

| Script | What it does |
|---|---|
| `01_setup_and_find_datasets.R` | install packages, connect to OpenGWAS, list candidate datasets |
| `02_mr_analysis.R` | two-sample MR: BMI and triglycerides to periodontitis and caries (needs internet and token) |
| `03_mr_checks_and_plots.R` | heterogeneity, Egger intercept, leave-one-out, scatter and funnel plots |
| `04_metaphlan_parse.R` | parse the combined MetaPhlAn output (Galaxy) to a species table |
| `05_diversity_and_plots.R` | Shannon, Bray-Curtis PCoA, PERMANOVA, top-species plot |
| `06_amr_parse.R` | parse AMRFinderPlus output for the oral samples, plot gene presence |
| `07_klebsiella_genomes.R` | MLST + AMR summary table and the core-gene trees for the 9 isolates |
| `08_build_database.R` | load results into SQLite and run 4 example SQL queries |

The Galaxy output tables must be saved in `data/raw/` first: `metaphlan_combined.tsv`, `amr_combined.tsv`, `kleb_amr.tsv`, `kleb_mlst.tsv`, `kleb_tree.nwk`.

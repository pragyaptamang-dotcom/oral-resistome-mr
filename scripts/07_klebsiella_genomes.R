# 07_klebsiella_genomes.R
# Goal: summarise the 9 Klebsiella isolates (MLST + AMR from Galaxy) and draw the core-gene tree.
# Run from the project folder (oral-resistome-mr). Inputs are in data/raw/:
#   kleb_amr.tsv   (AMRFinderPlus, collapsed over the 9 isolates, Galaxy)
#   kleb_mlst.tsv  (MLST, collapsed, Galaxy)
#   kleb_tree.nwk  (IQ-TREE maximum-likelihood tree built on the Roary core gene alignment, Galaxy)

library(tidyverse)
library(ape)

dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

# ---- 1. isolate key (run accession -> isolate name, species, country) ----
isolates <- data.frame(
  run = c("ERR3162530","ERR3162531","ERR3162548","ERR3162554","ERR3162558",
          "ERR3162560","ERR3162561","ERR3162573","ERR3162532"),
  isolate = c("1370","1379","2725","BA12464","BA1335","BA13406","BA13599","BA2138","1429"),
  species = c(rep("K. pneumoniae", 8), "K. quasipneumoniae"),
  country = c(rep("Nepal", 3), rep("India", 5), "Nepal")
)
write.csv(isolates, "data/raw/isolates.csv", row.names = FALSE)

# ---- 2. MLST ----
# Columns in the Galaxy file have no header: run, scheme, ST, then allele calls.
mlst <- read_tsv("data/raw/kleb_mlst.tsv", col_names = FALSE, show_col_types = FALSE) %>%
  transmute(run = X1, scheme = X2, ST = ifelse(X3 == "-", NA, X3))

# Isolate 1379 (ERR3162531): the tool picked an E. coli scheme on a very fragmented assembly.
# That call is not reliable, so we do not report an ST for it.
mlst <- mlst %>%
  mutate(ST = ifelse(run == "ERR3162531", NA, ST),
         ST_note = case_when(
           run == "ERR3162531" ~ "unreliable: fragmented assembly, wrong scheme picked",
           run == "ERR3162530" ~ "ST14-like profile, one unassigned allele (phoE)",
           run == "ERR3162532" ~ "outgroup: novel alleles",
           TRUE ~ ""))

# ---- 3. AMR ----
amr <- read_tsv("data/raw/kleb_amr.tsv", show_col_types = FALSE) %>%
  rename(run = Sample, gene = `Element symbol`, class = Class, type = Type, method = Method)

hits_per_isolate <- amr %>% count(run, name = "n_hits")

key_genes <- amr %>%
  filter(grepl("^blaCTX-M|^blaOXA-232|^blaNDM|^rmt", gene)) %>%
  group_by(run) %>%
  summarise(key_genes = paste(sort(unique(gene)), collapse = "; "), .groups = "drop")

summary_table <- isolates %>%
  left_join(mlst, by = "run") %>%
  left_join(hits_per_isolate, by = "run") %>%
  left_join(key_genes, by = "run") %>%
  select(run, isolate, species, country, ST, ST_note, n_hits, key_genes)

print(summary_table)
write_csv(summary_table, "results/kleb_summary.csv")

# ---- 4. Tree ----
tr <- read.tree("data/raw/kleb_tree.nwk")
stopifnot(all(tr$tip.label %in% isolates$run))   # every tip must be in our key

tr <- root(tr, outgroup = "ERR3162532", resolve.root = TRUE)   # root on K. quasipneumoniae
tr$tip.label <- paste0(isolates$isolate[match(tr$tip.label, isolates$run)],
                       " (", isolates$country[match(tr$tip.label, isolates$run)], ")")

png("results/figures/kleb_tree.png", width = 1000, height = 700, res = 120)
plot(tr, cex = 0.9)
axisPhylo()
title("Klebsiella isolates: core-gene maximum-likelihood tree")
dev.off()

# Zoomed tree without the outgroup, with bootstrap values at the nodes
tr8 <- drop.tip(tr, grep("^1429", tr$tip.label, value = TRUE))
png("results/figures/kleb_tree_zoom.png", width = 1000, height = 700, res = 120)
plot(tr8, cex = 0.9)
axisPhylo()
if (!is.null(tr8$node.label)) nodelabels(tr8$node.label, cex = 0.6, frame = "none", adj = c(1.2, -0.4))
title("K. pneumoniae isolates only (outgroup removed)")
dev.off()

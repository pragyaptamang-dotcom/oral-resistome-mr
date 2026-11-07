# 06_amr_parse.R
# Read the combined AMRFinderPlus output for the 8 oral metagenome assemblies (Galaxy),
# keep AMR-type hits, attach sample names and groups, and plot gene presence.
# Input : data/raw/amr_combined.tsv, data/raw/samples.csv
# Output: results/amr_hits.csv, results/figures/amr_presence.png
# Run from the project folder.

library(tidyverse)
dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

smp <- read_csv("data/raw/samples.csv", show_col_types = FALSE)

amr <- read_tsv("data/raw/amr_combined.tsv", show_col_types = FALSE) %>%
  rename(run = Sample, contig = `Contig id`, gene = `Element symbol`,
         gene_name = `Element name`, type = Type, class = Class, subclass = Subclass,
         method = Method, coverage = `% Coverage of reference`,
         identity = `% Identity to reference`) %>%
  filter(type == "AMR") %>%
  left_join(smp, by = "run")

# per-sample summary (strict = coverage and identity both at least 90%)
amr %>%
  group_by(sample_name, group) %>%
  summarise(hits = n(), genes = n_distinct(gene), classes = n_distinct(class),
            strict_hits = sum(coverage >= 90 & identity >= 90), .groups = "drop") %>%
  print()

# which drug classes, per group
amr %>% distinct(sample_name, group, gene, class) %>%
  count(group, class) %>% arrange(group, desc(n)) %>% print(n = 30)

write_csv(amr, "results/amr_hits.csv")

p <- amr %>% distinct(sample_name, group, gene) %>%
  ggplot(aes(sample_name, gene, fill = group)) + geom_tile(colour = "white") +
  facet_grid(. ~ group, scales = "free_x", space = "free_x") +
  labs(x = NULL, y = NULL) + theme_minimal() + theme(legend.position = "none")
ggsave("results/figures/amr_presence.png", p, width = 8, height = 9, dpi = 150)

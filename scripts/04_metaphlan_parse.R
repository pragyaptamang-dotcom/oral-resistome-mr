# 04_metaphlan_parse.R
# Read the combined MetaPhlAn output (from Galaxy) and keep species-level rows per sample.
# Input : data/raw/metaphlan_combined.tsv
# Output: data/raw/samples.csv, results/metaphlan_species.csv
# Run from the project folder.

library(tidyverse)
dir.create("results", showWarnings = FALSE)

# ---- sample key: SRA run -> sample name and group ----
samples <- data.frame(
  run = c("SRR31350389","SRR31350392","SRR31350396","SRR31350390",
          "SRR31350378","SRR31350385","SRR31350379","SRR31350381"),
  sample_name = c("PEHE064","PEHE057","PEHE009","PEHE060",
                  "PEPE109","PEPE027","PEPE107","PEPE104"),
  group = c(rep("healthy", 4), rep("periodontitis", 4))
)
write.csv(samples, "data/raw/samples.csv", row.names = FALSE)

# ---- parse: each sample's block starts with a line beginning with its SRR number ----
x <- readLines("data/raw/metaphlan_combined.tsv")
starts <- grep("^SRR[0-9]+\t", x)
print(length(starts))                      # should print 8
runs <- sub("\t.*", "", x[starts])
print(runs)

dat <- tibble(line = x, block = findInterval(seq_along(x), starts)) %>%
  filter(block > 0) %>%
  mutate(line = sub("^SRR[0-9]+\t", "", line)) %>%
  filter(str_detect(line, "^(UNCLASSIFIED|k__)")) %>%
  separate(line, c("clade", "ncbi", "rel_ab", "extra"), sep = "\t", fill = "right") %>%
  mutate(rel_ab = as.numeric(rel_ab), run = runs[block])

# species-level rows only (drop strain-level "t__" rows)
species <- dat %>%
  filter(str_detect(clade, "\\|s__"), !str_detect(clade, "\\|t__")) %>%
  mutate(species = sub(".*\\|s__", "", clade)) %>%
  left_join(samples, by = "run") %>%
  select(run, sample_name, group, species, rel_ab)

species %>%
  group_by(sample_name, group) %>%
  summarise(n_species = n(), total_pct = round(sum(rel_ab), 1), .groups = "drop") %>%
  print()

write_csv(species, "results/metaphlan_species.csv")

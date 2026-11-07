# 05_diversity_and_plots.R
# Alpha diversity (Shannon), beta diversity (Bray-Curtis, PCoA, PERMANOVA) and top-species plot.
# Input : results/metaphlan_species.csv (from script 04)
# Output: results/figures/{alpha_shannon,beta_pcoa,top_species}.png, results/diversity_tests.txt
# Only 4 vs 4 samples: treat the tests as descriptive. Run from the project folder.

library(tidyverse)
if (!requireNamespace("vegan", quietly = TRUE)) install.packages("vegan")
library(vegan)
dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

species <- read_csv("results/metaphlan_species.csv", show_col_types = FALSE)

# rescale so each sample's classified species add to 100%
sp <- species %>%
  group_by(sample_name) %>%
  mutate(rel = rel_ab / sum(rel_ab) * 100) %>%
  ungroup()

meta <- distinct(species, sample_name, group)
mat <- sp %>%
  select(sample_name, species, rel) %>%
  pivot_wider(names_from = species, values_from = rel, values_fill = 0) %>%
  column_to_rownames("sample_name")
meta <- meta[match(rownames(mat), meta$sample_name), ]

# ---- alpha diversity (within each sample) ----
alpha <- tibble(sample_name = rownames(mat),
                shannon  = diversity(mat, index = "shannon"),
                richness = specnumber(mat)) %>%
  left_join(meta, by = "sample_name")
print(alpha)
wil <- wilcox.test(shannon ~ group, data = alpha)
print(wil)

p1 <- ggplot(alpha, aes(group, shannon, colour = group)) +
  geom_boxplot(outlier.shape = NA) + geom_jitter(width = 0.08, size = 3) +
  labs(x = NULL, y = "Shannon diversity") + theme_minimal() + theme(legend.position = "none")
ggsave("results/figures/alpha_shannon.png", p1, width = 5, height = 4, dpi = 150)

# ---- beta diversity (between samples) ----
bray <- vegdist(mat, method = "bray")
perm <- adonis2(bray ~ group, data = meta, permutations = 999)
print(perm)

pc <- cmdscale(bray, k = 2)
pc_df <- tibble(sample_name = rownames(pc), PC1 = pc[, 1], PC2 = pc[, 2]) %>%
  left_join(meta, by = "sample_name")
p2 <- ggplot(pc_df, aes(PC1, PC2, colour = group, label = sample_name)) +
  geom_point(size = 3) + geom_text(vjust = -1, size = 3) + theme_minimal()
ggsave("results/figures/beta_pcoa.png", p2, width = 6, height = 5, dpi = 150)

# save the test results as text so they can be quoted in the README
capture.output(print(alpha), print(wil), print(perm),
               file = "results/diversity_tests.txt")

# ---- top 10 species ----
top <- sp %>% group_by(species) %>% summarise(m = mean(rel)) %>%
  slice_max(m, n = 10) %>% pull(species)
p3 <- sp %>%
  mutate(species = if_else(species %in% top, species, "Other")) %>%
  group_by(sample_name, group, species) %>% summarise(rel = sum(rel), .groups = "drop") %>%
  ggplot(aes(sample_name, rel, fill = species)) + geom_col() +
  facet_wrap(~group, scales = "free_x") +
  labs(x = NULL, y = "% of classified bacteria") + theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("results/figures/top_species.png", p3, width = 9, height = 5, dpi = 150)

# P. gingivalis check
sp %>% filter(species == "Porphyromonas_gingivalis") %>%
  select(sample_name, group, rel_ab, rel) %>% arrange(desc(rel)) %>% as.data.frame()

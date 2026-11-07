# 08_build_database.R
# Goal: put our pipeline results into ONE searchable SQLite database file,
# then run a few example queries. Run from the project folder (oral-resistome-mr).

if (!requireNamespace("RSQLite", quietly = TRUE)) install.packages(c("DBI", "RSQLite"))
library(DBI); library(RSQLite); library(tidyverse)

# ---- read the result files we already made ----
saved      <- readRDS("results/mr_objects.rds")
samples    <- read_csv("data/raw/samples.csv", show_col_types = FALSE) %>% rename(group_name = group)
species    <- read_csv("results/metaphlan_species.csv", show_col_types = FALSE) %>% rename(group_name = group)
mr_results <- read_csv("results/mr_main_results.csv", show_col_types = FALSE) %>%
  rename_with(~ gsub("\\.", "_", .x))
instruments <- bind_rows(saved$exp_bmi, saved$exp_tg) %>%
  select(any_of(c("SNP", "id.exposure", "beta.exposure", "se.exposure",
                  "pval.exposure", "effect_allele.exposure", "other_allele.exposure"))) %>%
  rename_with(~ gsub("\\.", "_", .x))
amr_hits <- read_csv("results/amr_hits.csv", show_col_types = FALSE) %>%
  select(run, sample_name, group_name = group, contig, gene, gene_name,
         class, subclass, method, coverage, identity)

# ---- write them into the database file ----
con <- dbConnect(SQLite(), "results/oral_resistome.sqlite")
dbWriteTable(con, "samples", samples, overwrite = TRUE)
dbWriteTable(con, "taxa_abundance", species, overwrite = TRUE)
dbWriteTable(con, "amr_hits", amr_hits, overwrite = TRUE)
dbWriteTable(con, "mr_results", mr_results, overwrite = TRUE)
dbWriteTable(con, "mr_instruments", instruments, overwrite = TRUE)
print(dbListTables(con))

# ---- Query 1: top 10 species in periodontitis samples ----
print(dbGetQuery(con, "SELECT species, ROUND(AVG(rel_ab),2) AS mean_pct, COUNT(*) AS n_samples
  FROM taxa_abundance WHERE group_name = 'periodontitis'
  GROUP BY species ORDER BY mean_pct DESC LIMIT 10"))

# ---- Query 2: resistance gene classes per group ----
print(dbGetQuery(con, "SELECT group_name, class, COUNT(DISTINCT gene) AS n_genes
  FROM amr_hits GROUP BY group_name, class ORDER BY group_name, n_genes DESC"))

# ---- Query 3: MR results with p < 0.05 ----
print(dbGetQuery(con, "SELECT id_exposure, id_outcome, method, nsnp, ROUND(b,3) AS b, ROUND(pval,4) AS pval
  FROM mr_results WHERE pval < 0.05 ORDER BY pval"))

# ---- Query 4: join across tables ----
# P. gingivalis abundance vs number of resistance genes per sample
# (only samples where P. gingivalis was detected appear)
print(dbGetQuery(con, "SELECT t.sample_name, t.group_name, ROUND(t.rel_ab,2) AS gingivalis_pct,
  COUNT(DISTINCT a.gene) AS amr_genes
  FROM taxa_abundance t JOIN amr_hits a ON a.sample_name = t.sample_name
  WHERE t.species = 'Porphyromonas_gingivalis' GROUP BY t.sample_name"))

dbDisconnect(con)

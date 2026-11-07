# 03_mr_checks_and_plots.R
# Sensitivity checks for the four MR analyses: heterogeneity (Cochran's Q),
# MR-Egger intercept (pleiotropy), leave-one-out, scatter and funnel plots.
# Needs results/mr_objects.rds from script 02. Run from the project folder.

library(TwoSampleMR)
library(tidyverse)
dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

saved <- readRDS("results/mr_objects.rds")
list2env(saved, envir = globalenv())

dats <- list(
  perio_bmi  = dat_perio_bmi,
  perio_tg   = r_perio_tg$dat,
  caries_bmi = r_caries_bmi$dat,
  caries_tg  = r_caries_tg$dat
)

# ---- heterogeneity: do the variants agree with each other? ----
het <- bind_rows(lapply(names(dats), function(n)
  mutate(mr_heterogeneity(dats[[n]]), analysis = n)))
het_out <- het %>% select(analysis, method, Q, Q_df, Q_pval)
print(as.data.frame(het_out))
write_csv(het_out, "results/mr_heterogeneity.csv")

# ---- pleiotropy: MR-Egger intercept ----
ple <- bind_rows(lapply(names(dats), function(n)
  mutate(mr_pleiotropy_test(dats[[n]]), analysis = n)))
ple_out <- ple %>% select(analysis, egger_intercept, se, pval)
print(as.data.frame(ple_out))
write_csv(ple_out, "results/mr_pleiotropy.csv")

# ---- scatter and funnel plots ----
for (n in names(dats)) {
  d <- dats[[n]]
  res <- mr(d)
  ggsave(paste0("results/figures/", n, "_scatter.png"),
         mr_scatter_plot(res, d)[[1]], width = 7, height = 6, dpi = 150)
  ggsave(paste0("results/figures/", n, "_funnel.png"),
         mr_funnel_plot(mr_singlesnp(d))[[1]], width = 7, height = 6, dpi = 150)
}

# ---- leave-one-out: does one variant carry the result? ----
loo_summary <- bind_rows(lapply(names(dats), function(n) {
  l <- mr_leaveoneout(dats[[n]]) %>% filter(SNP != "All")
  tibble(analysis = n, min_b = min(l$b), max_b = max(l$b),
         min_p = min(l$p), max_p = max(l$p))
}))
print(as.data.frame(loo_summary))
write_csv(loo_summary, "results/mr_leaveoneout_summary.csv")

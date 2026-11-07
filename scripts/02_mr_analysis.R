# 02_mr_analysis.R
# Two-sample Mendelian randomization:
#   exposures: BMI (ieu-b-40), triglycerides (ieu-b-111)
#   outcomes : periodontitis (finn-b-K11_PERIODON_CHRON), dental caries (finn-b-K11_CARIES), FinnGen
# Needs your OpenGWAS token in .Renviron (see script 01). Run from the project folder.

library(TwoSampleMR)
library(tidyverse)
dir.create("results", showWarnings = FALSE)

# ---- 1. instruments: strong (p < 5e-8), independent (clumped) variants ----
exp_bmi <- extract_instruments(outcomes = "ieu-b-40")    # 501 instruments in our run
exp_tg  <- extract_instruments(outcomes = "ieu-b-111")   # 313 instruments in our run
nrow(exp_bmi); nrow(exp_tg)

# ---- 2. for each exposure/outcome pair: look up outcome, harmonise, run MR ----
run_mr <- function(exp_dat, outcome_id) {
  out <- extract_outcome_data(snps = exp_dat$SNP, outcomes = outcome_id)
  dat <- harmonise_data(exp_dat, out)       # same effect allele in both studies
  res <- mr(dat)                            # IVW, MR-Egger, weighted median, modes
  list(dat = dat, res = res)
}

r_perio_bmi  <- run_mr(exp_bmi, "finn-b-K11_PERIODON_CHRON")
r_perio_tg   <- run_mr(exp_tg,  "finn-b-K11_PERIODON_CHRON")
r_caries_bmi <- run_mr(exp_bmi, "finn-b-K11_CARIES")
r_caries_tg  <- run_mr(exp_tg,  "finn-b-K11_CARIES")

# keep names used by later scripts
dat_perio_bmi <- r_perio_bmi$dat
res_perio_bmi <- r_perio_bmi$res
table(dat_perio_bmi$mr_keep)

# ---- 3. save results ----
all_res <- bind_rows(res_perio_bmi, r_perio_tg$res, r_caries_bmi$res, r_caries_tg$res) %>%
  select(id.exposure, id.outcome, method, nsnp, b, se, pval)
print(as.data.frame(all_res))
write_csv(all_res, "results/mr_main_results.csv")

saveRDS(list(exp_bmi = exp_bmi, exp_tg = exp_tg, dat_perio_bmi = dat_perio_bmi,
             r_perio_tg = r_perio_tg, r_caries_bmi = r_caries_bmi,
             r_caries_tg = r_caries_tg), "results/mr_objects.rds")

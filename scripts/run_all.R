# run_all.R
# Runs the whole local analysis in order. Run from the project folder (open the .Rproj first).
#
# Before this, you need once:
#   - script 01 (install packages, OpenGWAS token in .Renviron)
#   - the Galaxy output tables saved in data/raw/:
#       metaphlan_combined.tsv, amr_combined.tsv, kleb_amr.tsv, kleb_mlst.tsv, kleb_tree.nwk
# Script 02 needs internet and the OpenGWAS token.

steps <- c("scripts/02_mr_analysis.R",
           "scripts/03_mr_checks_and_plots.R",
           "scripts/04_metaphlan_parse.R",
           "scripts/05_diversity_and_plots.R",
           "scripts/06_amr_parse.R",
           "scripts/07_klebsiella_genomes.R",
           "scripts/08_build_database.R")

for (s in steps) {
  message("\n==== running ", s, " ====")
  source(s, echo = FALSE)
}
message("\nDone. Results are in results/ and results/figures/.")

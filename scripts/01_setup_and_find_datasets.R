# 01_setup_and_find_datasets.R
# Goal: install MR packages, connect to OpenGWAS, and list candidate datasets
# for our exposures (BMI, triglycerides) and outcomes (periodontitis, caries).
# Run this line by line in RStudio (Ctrl+Enter), not all at once, the first time.

# ---- Step 1: install packages (only needed once) ----
# 'remotes' lets R install packages straight from GitHub.
install.packages(c("remotes", "tidyverse"))

# TwoSampleMR is the main Mendelian randomization package.
# ieugwasr is the package that talks to the OpenGWAS database.
remotes::install_github("MRCIEU/TwoSampleMR")
remotes::install_github("MRCIEU/ieugwasr")

# ---- Step 2: add your OpenGWAS token ----
# 1. Register at https://api.opengwas.io and copy your token.
# 2. Run the next line. It opens a hidden settings file called .Renviron.
usethis::edit_r_environ()   # if this errors, run install.packages("usethis") first
# 3. In that file add ONE line (paste your own token after the =):
#      OPENGWAS_JWT=your_token_here
# 4. Save the file, then restart R: Session > Restart R.

# ---- Step 3: check the connection ----
library(TwoSampleMR)
library(ieugwasr)
library(tidyverse)

ieugwasr::user()   # should print your account details. If it errors, the token is the problem.

# ---- Step 4: list every dataset OpenGWAS offers ----
# Each row is one GWAS. We keep only the columns we need.
all_gwas <- ieugwasr::gwasinfo()

all_gwas_small <- all_gwas %>%
  select(id, trait, sample_size, population, consortium, year, author)

# ---- Step 5: search for the traits we care about ----
# grepl() checks whether a word appears in the trait name. ignore.case = TRUE ignores capitals.
find_trait <- function(word) {
  all_gwas_small %>%
    filter(grepl(word, trait, ignore.case = TRUE)) %>%
    arrange(desc(sample_size))
}

bmi          <- find_trait("body mass index")
triglyceride <- find_trait("triglycerid")
periodontitis <- find_trait("periodon")
caries       <- find_trait("caries")

# Look at each table in RStudio (click the name in the Environment panel).
# Questions to ask of each candidate:
#   - Is the sample size large?plot(tr8, cex = 0.9)

#   - Is the population European only? (most are, which is a limitation to report)
#   - Is the exposure study a DIFFERENT study from the outcome study? (avoids sample overlap)

# ---- Step 6: save the candidates so they are part of the project record ----
dir.create("results", showWarnings = FALSE)
bind_rows(
  mutate(bmi, group = "exposure: BMI"),
  mutate(triglyceride, group = "exposure: triglycerides"),
  mutate(periodontitis, group = "outcome: periodontitis"),
  mutate(caries, group = "outcome: caries")
) %>%
  write_csv("results/dataset_candidates.csv")

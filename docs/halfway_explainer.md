# Halfway explainer: what we did and why (Mendelian randomization)

Written for you to re-read. If a word here is still unclear, add it to `docs/notes.md` and ask.

---

## 1. The story in one paragraph

We asked: **does having a higher BMI or higher triglycerides cause gum disease (periodontitis) or tooth decay (caries)?**
Ordinary studies can't answer this, because people with high BMI also differ in diet, income, smoking, and so on. So we used **genes as a natural experiment**. Some genetic variants nudge BMI up a little. You are given your variants at conception, before lifestyle can affect them. If people who carry more BMI-raising variants also get more tooth decay, that points to BMI actually causing it. We did this using published summary numbers, not anyone's personal data.

---

## 2. Words you now know (with where you met them)

| Word | Plain meaning | Where you met it |
|---|---|---|
| **Variant / SNP** | One spot in the DNA where people differ by a single letter | the `rs...` names, like rs705217 |
| **GWAS** | A huge study that checks, for every variant, whether it is linked to a trait | what produced all our datasets |
| **Summary statistics** | The results table of a GWAS: one row per variant, with its effect and uncertainty. No personal data | what `extract_instruments` pulled |
| **Exposure** | The thing we think is the cause (BMI, triglycerides) | `ieu-b-40`, `ieu-b-111` |
| **Outcome** | The thing we think is affected (periodontitis, caries) | the two FinnGen datasets |
| **Instrument** | A variant strongly linked to the exposure. The variants are the natural experiment | 501 for BMI, 313 for triglycerides |
| **Independent (clumping)** | We keep only variants that are not inherited together, so they count as separate pieces of evidence | done automatically inside `extract_instruments` |
| **Effect allele** | The DNA letter that an effect is measured against | why we had to harmonise |
| **Harmonising** | Making sure both studies measure a variant against the same letter. Without this, effects could point in opposite directions | Step 17 |
| **Palindromic variant** | A variant whose two letters pair up on opposite strands (A/T, G/C), so you can't tell which strand a study used. Dropped when ambiguous | the 18 variants removed |
| **beta (b)** | The estimated effect. For a yes/no disease it is on the **log-odds** scale | the `b` column |
| **Odds ratio (OR)** | exp(b). OR above 1 means higher risk, 1 means no effect | we converted by hand |
| **p-value** | How surprising the result would be if there were truly no effect. Small is surprising, but it is not the chance you are right | the `pval` column |
| **Confidence interval** | A range of effects that the data can't rule out. If it includes OR = 1, "no effect" is still possible | b ± 1.96 x se |

---

## 3. The three assumptions (the heart of MR)

An instrument is only valid if:

1. **Relevance:** the variant really does affect the exposure. We make sure of this by keeping only variants that pass a strict threshold (p < 5e-8).
2. **Independence:** the variant is not linked to confounders, like diet or income. Genes assigned at conception help, but this is not guaranteed (population structure can break it).
3. **Exclusion restriction:** the variant affects the outcome **only through** the exposure, with no side routes. A side route is called **pleiotropy**.

Assumption 3 is the hardest to prove, which is why we ran several methods and tests.

---

## 4. The methods (each makes a different bet about pleiotropy)

| Method | How it combines the 480 variants | Its bet |
|---|---|---|
| **IVW (inverse variance weighted)** | A weighted average. Most powerful (smallest uncertainty) | Assumes no pleiotropy, or that it balances out. **Our main method** |
| **MR-Egger** | A line fitted with a free intercept. The intercept detects a one-directional side route | Handles directional pleiotropy, but is much less precise |
| **Weighted median** | Takes the middle estimate, weighted | Still valid if up to half the instruments are bad |
| **Simple / weighted mode** | Takes the most common estimate | Still valid if the biggest group of variants is valid |

**Reading them together:** when all methods agree on direction and size, that is reassuring. When they disagree, be cautious.

---

## 5. The checks (Steps 22 and 23)

- **Heterogeneity (Cochran's Q):** do the variants agree with each other? Q close to its degrees of freedom (Q_df) means yes. Ours were all fine.
- **Egger intercept:** a non-zero intercept suggests directional pleiotropy. Two of ours were nominally flagged (triglycerides to periodontitis, p = 0.019; BMI to caries, p = 0.047).
- **Leave-one-out:** drop each variant in turn and re-run. If one variant is carrying the result, the estimate swings. Ours did not.
- **Multiple testing:** we ran 4 analyses, so a fair threshold is about 0.05 / 4 = 0.0125. Many tests means some small p-values appear by chance.

---

## 6. Our results in plain words

| Exposure | Outcome | Main result (IVW) | Verdict |
|---|---|---|---|
| BMI | Periodontitis | OR about 1.03, p = 0.73 | No evidence of an effect |
| Triglycerides | Periodontitis | p = 0.92 | No evidence of an effect |
| Triglycerides | Caries | p = 0.27 | No evidence of an effect |
| **BMI** | **Caries** | **OR about 1.19 (1.03 to 1.38), p = 0.015** | **Suggestive only** |

Why BMI to caries is "suggestive only" and not a finding:
- The other methods did not agree (Egger went the opposite way; weighted median and modes were weaker, with p from 0.18 to 0.91).
- The Egger intercept was borderline (p = 0.047).
- p = 0.015 does not survive correction for 4 tests.
- It *did* pass leave-one-out and heterogeneity.

**Honest one-line summary:** "We found no clear evidence that genetically higher BMI or triglycerides cause periodontitis; there was a suggestive positive association between BMI and caries that was not robust across methods and needs replication."

---

## 7. Limits you must state

- **Few cases** (3,046 periodontitis, 4,170 caries), so confidence intervals are wide. A null result is not proof of no effect.
- **European / Finnish outcome data.** Results may not transfer to Indian populations.
- **Public datasets only**, no individual-level data. This is a learning project and a replication-style analysis, not new discovery.
- **Not yet done:** instrument strength (F-statistics), checking that each dataset's units are per standard deviation, and confirming sample overlap in each source paper.
- The four outcomes share the same FinnGen controls, so they are not fully independent.

---

## 8. Interview answers you can now give

- **Why IVW as the main method?** It's the most statistically powerful when its assumptions hold, so it's the usual primary analysis. The others are sensitivity analyses, each relaxing a different assumption.
- **Why did you also run Egger?** To test for directional pleiotropy through its intercept, since pleiotropy is the main threat to MR.
- **What is a palindromic SNP and why drop it?** Its alleles pair up on opposite strands, so strand can't be resolved when frequencies are near 50%.
- **What would you do if the Egger intercept were strongly significant?** Treat IVW with caution, lean on the weighted median and mode, and look for outlier variants.
- **Why not UK Biobank for the outcome?** It overlaps with the exposure data, which biases estimates toward the observational association, and it has few caries cases.

---

## 9. Step-to-concept map (what each of your commands did)

| Step | Command | Concept |
|---|---|---|
| Find datasets | `gwasinfo()` | catalogue of available GWAS |
| Instruments | `extract_instruments()` | pick strong, independent variants |
| Look up outcome | `extract_outcome_data()` | get those variants' effect on the outcome |
| Align | `harmonise_data()` | same allele in both studies |
| Estimate | `mr()` | IVW, Egger, median, mode |
| Checks | `mr_heterogeneity()`, `mr_pleiotropy_test()`, `mr_leaveoneout()` | is the result trustworthy |
| Plots | `mr_scatter_plot()`, `mr_funnel_plot()` | visualise agreement and outliers |

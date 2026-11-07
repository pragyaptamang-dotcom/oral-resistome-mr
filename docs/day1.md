# Day 1: set up, first Linux commands, check the data exists

Goal for today: a working terminal, a GitHub repo, and proof that the datasets Arm B depends on are real.

## 1. Get a terminal (pick ONE)

- **Windows:** install WSL2 (open PowerShell as administrator, run `wsl --install`, restart, then open "Ubuntu").
- **Mac:** open the built-in Terminal app.
- **Anything else / easiest start:** a free GitHub Codespace (works in the browser, nothing to install).

## 2. Fifteen commands to learn today

Type each one and see what it does. Write a one-line note on each in `docs/notes.md`.

| Command | What it does |
|---|---|
| `pwd` | show where you are |
| `ls` / `ls -l` | list files |
| `cd folder` / `cd ..` | move into / out of a folder |
| `mkdir name` | make a folder |
| `touch file.txt` | make an empty file |
| `cp a b` / `mv a b` | copy / move or rename |
| `rm file` | delete (permanent, careful) |
| `cat file` / `head file` | show file contents |
| `wc -l file` | count lines |
| `grep word file` | find lines containing a word |
| `man command` or `command --help` | read the manual |

## 3. Install Conda and make the environment

1. Install Miniforge (a light Conda): https://github.com/conda-forge/miniforge
2. In the project folder run:
   ```
   conda env create -f envs/environment.yml
   conda activate oral-resistome
   ```

## 4. GitHub repo

Create an empty repo named `oral-resistome-mr`, then commit this folder. Add `data/raw/` to a `.gitignore` file so big downloads are not uploaded.

## 5. Data check (the most important step today)

1. Make a free OpenGWAS account and get an API token (search "OpenGWAS API token").
2. Confirm these exist and note their sample sizes and ancestry in the README table:
   - Periodontitis: `finn-b-K11_PERIODON_CHRON`
   - A BMI GWAS (GIANT or UK Biobank) and a triglyceride GWAS
3. For dental caries, look at the FinnGen listing and the GLIDE consortium summary statistics (University of Bristol data repository). The GLIDE download is very large (about 24.7 GB), so check whether OpenGWAS or a smaller file can be used instead.

**Warning:** at least one published MR study found that three GWAS Catalog files labelled periodontitis (GCST90018905/906/907) were not actually periodontitis after checking the source files. Always confirm a dataset against its source paper before using it.

## 6. End of day

- Repo exists with this structure.
- `docs/notes.md` has your command notes.
- README data table updated with what you found.
- Tell me what you got stuck on and send any error messages.

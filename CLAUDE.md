# CLAUDE.md

Repository-local instructions for the thermo-hec tutorial; the global `~/.claude/CLAUDE.md` also applies.
The repository is nested inside the thermo-hec project (`~/0-projects/2026-09-16-thermo-hec-wgs-rna-1`), whose `CLAUDE.md` and memory hold the project context; git commands there use `git -C thermo-hec-tutorial`.

## The two pages

 * Every `shell` code block of `tutorial.md` is a command a reader runs, in order, in the directory the first block creates.
   The parent project's `slurm/tutorial.sbatch` extracts those blocks and runs them verbatim on bacon as the test of the page, so a block that only illustrates something does not belong on that page.
 * A change inside a shell block is a command change: the page passes again only after a bacon run of a tarball of this repository at that commit (the parent's coordinator ships it).
   Text outside the shell blocks changes without a rerun.
 * `tutorial.sbatch`'s `READS` option replaces the line `wget -O metagenome/metagenome-reads-10p.qza ...` literally, so renaming that file means changing the script too.
 * `data-preparation.md` records how the hosted artifacts were made and is never extracted or run.
   Its single-pass cutadapt step has not been run (it needs the 16S demux artifact `c25c70e1-0209-4b88-bfec-db2f815808be`).

## Prose

 * The text of both pages was drafted by Claude; @gregcaporaso is rewriting it (from 2026-10-30).
   Sessions fix commands and proof-read; they change text only when asked.
 * The two `@gregcaporaso, reminder for the prose` HTML comments in `tutorial.md` are notes for that rewrite; the pages hold no other comments (history lives in git).
 * Emoji open a sentence of running text, about one per section, with the same emoji for the same thing on both pages (🧪 the 16S data, 🦠 the metagenome, 🌳 the tree, 🏷️ a taxonomic level, 🗂️ the metadata, 📊 a report, ⚠️ a caveat).
   Never in headings, whose anchors are link targets (GitHub and the Pages site would each drop the emoji and slug the rest differently), and never in shell blocks, which are commands.
 * Linked anchors: `data-preparation.md#reference`, `#amplicon-data`, `#metagenome-data` and `#sample-metadata`, and `tutorial.md#a-taxonomic-level-instead-of-genomes`; renaming one of those headings means updating its links.

## Where the numbers come from

 * The download table's md5s and UUIDs: the parent's `tutorial-data/README.md` for the study data and the two GTDB artifacts, the Zenodo record's file checksums for the SSU reference sequences, and SILVA's `.md5` file for the classifier.
 * The results sentences: @gregcaporaso's run of every command by hand on bacon on 2026-10-30 (QIIME 2 2026.10, q2-confluence 4177690, mosh-sylph 939a531), which matched bacon job 325.
   The 99% and 100% figures of the identity-threshold paragraph come from bacon job 318 (the parent's `analyses/genome-space/`), which the page does not run.
 * The `# run time estimate` comments: the per-command start times of bacon job 325 (2026-10-28).

## Layout

 * The tutorial directory holds `16S/`, `metagenome/`, `reference/`, `genome/` (the integration, the reports, and `genome/metagenome-containment-analysis/` for the optional taxon search), `genus/` and `cache/`; the collection keys `16S` and `metagenome` match the directories.
 * Hosted file names match the page's; `metagenome-reads-10p.qza` is the 10% read subset.
 * While the parent project's `coordination/README.md` lists a distribution session, it owns the site and repository files (`index.md`, `_config.yml`, `_includes/`, `README.md`, `LICENSE`, `CITATION.cff`).

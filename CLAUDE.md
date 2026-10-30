# CLAUDE.md

Repository-local instructions for the q2-confluence tutorial (`gregcaporaso/q2-confluence-tutorial`; `thermo-hec-tutorial` until 2026-10-30); the global `~/.claude/CLAUDE.md` also applies.
The repository is nested inside the thermo-hec project (`~/0-projects/2026-09-16-thermo-hec-wgs-rna-1`), whose `CLAUDE.md` and memory hold the project context; the checkout there is still the directory `thermo-hec-tutorial/` (the parent's `slurm/tutorial.sbatch`, `pull.sh` and `.gitignore` name it), so git commands there use `git -C thermo-hec-tutorial`.

## The pages

 * Every `shell` code block of `tutorial.md` is a command a reader runs, in order, in the directory the first block creates.
   The parent project's `slurm/tutorial.sbatch` extracts those blocks and runs them verbatim on bacon as the test of the page, so a block that only illustrates something does not belong on that page.
   A full run downloads about 25 GB (19 GB of it the sylph database) and took 31 min on a 16-core server (bacon job 327); its peak memory, summed over a command's processes, is 14 GB in `classify-sklearn` with 8 jobs and about 5 GB without it.
 * A change inside a shell block is a command change: the page passes again only after a bacon run of a tarball of this repository at that commit (the parent's coordinator ships it).
   Text outside the shell blocks changes without a rerun.
 * `tutorial.sbatch`'s `READS` option replaces the line `wget -O metagenome/metagenome-reads-10p.qza ...` literally, so renaming that file means changing the script too.
 * `install.md` holds the environment commands; nothing runs them except a person building the environment.
 * `data-preparation.md` records how the hosted artifacts were made and is never extracted or run.
   Its amplicon section describes the steps in prose and sends readers to the gut-to-soil tutorial for their own data, by @gregcaporaso's choice (2026-10-30): that tutorial is QIIME 2's standard amplicon walk-through, and this page should not keep a second, lesser version of it.
   The metagenome section keeps its commands, because there is no standard metagenome tutorial to point to yet.

## Prose

 * The text of the pages was drafted by Claude; @gregcaporaso is rewriting it (from 2026-10-30).
   Sessions fix commands and proof-read; they change text only when asked.
 * In @gregcaporaso's edits, `CLAUDE:` marks a request to Claude (do it and remove the note) and `GREG ...` marks their own place in a review (leave it).
   Text Claude drafts at their request carries a `** GREG TO REVIEW: ... **` line, which they remove once they have reviewed it (the Requirements section of `tutorial.md`, 2026-10-30).
   The `@gregcaporaso, reminder for the prose` HTML comment in `tutorial.md` is a note for the rewrite; the pages hold no other comments (history lives in git).
 * No emoji on the pages: @gregcaporaso tried them and dropped them (2026-10-30).
 * The first mention on each published page of a term in the [rachis glossary](https://news.rachis.org/en/latest/glossary/) links to its entry (`https://news.rachis.org/en/latest/glossary/#term-<slug>`, lowercase slugs; the site is built with mystmd); only mentions in the rachis sense, never in headings or code, and a first mention already linked elsewhere (rachis.org, qiime2.org, view.rachis.org) keeps its link.
   Ask @gregcaporaso before a linking pass over their prose, as the global `CLAUDE.md` says.
 * Linked anchors: `data-preparation.md#reference`, `#amplicon-data`, `#metagenome-data` and `#sample-metadata`, and `tutorial.md#workflow-limitations`; renaming one of those headings means updating its links.

## Where the numbers come from

 * The download table's md5s and UUIDs: the parent's `tutorial-data/README.md` for the study data and the two GTDB artifacts, the Zenodo record's file checksums for the SSU reference sequences, and SILVA's `.md5` file for the classifier.
 * The results sentences: @gregcaporaso's run of every command by hand on bacon on 2026-10-30 (QIIME 2 2026.10, q2-confluence 4177690, mosh-sylph 939a531), which matched bacon jobs 325 and 327 in every count and pseudo-F (the p-values are permutation estimates and vary by run).
 * The `# run time estimate` and `# peak memory estimate` comments and the Requirements section (whose finished-directory size of about 25 GB is from the parent's `bacon/_status/listing.txt`): bacon job 327 (2026-10-30, this repository at 8a0b25a), whose trace in the parent's `bacon/tutorial/tutorial-327.err` stamps each command's start and whose `tutorial-327-rss.tsv` samples the run's summed RSS every 2 s; a command's values span its start to the next command's.
   The summed RSS is an upper bound where workers share pages; commands that finish within the 2 s sampling interval (`tools peek`, `cache-create`, the first `make-report`) are written as `< 1 GB` without a sample.
   GNU time's maximum RSS in the job log (4.4 GB) is the largest single process and is not comparable.
 * The limitations section comes from the Limitations slide of the parent's deck (`figures/slides.yaml`).

## Layout

 * The tutorial directory holds `16S/`, `metagenome/`, `reference/`, `genome/` (the integration, the reports, and `genome/metagenome-containment-analysis/` for the optional taxon search), `genus/` and `cache/`.
 * The collection keys are `amplicon` and `metagenome`, so `amplicon:16S/...` differs from its directory: rachis-cli requires every collection key on the command line to be a Python identifier (letters, digits and underscores, no leading digit, no hyphen; `str.isidentifier()` in `rachis_cli/click/option.py`, `_split_and_validate_input_keys`), and `16S` is not one (bacon job 326 failed on it).
   The Artifact API has no such rule, so the plugins' tests do not catch it.
 * Hosted file names match the page's; `metagenome-reads-10p.qza` is the 10% read subset.
 * `README.md` stays minimal, modeled on q2-confluence's: title, alpha warning, one paragraph linking the site and the pages, the forum, and an AI disclosure dated as of its last update (keep it current).

## The site

 * GitHub Pages is to build the site at https://gregcaporaso.github.io/q2-confluence-tutorial/ from `main` (root folder, no workflow) with Jekyll and the Cayman theme; it is not enabled yet, and the steps to publish, with the decisions still open, are in the parent's `coordination/distribution.md`.
   `_config.yml` sets the theme and, as `description`, the notice shown under the title of every page; `_includes/head-custom.html` adds `<meta name="robots" content="noindex, nofollow">`.
 * `README.md` is the landing page, so readers see its alpha warning: there is no `index.md` (removed 2026-10-30 at @gregcaporaso's choice), and GitHub Pages' `jekyll-readme-index` renders the README as the index.
   Its "Read it at gregcaporaso.github.io/..." link then points at the page itself, which is harmless.
 * Pages are rendered without front matter, the first heading is the title, and links to `*.md` files become links to the rendered pages, so links work both on GitHub and on the site.
   `LICENSE`, `CITATION.cff` and `CLAUDE.md` are excluded.
 * The site stays unlisted until the data are published; only the two plugin READMEs link to it.
 * The tutorial session owns the whole repository, site files included, since the distribution session closed on 2026-10-30.

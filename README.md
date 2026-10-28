# thermo-hec tutorial

Source of the tutorial that integrates a 16S rRNA amplicon profile and a metagenome profile of the same samples in the feature space of one GTDB release's genomes, with the [q2-confluence](https://github.com/gregcaporaso/q2-confluence) and [mosh-sylph](https://github.com/gregcaporaso/mosh-sylph) QIIME 2 plugins.
The pages are plain Markdown with command-line commands; they will be published with GitHub Pages later.

## Layout

 * [`tutorial.md`](tutorial.md): the tutorial, what a reader runs on their own data.
   Every shell block is a command to run, in order, in the directory the first block creates.
 * [`data-preparation.md`](data-preparation.md): how the hosted tutorial data and the reference artifacts were prepared; a record, not run by readers.
 * `environment-files/thermo-hec-tutorial-extras.yml`: what the tutorial needs on top of the QIIME 2 2026.10 distribution (see below).

The pages were moved from the q2-confluence repository (`docs/` at commit 92f4995) on 2026-10-16 and rewritten as plain Markdown the same day, when the q2doc/MyST usage-example site was set aside.
Their prose is @gregcaporaso's; until they rewrite them, the two pages are Claude's drafts, as their header comments say.

## Create the environment

Install the QIIME 2 2026.10 distribution by following the instructions at [install.qiime2.org](https://install.qiime2.org); they create a conda environment named `rachis-qiime2-2026.10`.
Then add sylph and the two plugins to that environment with this repository's extras file:

```shell
wget https://raw.githubusercontent.com/gregcaporaso/thermo-hec-tutorial/main/environment-files/thermo-hec-tutorial-extras.yml

conda env update \
  -n rachis-qiime2-2026.10 \
  --file thermo-hec-tutorial-extras.yml

conda activate rachis-qiime2-2026.10

qiime dev refresh-cache
qiime confluence --help
qiime sylph --help
```

The plugin repositories are private at the time of writing, so the download and the pip installs in the extras file need GitHub credentials until they are made public.

## Testing the tutorial

The thermo-hec project's `slurm/tutorial.sbatch` extracts every shell block of `tutorial.md`, in order, and runs them verbatim on a server with both plugins installed, downloads included (about 25 GB, most of it the sylph database; 31 min and 4.4 GB peak memory on a 16-core server on 2026-10-21, half of it the sylph database download and the read sketching).
A change to a command on the page is tested there before it is committed as passing.

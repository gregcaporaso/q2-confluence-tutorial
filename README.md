# thermo-hec tutorial

Source of the tutorial that integrates a 16S rRNA amplicon profile and a shotgun metagenome profile of the same samples in the feature space of one GTDB release's genomes, with the [q2-confluence](https://github.com/gregcaporaso/q2-confluence) and [mosh-sylph](https://github.com/gregcaporaso/mosh-sylph) QIIME 2 plugins.
The pages are plain Markdown with command-line commands; they will be published with GitHub Pages later.

## Layout

 * [`tutorial.md`](tutorial.md): the tutorial, what a reader runs on their own data.
   Every shell block is a command to run, in order, in the directory the first block creates.
 * [`data-preparation.md`](data-preparation.md): how the hosted tutorial data and the reference artifacts were prepared; a record, not run by readers.
 * `environment-files/thermo-hec-tutorial-extras.yml`: what the tutorial needs on top of the qiime2 distribution's development environment (see below).

The pages were moved from the q2-confluence repository (`docs/` at commit 92f4995) on 2026-10-16 and rewritten as plain Markdown the same day, when the q2doc/MyST usage-example site was set aside.
Their prose is @gregcaporaso's; until they rewrite them, the two pages are Claude's drafts, as their header comments say.

## Create the environment

The plugins target the unreleased 2026.10 epoch, so the base environment is the `qiime2` distribution's development environment, created as in the [QIIME 2 development environment guide](https://develop.qiime2.org/en/stable/plugins/how-to-guides/set-up-development-environment.html) from the distribution's `dev/latest/passed` environment file for your platform; the extras file layers on sylph, and both plugins from GitHub at pinned commits.

Linux (x86_64):

```shell
conda env create -n thermo-hec-tutorial --file https://raw.githubusercontent.com/qiime2/distributions/dev/latest/passed/rachis-qiime2-linux-64-conda.yml
```

macOS on Apple Silicon (the distribution has no arm64 build; the osx-64 build runs under Rosetta):

```shell
CONDA_SUBDIR=osx-64 conda env create -n thermo-hec-tutorial --file https://raw.githubusercontent.com/qiime2/distributions/dev/latest/passed/rachis-qiime2-osx-64-conda.yml
conda activate thermo-hec-tutorial
conda config --env --set subdir osx-64
```

macOS on Intel uses the same osx-64 file without `CONDA_SUBDIR`.
Then, in the activated environment, from this directory:

```shell
conda env update -n thermo-hec-tutorial --file environment-files/thermo-hec-tutorial-extras.yml
qiime dev refresh-cache
qiime confluence --help
qiime sylph --help
```

The plugin repositories are private at the time of writing, so the pip installs in the extras file need GitHub credentials (a git credential helper on your machine) until they are made public.
The dev environment files are rebuilt as the distribution's packages change; recreate the environment every few weeks, as the guide suggests.

## Testing the tutorial

The thermo-hec project's `slurm/tutorial.sbatch` extracts every shell block of `tutorial.md`, in order, and runs them verbatim on a server with both plugins installed, downloads included (about 25 GB, most of it the sylph database; the SILVA classification is the memory peak).
A change to a command on the page is tested there before it is committed as passing.

## Pinned plugin commits

The extras file pins q2-confluence and mosh-sylph to the commits the page was written against.
A change to either plugin's command line means moving the pin and editing the page's commands.

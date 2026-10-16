# thermo-hec tutorial

Source of the tutorial that integrates a 16S rRNA amplicon profile and a shotgun metagenome profile of the same samples on one GTDB release, with the [q2-confluence](https://github.com/gregcaporaso/q2-confluence) and [mosh-sylph](https://github.com/gregcaporaso/mosh-sylph) QIIME 2 plugins.
The built site will be at https://thermo-hec-tutorial.readthedocs.io once the ReadTheDocs project exists.

The site is a MyST book built with [q2doc](https://github.com/qiime2/q2doc), in the layout of the [gut-to-soil tutorial](https://github.com/qiime2/gut-to-soil-tutorial).
The tutorial's commands are QIIME 2 usage examples (`describe-usage` blocks), rendered for every interface by q2doc.

## Layout

 * `docs/tutorial.md`: the tutorial, what a reader runs on their own data.
 * `docs/data-preparation.md`: how the hosted tutorial data and the reference artifacts were prepared; not run by readers.
 * `docs/intro.md`: placeholder for the introduction.
 * `docs/myst.yml`, `docs/q2doc-plug.py`: the MyST project and q2doc's directive plugin.
 * `environment-files/thermo-hec-tutorial-extras.yml`: what the site needs on top of the qiime2 distribution's development environment (see below).
 * `Makefile`, `.readthedocs.yaml`: the local and the ReadTheDocs builds.

The pages were moved from the q2-confluence repository (`docs/` at commit 92f4995) on 2026-10-16.
Their prose is @gregcaporaso's; until they rewrite them, the two pages are Claude's drafts, as their header comments say.

## Create the environment

The plugins target the unreleased 2026.10 epoch, so the base environment is the `qiime2` distribution's development environment, created as in the [QIIME 2 development environment guide](https://develop.qiime2.org/en/stable/plugins/how-to-guides/set-up-development-environment.html) from the distribution's `dev/latest/passed` environment file for your platform; the extras file layers on the documentation toolchain, sylph and sylph-tax, and both plugins from GitHub at pinned commits.

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
q2doc refresh-cache
qiime confluence --help
qiime sylph --help
```

The plugin repositories are private at the time of writing, so the pip installs in the extras file need GitHub credentials (a git credential helper on your machine; a token on ReadTheDocs) until they are made public.
The dev environment files are rebuilt as the distribution's packages change; recreate the environment every few weeks, as the guide suggests.

## Build the site

```shell
make preview
make serve
```

`make preview` renders every usage example for each interface without executing it; this is what ReadTheDocs builds (`.readthedocs.yaml`).
Known limitation (q2doc, reported 2026-10-16): q2doc renders every `init_artifact_from_url` and `init_metadata_from_url` input as a download from the site's own `data/` directory, which only an executed build fills, so in a preview build those download commands point at files the site does not have.
The tutorial's opening download section lists the real URLs until q2doc renders them itself.
`make html` executes the examples: it downloads about 30 GB and runs sylph, so it is the tutorial's test run rather than a routine build.
The thermo-hec project's `slurm/tutorial.sbatch` is the other test of the page: it renders the usage examples to command-line commands with the CLI usage driver and runs them on a server.

## Pinned plugin commits

The extras file pins q2-confluence and mosh-sylph to the commits the page was written against.
A change to either plugin's command line is picked up by moving the pin and re-rendering the page.

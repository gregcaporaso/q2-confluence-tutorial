# Integrating 16S and metagenome profiles: the tutorial

<!-- Draft by Claude, pending @gregcaporaso's rewrite (no prose of theirs yet).
Plain Markdown since 2026-10-16, when @gregcaporaso set the q2doc/MyST
usage-example site aside. Every ```shell block on this page is a command a
reader runs, in order, in the directory the first block creates; the
thermo-hec project's slurm/tutorial.sbatch extracts those blocks and runs
them verbatim as the test of the page. No block on this page is
documentation-only: how the hosted data was prepared is on
data-preparation.md, which is never run.
2026-10-21: the page moved from integration at a taxonomic level (genus and
family, bacon jobs 308 to 315) to integration in the feature space of GTDB
genomes, after the comparison in the thermo-hec project's
analyses/genome-space/ (bacon job 318): closed-reference clustering of the
ASVs against the GTDB SSU reference at 97% identity, sylph's genome table as
it is, the uncollapsed GTDB tree imported through GTDBNewickFormat, and no
sylph-tax step. 2026-10-23: integrate filters every source to the tips
of the tree itself (no Bacteria filters, no SSU taxonomy download), takes
no taxonomy and keys the metadata per source; GTDB's taxonomy artifact
serves every downstream action. 2026-10-30: the GTDB tree and taxonomy are
downloaded as artifacts hosted with the study data (made by @gregcaporaso's
run of this page on bacon); their import moved to data-preparation.md. The
md5s and UUIDs in the download table come from tutorial-data/README.md in
the parent project, from the Zenodo record's file checksums, from SILVA's
.md5 file and, for the two GTDB artifacts, from the uploaded files.
2026-10-30: @gregcaporaso ran every command of the page by hand on bacon in
the released QIIME 2 2026.10 with both plugins from GitHub main
(q2-confluence 4177690, mosh-sylph 939a531): every output present, every
md5 and UUID as in the table, every results sentence checked against that
run (the 99% and 100% figures of the threshold paragraph remain those of
bacon job 318, which the page does not run). -->

This tutorial integrates a 16S rRNA amplicon profile and a metagenome profile of the same samples in one feature space: the genomes of one GTDB release.
It uses the `confluence` plugin, the `sylph` plugin (mosh-sylph) for the metagenome profile, and stock QIIME 2 actions.
It covers what you run on your own data: mapping the amplicon features to GTDB genomes, profiling the metagenome reads against the same genomes, integrating both, and comparing the two profile types on the samples they share.
[How the tutorial data were prepared](data-preparation.md) is a separate page.
The commands assume an environment with both plugins installed ([README](README.md)).

<!-- @gregcaporaso, reminder for the prose: the choice of the 10% read subset was made at genus level (bacon job 308 versus jobs 300 to 307: weighted UniFrac pseudo-F 2.61 against 2.62, Bray-Curtis 3.21 against 3.20, while the presence-based metrics and the feature counts move because sylph detects fewer genomes at this depth); the genome-space numbers below are from the subset only (bacon job 318). -->

<!-- @gregcaporaso, reminder for the prose: explain why a reader's numbers differ slightly from the ones shown. The PERMANOVA p-values are permutation estimates and the random forest draws its folds and trees afresh each run, so p-values wobble in the third decimal and the accuracy by a sample or two; the pseudo-F values and the feature summary are deterministic. No random seed is set on purpose: copied commands would reuse it. -->

## Working directory

Create a directory for the tutorial and change into it; every file below is written there.
The amplicon, metagenome, reference and integration files get a subdirectory each, because QIIME 2 does not create the directory of an output.
The `# run time estimate` above each command is its wall time, rounded to minutes, in a run of this page on a 16-core Linux server with QIIME 2 2026.10 (2026-10-28).

```shell
mkdir confluence-tutorial
cd confluence-tutorial
mkdir 16S metagenome reference genome
```

## Downloading the data

Every file the tutorial uses: the study data (the sample metadata as an `ImmutableMetadata` artifact, the ASV table and sequences, the 10% subset of the metagenome reads, 4.8 GB) and the reference data: the GTDB r232 bacterial tree and genome taxonomy, imported from GTDB's files and hosted with the study data ([how](data-preparation.md#reference)), and, each from its publisher, the GTDB r232 16S reference sequences from the rachis Zenodo record (the data the GTDB classifier of that record was trained on) and the SILVA 144 V4 classifier from SILVA.
The sylph database is fetched by an action below, not by `wget`.

```shell
# run time estimate: 3 minutes for the downloads together, most of it the 4.8 GB reads (depends on the connection)
D='https://drive.usercontent.google.com/download?export=download&confirm=t&id='
wget -O sample-metadata.qza "${D}1PJQOCPLgOJ_Jeb-_ZmEN1enFzqLhbH5S"
wget -O 16S/asv-table.qza "${D}1-HH4892h693WAQ37YvrBjV_3P7xA3UgF"
wget -O 16S/asv-sequences.qza "${D}1LzOioUEnzP4nbOsV9v75VGaqfgseagbi"
wget -O metagenome/metagenome-reads-10p.qza "${D}1fkzsYoWAIeGOJDQrdqGcf5k5rNfoFR7E"
wget -O reference/gtdb-r232-bac120-tree.qza "${D}1CqKOWDfh0nfQW_eoBGkzEVFziUsnQoUE"
wget -O reference/gtdb-r232-bac120-taxonomy.qza "${D}11SsB4XNaVt7KiUy0w6jFW8PQnq3VLpM4"
wget -O reference/gtdb-r232-ssu-sequences.qza 'https://zenodo.org/records/21619532/files/gtdb-r232.0-2026.7.0-reference-sequences.qza?download=1'
wget -O reference/silva-144-v4-classifier.qza 'https://www.arb-silva.de/fileadmin/silva_databases/current/QIIME2/2026.7/SSU/V4-515f-806r/uniform/SILVA_144_SSURef_NR99_uniform_classifier_V4-515f-806r.qza'
md5sum sample-metadata.qza 16S/*.qza metagenome/*.qza reference/*
```

> [!NOTE]
> macOS has no `md5sum`; run `md5 -r` with the same arguments, which prints the sums in the same form.

The md5 sums should match the table; the UUID identifies each artifact in provenance (`qiime tools peek sample-metadata.qza 16S/*.qza metagenome/*.qza reference/*`).

| File | md5 | Artifact UUID |
|---|---|---|
| `sample-metadata.qza` | `8ed73161d2d70d9a9499d531401bd725` | `7d0ae7fb-1f89-4b1f-b475-ff6f0263d492` |
| `16S/asv-sequences.qza` | `a4173850ea0e9cc3220cede19cec6a30` | `ce58ed07-5639-49d0-acdd-37a56f5a4476` |
| `16S/asv-table.qza` | `c7313d6efe664c559104120d23291010` | `e02ea2d0-16a7-457b-8009-03ed2874216c` |
| `metagenome/metagenome-reads-10p.qza` | `884d47f6948d010356cde49594238b3f` | `09901ee0-9bca-4825-b94a-20c953d97cef` |
| `reference/gtdb-r232-bac120-taxonomy.qza` | `db35824401f6fcec75ba91f2be94f6a3` | `0c811883-42ef-430e-89c5-9f29f9e3a6ff` |
| `reference/gtdb-r232-bac120-tree.qza` | `302f40b1ff9bc872f01279a3a7a1dc2a` | `2ab4d0b8-967a-4c55-af04-863232a19fcf` |
| `reference/gtdb-r232-ssu-sequences.qza` | `c005d9db391cb78280eadb935ad8cfe5` | `622d4617-31dc-40ee-931b-810724b40fcc` |
| `reference/silva-144-v4-classifier.qza` | `683a71dcd81ce90d724add22d2ad4d0f` | `76237f8f-87e0-4d1e-93b9-970bb7603cf0` |

## Sample metadata

The sample metadata of the ten tutorial samples: bin location, sample type, composting time point and core temperature in °C (both empty for the two samples that were not composting, the fresh excrement and the soil), and the sample UUID.
It is provided as an `ImmutableMetadata` artifact, `sample-metadata.qza`, which any action that takes metadata accepts in place of a TSV.

```shell
# run time estimate: < 1 minute
qiime metadata tabulate \
  --m-input-file sample-metadata.qza \
  --o-visualization sample-metadata.qzv
```

> [!TIP]
> For your own data, import the sample metadata TSV into an `ImmutableMetadata` artifact once (the import command is on the [data preparation page](data-preparation.md#sample-metadata)) and pass the artifact everywhere the TSV would go.
> The artifact has a UUID, so provenance records which version of the metadata each result was made from; a TSV passed directly is recorded only by its contents.
> Either way, the metadata contents are written into the provenance of every downstream result, so a metadata file must not hold anything that cannot travel with the artifacts.
> Metadata in QIIME 2, including the artifact form, is described in the [metadata reference](https://use.qiime2.org/en/latest/references/metadata/).

## Reference data

Both profile types are placed on the genomes of GTDB r232: the amplicon features by closed-reference clustering against the 16S sequences of the GTDB species representatives, the metagenome reads by sylph against the same genomes.
GTDB's bacterial tree is the phylogeny, and GTDB's genome taxonomy names the genomes.
Both were imported from the files GTDB publishes into the two artifacts downloaded above; the commands are on the [data preparation page](data-preparation.md#reference), where they serve for another GTDB release with its file names.

The tree was imported through the `GTDBNewickFormat` import format of the `confluence` plugin: GTDB's tree ends in a quoted root label without a branch length (`'100:d__Bacteria'`), which UniFrac's parser cannot read, and the import drops that one label and changes nothing else.
The rooting of the tree is recorded on the artifact as a Note annotation, which every artifact derived from it carries along: GTDB places the root arbitrarily and advises treating its reference trees as unrooted.
`qiime tools annotation-fetch --input-path reference/gtdb-r232-bac120-tree.qza --name rooting --verbose` prints the note.

The metagenome reads are profiled with sylph through the `sylph` plugin (mosh-sylph), thin wrappers around sylph.
The sylph database of the GTDB r232 species representatives is about 20 GB, and every action that reads a `.qza` file unzips it first.
An [artifact cache](https://use.qiime2.org/en/stable/tutorials/use-the-artifact-cache/) keeps artifacts unzipped under a key, referenced as `cache:key` in place of a file path, so the large artifacts are written once and never zipped or unzipped again.
The commands below keep the database and the read sketches in a cache called `cache` inside the tutorial directory and pass `--use-cache cache` to the actions that write them; the tutorial's own data stays in `.qza` files, with its provenance.
`fetch-database` downloads the authors' pre-built database.

The plugin accepts only sylph's two-stage database format (`.syl2db`), which the sylph authors publish for GTDB r226 and r232; those are the releases `fetch-database` offers.
[GlobDB](https://globdb.org) publishes sylph databases for its r226 and r232 releases as well, but in the single-stage format so far; `fetch-database` will offer them when two-stage builds become available.
Until then, a GlobDB database can be used by downloading it, converting it with `sylph convert-db-two-screen`, and importing the result (`qiime tools import --type SylphTwoStageDatabase --input-format SylphTwoStageDatabaseFormat`); its genomes are not NCBI assemblies, so `profile-to-tables` below would run with `--p-no-gtdb-ids`, and the taxonomy and tree would be GlobDB's.
The [mosh-sylph README](https://github.com/gregcaporaso/mosh-sylph#types-and-formats) has the commands.

```shell
# run time estimate: < 1 minute
qiime tools cache-create --cache cache

# run time estimate: 9 minutes
qiime sylph fetch-database \
  --p-release 232 \
  --use-cache cache \
  --o-database cache:sylph-gtdb-r232
```

## Amplicon data

The amplicon side starts from the denoised ASV table and sequences of the ten samples ([how](data-preparation.md#amplicon-data)).
The SILVA classifier is used only to find organelle (mitochondria, chloroplasts) and other eukaryotic sequences, which the GTDB reference cannot name; they are removed with the SILVA taxonomy, and the ASV sequences are restricted to the features that remain, which closed-reference clustering requires.

```shell
# run time estimate: < 1 minute
qiime feature-classifier classify-sklearn \
  --i-classifier reference/silva-144-v4-classifier.qza \
  --i-reads 16S/asv-sequences.qza \
  --p-n-jobs 8 \
  --o-classification 16S/asv-taxonomy-silva.qza

# run time estimate: < 1 minute
qiime taxa filter-table \
  --i-table 16S/asv-table.qza \
  --i-taxonomy 16S/asv-taxonomy-silva.qza \
  --p-exclude f__Mitochondria,o__Chloroplast,d__Eukaryota \
  --p-mode contains \
  --o-filtered-table 16S/asv-table-noorganelles.qza

# run time estimate: < 1 minute
qiime feature-table filter-seqs \
  --i-data 16S/asv-sequences.qza \
  --i-table 16S/asv-table-noorganelles.qza \
  --o-filtered-data 16S/asv-sequences-noorganelles.qza
```

Closed-reference clustering maps every ASV to a GTDB genome: each ASV is searched against the 16S sequences of the species-representative genomes, and its counts go to the first reference at or above the identity threshold.
The clustered table is keyed by GTDB genome accessions (`RS_GCF_...`, `GB_GCA_...`), the same IDs as GTDB's tree and taxonomy and as the metagenome table below.
ASVs with no reference at the threshold are returned as the unmatched sequences and leave the analysis.

```shell
# run time estimate: < 1 minute
qiime vsearch cluster-features-closed-reference \
  --i-sequences 16S/asv-sequences-noorganelles.qza \
  --i-table 16S/asv-table-noorganelles.qza \
  --i-reference-sequences reference/gtdb-r232-ssu-sequences.qza \
  --p-perc-identity 0.97 \
  --p-threads 8 \
  --o-clustered-table 16S/genome-table.qza \
  --o-clustered-sequences 16S/genome-sequences.qza \
  --o-unmatched-sequences 16S/unmatched-asvs.qza

# run time estimate: < 1 minute
qiime feature-table summarize \
  --i-table 16S/genome-table.qza \
  --m-metadata-file sample-metadata.qza \
  --o-feature-frequencies 16S/genome-table-feature-frequencies.qza \
  --o-sample-frequencies 16S/genome-table-sample-frequencies.qza \
  --o-summary 16S/genome-table-summary.qzv
```

`feature-table summarize` shows how many reads and genomes each sample keeps after the mapping.

The identity threshold trades coverage for agreement.
On the tutorial data, 97% keeps 75% of the reads (54% of the ASVs, 3,611 genomes), 99% keeps 55% (31%, 2,483 genomes) and 100% keeps 42% (18%, 1,671 genomes); the stricter the threshold, the closer the two profile types come in the comparison below (weighted UniFrac PERMANOVA pseudo-F by profile type 1.7 at 97%, 1.2 at 99% and 100%), because only ASVs whose genome is in the reference remain, and those genomes are what the metagenome profile can see as well.
The tutorial uses 97% to keep more of the data; raise the threshold for a stricter comparison.

Two limitations of this mapping are worth knowing.
Only about half of the bacterial species representatives of GTDB r232 have a 16S sequence in the reference (88,481 of 189,801), so an ASV whose genome is among the rest can only land on a relative's genome, at a lower threshold.
And among references with identical V4 regions, vsearch returns the first one at or above the threshold rather than a best or a consensus hit (`cluster-features-closed-reference` does not expose vsearch's `maxaccepts`), so the particular genome an ASV lands on is arbitrary within such a group; the phylogenetic metrics below tolerate that, the presence-based ones do not.

The reference holds archaeal genomes too; `integrate` below drops them, because they are not tips of the bacterial tree, and records how many features each source lost.

## Metagenome data

The metagenome side starts from paired-end reads that are already trimmed, free of control samples and human reads, and subsampled to 10% ([how](data-preparation.md#metagenome-data)).
sylph sketches the reads once per sample; the sketches serve every profile or query against any database, so they go into the cache too.

```shell
# run time estimate: 4 minutes
qiime sylph sketch \
  --i-reads metagenome/metagenome-reads-10p.qza \
  --p-threads 16 \
  --use-cache cache \
  --o-sketches cache:sketches
```

`profile` runs sylph profile against the database; `--p-estimate-unknown` asks sylph to estimate, per sample, the share of reads from no genome in the database.
Reading `cache:` inputs needs no extra option; `--use-cache` above mattered only where an output was written into the cache, so that the action built it there instead of in the default temporary cache.
`profile-to-tables` turns the profile into QIIME 2 tables keyed by GTDB genome ID: the share of each detected genome corrected for genome size (the taxonomic abundance, the measure to integrate), the share of reads (the sequence abundance), and per-sample statistics (genomes detected, median ANI, unknown share).
No taxonomy step is needed: the genome IDs are those of GTDB's taxonomy and tree.

```shell
# run time estimate: 1 minute
qiime sylph profile \
  --i-sketches cache:sketches \
  --i-database cache:sylph-gtdb-r232 \
  --p-threads 16 \
  --p-estimate-unknown \
  --o-profile metagenome/sylph-profile.qza

# run time estimate: < 1 minute
qiime sylph profile-to-tables \
  --i-profile metagenome/sylph-profile.qza \
  --i-sketches cache:sketches \
  --o-taxonomic-abundance metagenome/sylph-taxonomic-abundance.qza \
  --o-sequence-abundance metagenome/sylph-sequence-abundance.qza \
  --o-stats metagenome/sylph-stats.qza
```

The per-sample statistics are metadata and tabulate like any other; the study metadata is given last, so its columns follow the statistics in the table.

```shell
# run time estimate: < 1 minute
qiime metadata tabulate \
  --m-input-file metagenome/sylph-stats.qza \
  --m-input-file sample-metadata.qza \
  --o-visualization metagenome/sylph-stats.qzv
```

The sylph database holds the archaeal representatives too; as on the amplicon side, `integrate` drops them.

## Integration

The two profiles enter as collections: each member is given as `key:path`, and the key names the profile type in every output.
`summarize-inputs` takes the inputs of `integrate` and shows, before anything is merged, which sample IDs the profiles and the metadata share and how many genomes of each profile are tips of the tree.

```shell
# run time estimate: < 1 minute
qiime confluence summarize-inputs \
  --i-tables 16S:16S/genome-table.qza metagenome:metagenome/sylph-taxonomic-abundance.qza \
  --i-tree reference/gtdb-r232-bac120-tree.qza \
  --i-metadata 16S:sample-metadata.qza metagenome:sample-metadata.qza \
  --o-visualization genome/inputs-summary.qzv
```

`integrate` keeps, in each profile, the genomes that are tips of the tree (`phylogeny filter-table`; the archaeal genomes go here), renormalizes the rest to proportions and merges the profiles.
Nothing is collapsed: the feature space is the genomes themselves, and a taxonomic level is a separate step ([last section](#a-taxonomic-level-instead-of-genomes)).
No taxonomy is built: GTDB's taxonomy artifact names every genome of the merged table and goes straight into the actions below.
Merged samples are named `<sample-id>-<key>`; the integrated metadata records `original-sample-id`, `study-id`, the source's `features-before` and `features-after` the tree filter and their quotient `features-kept-share`, beside the study metadata.
The metadata is given per profile type, under the table's key; one study profiled twice goes in under both keys.
A profile that loses more than a tenth of its features to the tree filter raises a warning naming the likely causes (archaea against the bacterial tree, or a reference release mismatch); the counts are in the metadata either way.
On the tutorial data the amplicon profile keeps 3,577 of its 3,611 genomes and the metagenome profile 1,313 of 1,322 (the nine archaea), so no warning is raised.

```shell
# run time estimate: < 1 minute
qiime confluence integrate \
  --i-tables 16S:16S/genome-table.qza metagenome:metagenome/sylph-taxonomic-abundance.qza \
  --i-tree reference/gtdb-r232-bac120-tree.qza \
  --i-metadata 16S:sample-metadata.qza metagenome:sample-metadata.qza \
  --o-integrated-table genome/relative-table.qza \
  --o-integrated-metadata genome/metadata.qza
```

The summaries so far are collected into one report, `genome/upstream-report.qzv`, with a tab for each; the paired report at the end does the same for the comparison.

```shell
# run time estimate: < 1 minute
qiime tools make-report \
  --report-path genome/upstream-report.qzv \
  16S/genome-table-summary.qzv \
  metagenome/sylph-stats.qzv \
  genome/inputs-summary.qzv
```

## Comparing the profile types without paired samples

Nothing up to this point needs paired samples.
`integrate` renames every sample of every profile type to `<sample-id>-<key>` whether or not the other type has a sample of the same ID, so two studies with no sample IDs in common integrate just the same, and `original-sample-id` keeps the input ID.
The merged relative table and the integrated metadata then go into any stock action that takes them: here weighted UniFrac distances between all merged samples, a PERMANOVA of the profile types on them, their ordination as a PCoA scatter plot coloured by profile type (the PCoA result is metadata, so it merges with the integrated metadata on the command line), and a taxa bar plot of the merged table, which GTDB's taxonomy lets you collapse to any rank and which can be sorted and coloured by the integrated metadata.

```shell
# run time estimate: < 1 minute
qiime diversity beta-phylogenetic \
  --i-table genome/relative-table.qza \
  --i-phylogeny reference/gtdb-r232-bac120-tree.qza \
  --p-metric weighted_unifrac \
  --o-distance-matrix genome/weighted-unifrac.qza

# run time estimate: < 1 minute
qiime diversity beta-group-significance \
  --i-distance-matrix genome/weighted-unifrac.qza \
  --m-metadata-file genome/metadata.qza \
  --m-metadata-column study-id \
  --o-visualization genome/weighted-unifrac-study-id.qzv

# run time estimate: < 1 minute
qiime diversity pcoa \
  --i-distance-matrix genome/weighted-unifrac.qza \
  --o-pcoa genome/weighted-unifrac-pcoa.qza

# run time estimate: < 1 minute
qiime vizard scatterplot-2d \
  --m-metadata-file genome/weighted-unifrac-pcoa.qza \
  --m-metadata-file genome/metadata.qza \
  --p-x-measure 'Axis 1' \
  --p-y-measure 'Axis 2' \
  --p-color-by study-id \
  --p-title 'Weighted UniFrac PCoA, GTDB genomes' \
  --o-visualization genome/weighted-unifrac-pcoa.qzv

# run time estimate: < 1 minute
qiime taxa barplot2 \
  --i-table genome/relative-table.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --m-metadata-file genome/metadata.qza \
  --o-visualization genome/taxa-barplot.qzv

# run time estimate: < 1 minute
qiime tools make-report \
  --report-path genome/downstream-report.qzv \
  genome/weighted-unifrac-study-id.qzv \
  genome/weighted-unifrac-pcoa.qzv \
  genome/taxa-barplot.qzv
```

`genome/downstream-report.qzv` collects the three visualizations of this section in one report.

The paired report below is what paired samples buy on top: it keeps only the samples both profile types cover, so the comparison is between two profiles of the same material rather than between two sets of samples.

## Paired-sample report

On the samples both profile types cover, `paired-report` computes Bray-Curtis and weighted UniFrac on the proportions as they are (no rarefaction, so no presence-based metric), with PERMANOVA by profile type and a PCoA scatter plot for each; a random forest classifying the profile type with nested cross-validation; and a per-feature summary, tabulated over every genome with its taxonomy beside it and also returned as metadata.

```shell
# run time estimate: 1 minute
qiime confluence paired-report \
  --i-table genome/relative-table.qza \
  --i-tree reference/gtdb-r232-bac120-tree.qza \
  --i-metadata genome/metadata.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --p-permutations 999 \
  --p-cv 10 \
  --p-n-estimators 500 \
  --p-n-jobs 8 \
  --o-report genome/paired-report.qzv \
  --o-distance-matrices genome/distance-matrices/ \
  --o-feature-importance genome/feature-importance.qza \
  --o-feature-summary genome/feature-summary.qza
```

On the tutorial data at 97%, weighted UniFrac does not separate the two profile types (PERMANOVA pseudo-F 1.7, p 0.13), while Bray-Curtis does, and the random forest tells them apart: restricted to the genomes the reference covers, the abundance-weighted phylogenetic profiles of the two assays agree, but the particular genomes each assay calls differ (the summary's `direction` column: 3,184 genomes seen by the amplicon profile only, 393 by both, 920 by the metagenome profile only, of which 590 have no 16S in the reference).

## A taxonomic level instead of genomes

The genome space is one choice of feature space; the same integrated data can be compared at a taxonomic level instead.
`taxa collapse` sums the merged table within each taxon of GTDB's taxonomy (level 6 is genus with the seven GTDB ranks, 5 family), and `gtdb-tree-collapse` collapses the imported GTDB tree to the same rank, with one tip per taxon named like the collapsed features, so the two still match; its log records which genomes each tip stands for.
The collapse takes about ten seconds on r232 and keeps GTDB's bootstrap and taxon labels on the remaining internal nodes.
The integrated metadata is unchanged, because collapsing touches features, not samples, and the collapsed feature IDs are the taxonomy strings themselves, so the report needs no taxonomy.
The paired report then runs as above, at genus.

```shell
mkdir genus

# run time estimate: < 1 minute
qiime taxa collapse \
  --i-table genome/relative-table.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table genus/relative-table.qza

# run time estimate: < 1 minute
qiime confluence gtdb-tree-collapse \
  --i-tree reference/gtdb-r232-bac120-tree.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --p-level 6 \
  --o-collapsed-tree genus/gtdb-r232-genus-tree.qza \
  --o-collapse-log genus/gtdb-r232-genus-tree-collapse-log.qza

# run time estimate: 1 minute
qiime confluence paired-report \
  --i-table genus/relative-table.qza \
  --i-tree genus/gtdb-r232-genus-tree.qza \
  --i-metadata genome/metadata.qza \
  --p-permutations 999 \
  --p-cv 10 \
  --p-n-estimators 500 \
  --p-n-jobs 8 \
  --o-report genus/paired-report.qzv \
  --o-distance-matrices genus/distance-matrices/ \
  --o-feature-importance genus/feature-importance.qza \
  --o-feature-summary genus/feature-summary.qza
```

On the tutorial data, collapsing the 97% genome table to genus gives 2,226 genera (1,483 seen by the amplicon profile only, 511 by both, 232 by the metagenome profile only) and the same picture as the genome space: weighted UniFrac does not separate the two profile types (PERMANOVA pseudo-F 1.6, p 0.18), while Bray-Curtis (3.0, p 0.002) does, and the random forest tells them apart (accuracy 0.9).
An earlier version of this tutorial integrated at genus level with the amplicon features named by a GTDB classifier rather than mapped to genomes; on that route the two profile types separated by weighted UniFrac as well (pseudo-F 2.6, p 0.01), so the difference lies in how the amplicon features reach the genus level, not in the level itself.

## Searching for a taxon (optional)

This optional step asks a different question of the same sketches: is a particular organism present, and how close is it to a reference genome?
`sylph profile` above reports abundances and assigns shared k-mers to one genome; `sylph query` instead reports, for every database genome with enough sampled k-mers in a sample, the coverage-adjusted average nucleotide identity (ANI) of the reads to that genome, so closely related genomes are all listed and nothing is reassigned.
`query-to-metadata` tabulates the result as metadata, joins GTDB's taxonomy by genome ID, and keeps only the rows whose taxonomy string or genome ID contains one of the given texts; `metadata tabulate` then shows the table.
Here the search is for *Escherichia coli*; the text matches every GTDB species cluster whose name starts with it (in r232 `s__Escherichia coli`, `s__Escherichia coli_E` and `s__Escherichia coli_F`), so narrow it to one cluster, or widen it to `g__Escherichia`, as the question requires.
At effective coverage below about 0.1x the adjusted ANI and its 5 to 95 percentile interval overshoot (the 95th percentile can exceed 100); read such rows with the containment index and the naive ANI.

```shell
mkdir genome/metagenome-containment-analysis

# run time estimate: 1 minute
qiime sylph query \
  --i-sketches cache:sketches \
  --i-database cache:sylph-gtdb-r232 \
  --p-threads 16 \
  --o-query genome/metagenome-containment-analysis/sylph-query.qza

# run time estimate: < 1 minute
qiime sylph query-to-metadata \
  --i-query genome/metagenome-containment-analysis/sylph-query.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --p-targets 's__Escherichia coli' \
  --o-query-metadata genome/metagenome-containment-analysis/escherichia-coli-query.qza

# run time estimate: < 1 minute
qiime metadata tabulate \
  --m-input-file genome/metagenome-containment-analysis/escherichia-coli-query.qza \
  --o-visualization genome/metagenome-containment-analysis/escherichia-coli-query.qzv
```

On the tutorial data the search returns six rows: the three *Escherichia coli* clusters of r232 (`s__Escherichia coli`, `coli_E` and `coli_F`), each found in the fresh excrement (1135D, adjusted ANI 94 to 98) and in the day-1 compost (DB47D, 94 to 99) at effective coverage of 0.06x to 0.18x, and in none of the eight later or soil samples: *E. coli* arrives with the feedstock and is gone from the compost by day 2.
`query-to-metadata` fails when no genome matches the targets, so a search for an organism that is absent from every sample stops here rather than tabulating an empty table.

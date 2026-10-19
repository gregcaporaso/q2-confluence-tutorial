# Integrating 16S and shotgun metagenome profiles: the tutorial

<!-- Draft by Claude, pending @gregcaporaso's rewrite (no prose of theirs yet).
Plain Markdown since 2026-10-16, when @gregcaporaso set the q2doc/MyST
usage-example site aside. Every ```shell block on this page is a command a
reader runs, in order, in the directory the first block creates; the
thermo-hec project's slurm/tutorial.sbatch extracts those blocks and runs
them verbatim as the test of the page. No block on this page is
documentation-only: how the hosted data was prepared is on
data-preparation.md, which is never run.
The commands are those of the shell-block page that passed on bacon as jobs
308 and 309 (q2-confluence docs/workflow.md at 3d9bed1), brought to the state
of the usage-example page they replace (bacon job 311): the 2026-10-16 Drive
upload with its md5 table, the hosted collapsed trees in place of the GTDB
download and gtdb-tree-collapse, the sample-metadata artifact in place of an
import, the metagenome profile through the sylph plugin (mosh-sylph), the
Bacteria filter on both sides, integrate's current outputs (profile-type
column), paired-report's four outputs, and a mkdir for every output
directory (q2cli does not create them). The md5s and UUIDs in the download
table come from tutorial-data/README.md in the parent project, from the
Zenodo record's file checksums and from SILVA's .md5 file. -->

This tutorial integrates a 16S rRNA amplicon profile and a shotgun metagenome profile of the same samples on one GTDB release, with the `confluence` plugin, the `sylph` plugin (mosh-sylph) for the metagenome profile, and stock QIIME 2 actions.
It covers what you run on your own data: classifying and filtering the amplicon features, profiling the metagenome reads, integrating both at one taxonomic level, and comparing the two profile types on the samples they share.
[How the tutorial data and the reference artifacts were prepared](data-preparation.md) is a separate page.
The commands assume an environment with both plugins installed ([README](README.md)).

<!-- @gregcaporaso, reminder for the prose: say that the abundance-weighted results on this 10% subset equal the full-depth run (bacon job 308 versus jobs 300 to 307: weighted UniFrac pseudo-F 2.61 against 2.62, Bray-Curtis 3.21 against 3.20) while the presence-based metrics and the feature counts move (unweighted UniFrac 4.62 against 3.83, Jaccard 4.93 against 4.58, 2,020 against 2,385 features) because sylph detects fewer genomes at this depth. -->

<!-- @gregcaporaso, reminder for the prose: explain why a reader's numbers differ slightly from the ones shown. The PERMANOVA p-values are permutation estimates and the random forest draws its folds and trees afresh each run, so p-values wobble in the third decimal and the accuracy by a sample or two (0.90 and 0.95 on two runs of this page on the same inputs); the pseudo-F values and the feature summary are deterministic. No random seed is set on purpose: copied commands would reuse it. -->

## Working directory

Create a directory for the tutorial and change into it; every file below is written there.
The amplicon, metagenome and reference files get a subdirectory each, and so does every integration level, because QIIME 2 does not create the directory of an output.

```shell
mkdir confluence-tutorial
cd confluence-tutorial
mkdir 16S wgs reference genus family
```

## Downloading the data

Every file the tutorial uses: the study data (the sample metadata as an `ImmutableMetadata` artifact, the ASV table and sequences, the 10% subset of the shotgun reads, 4.8 GB) and the reference artifacts (the GTDB r232 trees collapsed to genus and to family, the GTDB r232 classifier from the rachis Zenodo record, the SILVA 144 V4 classifier from SILVA).
The sylph database is fetched by an action below, not by `wget`.

```shell
D='https://drive.usercontent.google.com/download?export=download&confirm=t&id='
wget -O study-metadata.qza "${D}1PJQOCPLgOJ_Jeb-_ZmEN1enFzqLhbH5S"
wget -O 16S/asv-table.qza "${D}1-HH4892h693WAQ37YvrBjV_3P7xA3UgF"
wget -O 16S/asv-sequences.qza "${D}1LzOioUEnzP4nbOsV9v75VGaqfgseagbi"
wget -O wgs/wgs-subset-reads.qza "${D}1fkzsYoWAIeGOJDQrdqGcf5k5rNfoFR7E"
wget -O reference/gtdb-r232-genus-tree.qza "${D}1sgwhDnhSXIbliFb-Fdi3o1u2NExqbovD"
wget -O reference/gtdb-r232-family-tree.qza "${D}1MM2gsJFqSF-Ec7nHcqvKVGReliEjDM_R"
wget -O reference/gtdb-r232-classifier.qza 'https://zenodo.org/records/21619532/files/gtdb-r232.0-2026.7.0-classifier.qza?download=1'
wget -O reference/silva-144-v4-classifier.qza 'https://www.arb-silva.de/fileadmin/silva_databases/current/QIIME2/2026.7/SSU/V4-515f-806r/uniform/SILVA_144_SSURef_NR99_uniform_classifier_V4-515f-806r.qza'
md5sum study-metadata.qza 16S/*.qza wgs/*.qza reference/*.qza
```

The md5 sums should match the table; the UUID identifies each artifact in provenance (`qiime tools peek <file>`).

| File | md5 | Artifact UUID |
|---|---|---|
| `study-metadata.qza` | `8ed73161d2d70d9a9499d531401bd725` | `7d0ae7fb-1f89-4b1f-b475-ff6f0263d492` |
| `16S/asv-table.qza` | `c7313d6efe664c559104120d23291010` | `e02ea2d0-16a7-457b-8009-03ed2874216c` |
| `16S/asv-sequences.qza` | `a4173850ea0e9cc3220cede19cec6a30` | `ce58ed07-5639-49d0-acdd-37a56f5a4476` |
| `wgs/wgs-subset-reads.qza` | `884d47f6948d010356cde49594238b3f` | `09901ee0-9bca-4825-b94a-20c953d97cef` |
| `reference/gtdb-r232-genus-tree.qza` | `7b7b1b596fb3808d5c43aa2f26a3b253` | `3d56c42b-6847-474e-8b85-1f7558341ddf` |
| `reference/gtdb-r232-family-tree.qza` | `503e594f77bd53afeaa093cebc0e0afe` | `09dc4a92-9ff8-4c16-9353-6cfc958551f5` |
| `reference/gtdb-r232-classifier.qza` | `1a39a83bcf9394809b13a2d758297270` | `75d340c4-dff1-4790-b6b6-04ea8217ab84` |
| `reference/silva-144-v4-classifier.qza` | `683a71dcd81ce90d724add22d2ad4d0f` | `76237f8f-87e0-4d1e-93b9-970bb7603cf0` |

## Sample metadata

The sample metadata of the ten tutorial samples: bin location, sample type, composting time point and core temperature in °C (both empty for the two samples that were not composting, the fresh excrement and the soil), and the sample UUID.
It is provided as an `ImmutableMetadata` artifact, `study-metadata.qza`, which any action that takes metadata accepts in place of a TSV.

```shell
qiime metadata tabulate \
  --m-input-file study-metadata.qza \
  --o-visualization sample-metadata.qzv
```

> [!TIP]
> For your own data, import the sample metadata TSV into an `ImmutableMetadata` artifact once (the import command is on the [data preparation page](data-preparation.md#sample-metadata)) and pass the artifact everywhere the TSV would go.
> The artifact has a UUID, so provenance records which version of the metadata each result was made from; a TSV passed directly is recorded only by its contents.
> Either way, the metadata contents are written into the provenance of every downstream result, so a metadata file must not hold anything that cannot travel with the artifacts.
> Metadata in QIIME 2, including the artifact form, is described in the [metadata reference](https://use.qiime2.org/en/latest/references/metadata/).

## Reference data

Both profile types are placed on GTDB r232.
The GTDB bacterial tree collapsed to one tip per genus and per family was prepared once for the release ([how](data-preparation.md#reference)); the amplicon classifiers come from their publishers, and the sylph database from the sylph authors.

The metagenome reads are profiled with sylph through the `sylph` plugin (mosh-sylph), thin wrappers around sylph and sylph-tax.
The sylph database of the GTDB r232 species representatives is about 20 GB, and every action that reads a `.qza` file unzips it first.
An [artifact cache](https://use.qiime2.org/en/stable/tutorials/use-the-artifact-cache/) keeps artifacts unzipped under a key, referenced as `cache:key` in place of a file path, so the large artifacts are written once and never zipped or unzipped again.
The commands below keep the database, its taxonomy and the read sketches in a cache called `cache` inside the tutorial directory and pass `--use-cache cache` to the actions that read or write them; the tutorial's own data stays in `.qza` files, with its provenance.
`fetch-database` downloads the authors' pre-built database, and `tax-download` the matching sylph-tax taxonomy.

```shell
qiime tools cache-create --cache cache

qiime sylph fetch-database \
  --p-release 232 \
  --use-cache cache \
  --o-database cache:sylph-gtdb-r232

qiime sylph tax-download \
  --p-taxonomy GTDB_r232 \
  --use-cache cache \
  --o-sylph-taxonomy cache:sylph-tax-gtdb-r232
```

## Amplicon data

The amplicon side starts from the denoised ASV table and sequences of the ten samples ([how](data-preparation.md#amplicon-data)).
The GTDB classifier gives every ASV a GTDB taxonomy; the SILVA classifier is used only to find organelle (mitochondria, chloroplasts) and other eukaryotic sequences, which GTDB cannot name.

```shell
qiime feature-classifier classify-sklearn \
  --i-classifier reference/gtdb-r232-classifier.qza \
  --i-reads 16S/asv-sequences.qza \
  --p-n-jobs 8 \
  --o-classification 16S/asv-taxonomy-gtdb.qza

qiime feature-classifier classify-sklearn \
  --i-classifier reference/silva-144-v4-classifier.qza \
  --i-reads 16S/asv-sequences.qza \
  --p-n-jobs 8 \
  --o-classification 16S/asv-taxonomy-silva.qza
```

Organelles and eukaryotic sequences are removed with the SILVA taxonomy, then the table is restricted to Bacteria with the GTDB taxonomy, because the reference tree is the bacterial GTDB tree and `integrate` refuses features that are not tips of it.

```shell
qiime taxa filter-table \
  --i-table 16S/asv-table.qza \
  --i-taxonomy 16S/asv-taxonomy-silva.qza \
  --p-exclude f__Mitochondria,o__Chloroplast,d__Eukaryota \
  --p-mode contains \
  --o-filtered-table 16S/asv-table-noorganelles.qza

qiime taxa filter-table \
  --i-table 16S/asv-table-noorganelles.qza \
  --i-taxonomy 16S/asv-taxonomy-gtdb.qza \
  --p-include d__Bacteria \
  --p-mode contains \
  --o-filtered-table 16S/asv-table-bacteria.qza
```

## Metagenome data

The metagenome side starts from paired-end reads that are already trimmed, free of control samples and human reads, and subsampled to 10% ([how](data-preparation.md#metagenome-data)).
sylph sketches the reads once per sample; the sketches serve every profile or query against any database, so they go into the cache too.

```shell
qiime sylph sketch \
  --i-reads wgs/wgs-subset-reads.qza \
  --p-threads 16 \
  --use-cache cache \
  --o-sketches cache:sketches
```

`profile` runs sylph profile against the database; `--p-estimate-unknown` asks sylph to estimate, per sample, the share of reads from no genome in the database.
Reading `cache:` inputs needs no extra option; `--use-cache` above mattered only where an output was written into the cache, so that the action built it there instead of in the default temporary cache.
`taxprof` attaches the taxonomy with sylph-tax, and `taxprof-to-tables` turns the per-sample profiles into QIIME 2 tables: the share of each detected genome corrected for genome size (the taxonomic abundance, the measure to integrate), the share of reads (the sequence abundance), the genome-keyed taxonomy, and per-sample statistics (genomes and genera detected, median ANI, unknown share).

```shell
qiime sylph profile \
  --i-sketches cache:sketches \
  --i-database cache:sylph-gtdb-r232 \
  --p-threads 16 \
  --p-estimate-unknown \
  --o-profile wgs/sylph-profile.qza

qiime sylph taxprof \
  --i-profile wgs/sylph-profile.qza \
  --i-sylph-taxonomy cache:sylph-tax-gtdb-r232 \
  --o-taxonomic-profiles wgs/sylph-taxonomic-profiles.qza

qiime sylph taxprof-to-tables \
  --i-taxonomic-profiles wgs/sylph-taxonomic-profiles.qza \
  --i-sketches cache:sketches \
  --o-taxonomic-abundance wgs/sylph-taxonomic-abundance.qza \
  --o-sequence-abundance wgs/sylph-sequence-abundance.qza \
  --o-taxonomy wgs/sylph-genome-taxonomy.qza \
  --o-stats wgs/sylph-stats.qza
```

The per-sample statistics are metadata and tabulate like any other; the study metadata is given last, so its columns follow the statistics in the table.

```shell
qiime metadata tabulate \
  --m-input-file wgs/sylph-stats.qza \
  --m-input-file study-metadata.qza \
  --o-visualization wgs/sylph-stats.qzv
```

As on the amplicon side, the profile is restricted to Bacteria.

```shell
qiime taxa filter-table \
  --i-table wgs/sylph-taxonomic-abundance.qza \
  --i-taxonomy wgs/sylph-genome-taxonomy.qza \
  --p-include d__Bacteria \
  --p-mode contains \
  --o-filtered-table wgs/sylph-bacteria.qza
```

## Integration

The two profiles enter as collections: each member is given as `key:path`, and the key names the profile type in every output.
`summarize-inputs` shows which sample IDs the profiles and the metadata share before anything is merged.

```shell
qiime confluence summarize-inputs \
  --i-tables amplicon:16S/asv-table-bacteria.qza metagenome:wgs/sylph-bacteria.qza \
  --i-metadata study:study-metadata.qza \
  --o-visualization inputs-summary.qzv
```

`integrate` collapses each profile to the chosen level (6 is genus with the seven GTDB ranks; 5 is family), drops the features without a name at that level, renormalizes each profile to proportions, and merges them.
Merged samples are named `<sample-id>-<key>`; the integrated metadata records `original-sample-id` and `profile-type` beside the study metadata.

```shell
qiime confluence integrate \
  --i-tables amplicon:16S/asv-table-bacteria.qza metagenome:wgs/sylph-bacteria.qza \
  --i-taxonomies amplicon:16S/asv-taxonomy-gtdb.qza metagenome:wgs/sylph-genome-taxonomy.qza \
  --i-tree reference/gtdb-r232-genus-tree.qza \
  --i-metadata study:study-metadata.qza \
  --p-level 6 \
  --o-relative-table genus/relative-table.qza \
  --o-taxonomy genus/taxonomy.qza \
  --o-integrated-metadata genus/metadata.qza
```

## Comparing the profile types without paired samples

Nothing up to this point needs paired samples.
`integrate` renames every sample of every profile type to `<sample-id>-<key>` whether or not the other type has a sample of the same ID, so two studies with no sample IDs in common integrate just the same, and `original-sample-id` keeps the input ID.
The merged relative table and the integrated metadata then go into any stock action that takes them: here Bray-Curtis and weighted UniFrac distances between all merged samples, a PERMANOVA of the profile types on the latter, its ordination as a PCoA scatter plot coloured by profile type (the PCoA result is metadata, so it merges with the integrated metadata on the command line), and a taxa bar plot of the merged table, which can be sorted and coloured by the integrated metadata.

```shell
qiime diversity beta \
  --i-table genus/relative-table.qza \
  --p-metric braycurtis \
  --o-distance-matrix genus/bray-curtis.qza

qiime diversity beta-phylogenetic \
  --i-table genus/relative-table.qza \
  --i-phylogeny reference/gtdb-r232-genus-tree.qza \
  --p-metric weighted_unifrac \
  --o-distance-matrix genus/weighted-unifrac.qza

qiime diversity beta-group-significance \
  --i-distance-matrix genus/weighted-unifrac.qza \
  --m-metadata-file genus/metadata.qza \
  --m-metadata-column profile-type \
  --o-visualization genus/weighted-unifrac-profile-type.qzv

qiime diversity pcoa \
  --i-distance-matrix genus/weighted-unifrac.qza \
  --o-pcoa genus/weighted-unifrac-pcoa.qza

qiime vizard scatterplot-2d \
  --m-metadata-file genus/weighted-unifrac-pcoa.qza \
  --m-metadata-file genus/metadata.qza \
  --p-x-measure 'Axis 1' \
  --p-y-measure 'Axis 2' \
  --p-color-by profile-type \
  --p-title 'Weighted UniFrac PCoA, genus level' \
  --o-visualization genus/weighted-unifrac-pcoa.qzv

qiime taxa barplot2 \
  --i-table genus/relative-table.qza \
  --i-taxonomy genus/taxonomy.qza \
  --m-metadata-file genus/metadata.qza \
  --o-visualization genus/taxa-barplot.qzv
```

The paired report below is what paired samples buy on top: it keeps only the samples both profile types cover, so the comparison is between two profiles of the same material rather than between two sets of samples.

## Paired-sample report

On the samples both profile types cover, `paired-report` computes Bray-Curtis, Jaccard, unweighted and weighted UniFrac on the proportions as they are (no rarefaction), with PERMANOVA by profile type and a PCoA scatter plot for each; a random forest classifying the profile type with nested cross-validation; and a per-feature summary, tabulated over every feature and also returned as metadata.

```shell
qiime confluence paired-report \
  --i-table genus/relative-table.qza \
  --i-tree reference/gtdb-r232-genus-tree.qza \
  --i-metadata genus/metadata.qza \
  --p-permutations 999 \
  --p-cv 10 \
  --p-n-estimators 500 \
  --p-n-jobs 8 \
  --o-report genus/paired-report.qzv \
  --o-distance-matrices genus/distance-matrices/ \
  --o-feature-importance genus/feature-importance.qza \
  --o-feature-summary genus/feature-summary.qza
```

## The family-level view

The same integration and report at family: level 5 and the family tree.

```shell
qiime confluence integrate \
  --i-tables amplicon:16S/asv-table-bacteria.qza metagenome:wgs/sylph-bacteria.qza \
  --i-taxonomies amplicon:16S/asv-taxonomy-gtdb.qza metagenome:wgs/sylph-genome-taxonomy.qza \
  --i-tree reference/gtdb-r232-family-tree.qza \
  --i-metadata study:study-metadata.qza \
  --p-level 5 \
  --o-relative-table family/relative-table.qza \
  --o-taxonomy family/taxonomy.qza \
  --o-integrated-metadata family/metadata.qza

qiime confluence paired-report \
  --i-table family/relative-table.qza \
  --i-tree reference/gtdb-r232-family-tree.qza \
  --i-metadata family/metadata.qza \
  --p-permutations 999 \
  --p-cv 10 \
  --p-n-estimators 500 \
  --p-n-jobs 8 \
  --o-report family/paired-report.qzv \
  --o-distance-matrices family/distance-matrices/ \
  --o-feature-importance family/feature-importance.qza \
  --o-feature-summary family/feature-summary.qza
```

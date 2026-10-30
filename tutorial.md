# Integrating 16S and metagenome profiles: the tutorial

🧬 This tutorial integrates a 16S rRNA amplicon profile and a metagenome profile of the same samples in one feature space: Genome Taxonomy Database (GTDB) genomes.
It uses `q2-confluence` and `mosh-sylph`, two [`rachis`](https://rachis.org) plugins, expanding on [QIIME 2](https://qiime2.org) 2026.10.
If you're new to QIIME 2, I recommend reading [*Getting Started with QIIME 2*](https://amplicon-docs.qiime2.org/en/stable/explanations/getting-started/) (about 10 minutes) to familiarize yourself with some of the jargon that will pop up here.
The [`rachis` glossary](https://news.rachis.org/en/latest/glossary/) may also be helpful.

**All `.qza` and `.qzv` files used in this tutorial can be viewed with [`rachis-view`](https://view.rachis.org).**

The data used in this tutorial is real data from a currently unpublished microbiome study that is ongoing in the [Caporaso Lab](http://caplab.dev).
Please consider it available only for use with this tutorial as we work toward publication of that project.

The tutorial starts with:

 * sample metadata describing the 10 samples that are used in the tutorial
 * a 16S rRNA ASV table and ASV sequences for those 10 samples
 * metagenomic reads for those 10 samples

Both the 16S and metagenome data are from the same samples, which allows us to directly assess how well the two different data types integrate.
The premise is that if the integration is working well, when we look at results like an ordination performed on the integrated 16S and metagenome data, we should see the biology driving the patterns in the PCoA, not the sequencing approach.
The 10 samples span what we call the "gut-to-soil" axis: the transition of human-gut-like microbiomes to soil-like microbiomes through the processing of human excrement composting (HEC).
You can learn about [why](https://gut-to-soil-tutorial.readthedocs.io/en/2026.10/why/) we are interested in HEC here, but for the purpose of this tutorial all you need to know is that both human-gut-like and soil-like microbiomes are represented in the data, so it allows for assessment of how well we should expect this integration to work on both data types.
Spoiler: it seems to work really well on human gut microbiomes, and only moderately well on soil microbiomes right now with some improvements in progress.

Before you run the tutorial, you'll need to install QIIME 2, `q2-confluence`, and `mosh-sylph`.
Find the instructions for doing that [here](install.md).

You can see how the tutorial data was prepared [here](data-preparation.md).

**Note**: The prose in this tutorial is still a work in progress and is pretty sparse at the moment.

At the bottom of this document [the known limitations](#workflow-limitations) of this workflow are described.

## Requirements

** GREG TO REVIEW: this section was drafted by Claude from the run of this page on bacon on 2026-10-30 (job 327). **

💻 The tutorial was tested on a 16-core Linux server, where all of its commands together took about 30 minutes, about 11 of them downloading the data and the sylph database.
You'll need:

 * **Memory**: about 14 GB for `classify-sklearn`, which runs with `--p-n-jobs 8` and whose memory grows with the number of jobs; lower `--p-n-jobs` if you have less.
   Every other command needs about 5 GB or less, most of them about 1 GB.
 * **CPUs**: the sylph commands run with `--p-threads 16`, and `classify-sklearn`, `cluster-features-closed-reference` and `paired-report` with 8 jobs or threads; with fewer cores, lower those values, and the commands take longer.
 * **Disk space and downloads**: about 25 GB is downloaded (19 GB of it the sylph database, 4.5 GB the metagenome reads), the finished tutorial directory takes about 25 GB, and QIIME 2 writes temporary files beyond that while it runs.

## Setup

📁 Create a directory for the tutorial and change into it; every file below is written there.

⏱️ The `# run time estimate` and `# peak memory estimate` above each command are its wall time, rounded to minutes, and its peak memory, summed over its processes, in a run of this page on a 16-core Linux server with QIIME 2 2026.10 (2026-10-30).

```shell
mkdir confluence-tutorial
cd confluence-tutorial
mkdir 16S metagenome reference genome
```

## Downloading the data

```shell
# run time estimate: 3 minutes for the downloads together, most of it the 4.8 GB reads (depends on the connection)
# peak memory estimate: < 1 GB
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
> 🍎 macOS has no `md5sum`; run `md5 -r` with the same arguments, which prints the sums in the same form.

The md5 sums and UUIDs should uniquely identify artifacts.
To list the artifact UUIDs, run:

```shell
# run time estimate: < 1 minute
# peak memory estimate: < 1 GB
qiime tools peek sample-metadata.qza 16S/*.qza metagenome/*.qza reference/*
```

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

🗂️ The sample metadata of the ten tutorial samples: bin identifier (location), sample type, composting time point and core temperature in °C (both empty for the two samples that were not composting, the fresh excrement and the soil), and the sample UUID.
It is provided as an `ImmutableMetadata` artifact.

```shell
# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime metadata tabulate \
  --m-input-file sample-metadata.qza \
  --o-visualization sample-metadata.qzv
```

> [!TIP]
> For your own data, you can use sample metadata as a `.tsv` file ([format reference](https://use.qiime2.org/en/latest/references/metadata/)) or by importing it into an `ImmutableMetadata` artifact once (the import command is on the [data preparation page](data-preparation.md#sample-metadata)).
> The artifact has a UUID, so provenance records which version of the metadata each result was made from; a TSV passed directly is recorded only by its contents.
> Either way, the metadata contents are written into the provenance of every downstream result, so a metadata file must not hold anything that cannot travel with the artifacts.

## Reference data

📚 Both profile types are integrated into the common feature space of GTDB genomes (GTDB r232 is used in this tutorial).
The amplicon features (ASVs) are mapped by closed-reference clustering against the 16S sequences of the GTDB species representatives, and the metagenome reads by sylph against the same genomes.
GTDB's bacterial tree is the phylogeny, and GTDB's genome taxonomy names the genomes.
GTDB file preparation is discussed on the [data preparation page](data-preparation.md#reference).

The metagenome reads are profiled with sylph through the `sylph` plugin (mosh-sylph), thin wrappers around sylph.
The sylph database of the GTDB r232 species representatives is about 20 GB, and every action that reads a `.qza` file unzips it first.
An [artifact cache](https://use.qiime2.org/en/stable/tutorials/use-the-artifact-cache/) keeps artifacts unzipped under a key, referenced as `cache:key` in place of a file path, so the large artifacts are written once and never zipped or unzipped again.
The commands below keep the database and the read sketches in a cache called `cache` inside the tutorial directory and pass `--use-cache cache` to the actions that write them.

```shell
# run time estimate: < 1 minute
# peak memory estimate: < 1 GB
qiime tools cache-create --cache cache

# run time estimate: 9 minutes
# peak memory estimate: about 5 GB
qiime sylph fetch-database \
  --p-release 232 \
  --use-cache cache \
  --o-database cache:sylph-gtdb-r232
```

## Amplicon data

🧪 The amplicon side starts from the denoised ASV table and sequences of the ten samples ([how](data-preparation.md#amplicon-data)).
The SILVA classifier is used to find and remove organelle (mitochondria, chloroplasts) and other eukaryotic sequences, which the GTDB reference does not name; they are removed with the SILVA taxonomy, and the ASV sequences are restricted to the features that remain, which closed-reference clustering requires.

```shell
# run time estimate: < 1 minute
# peak memory estimate: about 14 GB with --p-n-jobs 8; it grows with the number of jobs
qiime feature-classifier classify-sklearn \
  --i-classifier reference/silva-144-v4-classifier.qza \
  --i-reads 16S/asv-sequences.qza \
  --p-n-jobs 8 \
  --o-classification 16S/asv-taxonomy-silva.qza

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime taxa filter-table \
  --i-table 16S/asv-table.qza \
  --i-taxonomy 16S/asv-taxonomy-silva.qza \
  --p-exclude f__Mitochondria,o__Chloroplast,d__Eukaryota \
  --p-mode contains \
  --o-filtered-table 16S/asv-table-noorganelles.qza

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime feature-table filter-seqs \
  --i-data 16S/asv-sequences.qza \
  --i-table 16S/asv-table-noorganelles.qza \
  --o-filtered-data 16S/asv-sequences-noorganelles.qza
```

🎯 Closed-reference clustering maps every ASV to a GTDB genome: each ASV is searched against the 16S sequences of the species-representative genomes, and its counts go to the first reference at or above the identity threshold.
The clustered table is keyed by GTDB genome accessions (`RS_GCF_...`, `GB_GCA_...`), the same IDs as GTDB's tree and taxonomy and as the metagenome table below.
ASVs with no reference at the threshold are returned as the unmatched sequences and leave the analysis.

⚖️ The identity threshold is a target for optimization, and it may also be worth exploring other approaches for doing this mapping (there are many).

```shell
# run time estimate: < 1 minute
# peak memory estimate: about 2 GB
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
# peak memory estimate: about 1 GB
qiime feature-table summarize \
  --i-table 16S/genome-table.qza \
  --m-metadata-file sample-metadata.qza \
  --o-feature-frequencies 16S/genome-table-feature-frequencies.qza \
  --o-sample-frequencies 16S/genome-table-sample-frequencies.qza \
  --o-summary 16S/genome-table-summary.qzv
```

`feature-table summarize` shows how many reads and genomes each sample keeps after the mapping.

No taxonomy or phylogenetic reconstruction step is needed: the genome IDs are those of GTDB's taxonomy and tree.

## Metagenome data

🦠 The metagenome side starts from paired-end reads that are already trimmed, free of control samples and human reads, and subsampled to 10% ([how](data-preparation.md#metagenome-data)).

sylph sketches the reads once per sample; the sketches serve every profile or query against any database, so they go into the cache too.

```shell
# run time estimate: 4 minutes
# peak memory estimate: about 2 GB
qiime sylph sketch \
  --i-reads metagenome/metagenome-reads-10p.qza \
  --p-threads 16 \
  --use-cache cache \
  --o-sketches cache:sketches
```

`profile` runs sylph profile against the database; `--p-estimate-unknown` asks sylph to estimate, per sample, the share of reads from no genome in the database.

`profile-to-tables` turns the profile into QIIME 2 tables keyed by GTDB genome ID.

```shell
# run time estimate: 1 minute
# peak memory estimate: about 5 GB
qiime sylph profile \
  --i-sketches cache:sketches \
  --i-database cache:sylph-gtdb-r232 \
  --p-threads 16 \
  --p-estimate-unknown \
  --o-profile metagenome/sylph-profile.qza

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime sylph profile-to-tables \
  --i-profile metagenome/sylph-profile.qza \
  --i-sketches cache:sketches \
  --o-taxonomic-abundance metagenome/sylph-taxonomic-abundance.qza \
  --o-sequence-abundance metagenome/sylph-sequence-abundance.qza \
  --o-stats metagenome/sylph-stats.qza
```

The per-sample statistics are sample metadata and can be tabulated as such.

```shell
# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime metadata tabulate \
  --m-input-file metagenome/sylph-stats.qza \
  --m-input-file sample-metadata.qza \
  --o-visualization metagenome/sylph-stats.qzv
```

No taxonomy or phylogenetic reconstruction step is needed: the genome IDs are those of GTDB's taxonomy and tree.

## Integration

🔗 The two profiles enter as collections: each member is given as `key:path`, and the key names the profile type in every output.
`summarize-inputs` takes the inputs of `integrate` and shows, before anything is merged, which sample IDs the profiles and the metadata share and how many genomes of each profile are tips of the tree.
Any genome IDs that are present in a table but not the tree are dropped (at this time, this includes all archaea).

```shell
# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime confluence summarize-inputs \
  --i-tables amplicon:16S/genome-table.qza metagenome:metagenome/sylph-taxonomic-abundance.qza \
  --i-tree reference/gtdb-r232-bac120-tree.qza \
  --i-metadata amplicon:sample-metadata.qza metagenome:sample-metadata.qza \
  --o-visualization genome/inputs-summary.qzv
```

Samples are named `<sample-id>-<key>` to avoid collisions of sample IDs.
The integrated metadata records `original-sample-id`, `study-id`, as well as the source's number of `features-before` and `features-after` the tree filter and their quotient `features-kept-share`, beside the study metadata.
The metadata is given per profile type, under the table's key; one study profiled twice (as in the tutorial data) goes in under both keys.
A profile that loses more than a tenth of its features to the tree filter raises a warning naming the likely causes (archaea against the bacterial tree, or a reference release mismatch); the counts are in the metadata either way.

```shell
# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime confluence integrate \
  --i-tables amplicon:16S/genome-table.qza metagenome:metagenome/sylph-taxonomic-abundance.qza \
  --i-tree reference/gtdb-r232-bac120-tree.qza \
  --i-metadata amplicon:sample-metadata.qza metagenome:sample-metadata.qza \
  --o-integrated-table genome/relative-table.qza \
  --o-integrated-metadata genome/metadata.qza
```

📊 The summaries so far are collected into one report, `genome/upstream-report.qzv`, with a tab for each.
**Remember that you can view this, and all `.qza` and `.qzv` files used in this tutorial, with [`rachis-view`](https://view.rachis.org).**

```shell
# run time estimate: < 1 minute
# peak memory estimate: < 1 GB
qiime tools make-report \
  --report-path genome/upstream-report.qzv \
  16S/genome-table-summary.qzv \
  metagenome/sylph-stats.qzv \
  genome/inputs-summary.qzv
```

** GREG TO CONTINUE HERE WITH REVIEW **

## Comparing the profile types without paired samples

Nothing up to this point needs paired samples.
`integrate` renames every sample of every profile type to `<sample-id>-<key>` whether or not the other type has a sample of the same ID, so two studies with no sample IDs in common integrate just the same, and `original-sample-id` keeps the input ID.
The merged relative table and the integrated metadata then go into any stock action that takes them: here weighted UniFrac distances between all merged samples, a PERMANOVA of the profile types on them, their ordination as a PCoA scatter plot coloured by profile type (the PCoA result is metadata, so it merges with the integrated metadata on the command line), and a taxa bar plot of the merged table, which GTDB's taxonomy lets you collapse to any rank and which can be sorted and coloured by the integrated metadata.

```shell
# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime diversity beta-phylogenetic \
  --i-table genome/relative-table.qza \
  --i-phylogeny reference/gtdb-r232-bac120-tree.qza \
  --p-metric weighted_unifrac \
  --o-distance-matrix genome/weighted-unifrac.qza

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime diversity beta-group-significance \
  --i-distance-matrix genome/weighted-unifrac.qza \
  --m-metadata-file genome/metadata.qza \
  --m-metadata-column study-id \
  --o-visualization genome/weighted-unifrac-study-id.qzv

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime diversity pcoa \
  --i-distance-matrix genome/weighted-unifrac.qza \
  --o-pcoa genome/weighted-unifrac-pcoa.qza

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime vizard scatterplot-2d \
  --m-metadata-file genome/weighted-unifrac-pcoa.qza \
  --m-metadata-file genome/metadata.qza \
  --p-x-measure 'Axis 1' \
  --p-y-measure 'Axis 2' \
  --p-color-by study-id \
  --p-title 'Weighted UniFrac PCoA, GTDB genomes' \
  --o-visualization genome/weighted-unifrac-pcoa.qzv

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime taxa barplot2 \
  --i-table genome/relative-table.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --m-metadata-file genome/metadata.qza \
  --o-visualization genome/taxa-barplot.qzv

# run time estimate: < 1 minute
# peak memory estimate: < 1 GB
qiime tools make-report \
  --report-path genome/downstream-report.qzv \
  genome/weighted-unifrac-study-id.qzv \
  genome/weighted-unifrac-pcoa.qzv \
  genome/taxa-barplot.qzv
```

<!-- @gregcaporaso, reminder for the prose: explain why a reader's numbers differ slightly from the ones shown. The PERMANOVA p-values are permutation estimates and the random forest draws its folds and trees afresh each run, so p-values wobble in the third decimal and the accuracy by a sample or two; the pseudo-F values and the feature summary are deterministic. No random seed is set on purpose: copied commands would reuse it. -->

📊 `genome/downstream-report.qzv` collects the three visualizations of this section in one report.

The paired report below is what paired samples buy on top: it keeps only the samples both profile types cover, so the comparison is between two profiles of the same material rather than between two sets of samples.

## Paired-sample report

🤝 On the samples both profile types cover, `paired-report` computes Bray-Curtis and weighted UniFrac on the proportions as they are (no rarefaction, so no presence-based metric), with PERMANOVA by profile type and a PCoA scatter plot for each; a random forest classifying the profile type with nested cross-validation; and a per-feature summary, tabulated over every genome with its taxonomy beside it and also returned as metadata.

```shell
# run time estimate: 1 minute
# peak memory estimate: about 1 GB
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

🏷️ The genome space is one choice of feature space; the same integrated data can be compared at a taxonomic level instead.
`taxa collapse` sums the merged table within each taxon of GTDB's taxonomy (level 6 is genus with the seven GTDB ranks, 5 family), and `gtdb-tree-collapse` collapses the imported GTDB tree to the same rank, with one tip per taxon named like the collapsed features, so the two still match; its log records which genomes each tip stands for.
The collapse takes about ten seconds on r232 and keeps GTDB's bootstrap and taxon labels on the remaining internal nodes.
The integrated metadata is unchanged, because collapsing touches features, not samples, and the collapsed feature IDs are the taxonomy strings themselves, so the report needs no taxonomy.
The paired report then runs as above, at genus.

```shell
mkdir genus

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime taxa collapse \
  --i-table genome/relative-table.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table genus/relative-table.qza

# run time estimate: < 1 minute
# peak memory estimate: about 2 GB
qiime confluence gtdb-tree-collapse \
  --i-tree reference/gtdb-r232-bac120-tree.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --p-level 6 \
  --o-collapsed-tree genus/gtdb-r232-genus-tree.qza \
  --o-collapse-log genus/gtdb-r232-genus-tree-collapse-log.qza

# run time estimate: 1 minute
# peak memory estimate: about 1 GB
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
🔀 Mapping the ASVs to genomes is not the only way to reach a taxonomic level: the ASVs can instead be classified with the GTDB r232 classifier (from the same Zenodo record as the 16S reference sequences), and both profiles collapsed by taxonomy before they are integrated.
On the tutorial data that approach agreed less well at genus, where weighted UniFrac separated the two profile types as well (pseudo-F 2.6, p 0.01), so how the amplicon features reach a taxonomic level matters more than the level itself.

## Searching for a taxon (optional)

🔎 This optional step asks a different question of the same sketches: is a particular organism present, and how close is it to a reference genome?
`sylph profile` above reports abundances and assigns shared k-mers to one genome; `sylph query` instead reports, for every database genome with enough sampled k-mers in a sample, the coverage-adjusted average nucleotide identity (ANI) of the reads to that genome, so closely related genomes are all listed and nothing is reassigned.
`query-to-metadata` tabulates the result as metadata, joins GTDB's taxonomy by genome ID, and keeps only the rows whose taxonomy string or genome ID contains one of the given texts; `metadata tabulate` then shows the table.
Here the search is for *Escherichia coli*; the text matches every GTDB species cluster whose name starts with it (in r232 `s__Escherichia coli`, `s__Escherichia coli_E` and `s__Escherichia coli_F`), so narrow it to one cluster, or widen it to `g__Escherichia`, as the question requires.
At effective coverage below about 0.1x the adjusted ANI and its 5 to 95 percentile interval overshoot (the 95th percentile can exceed 100); read such rows with the containment index and the naive ANI.

```shell
mkdir genome/metagenome-containment-analysis

# run time estimate: 1 minute
# peak memory estimate: about 5 GB
qiime sylph query \
  --i-sketches cache:sketches \
  --i-database cache:sylph-gtdb-r232 \
  --p-threads 16 \
  --o-query genome/metagenome-containment-analysis/sylph-query.qza

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime sylph query-to-metadata \
  --i-query genome/metagenome-containment-analysis/sylph-query.qza \
  --i-taxonomy reference/gtdb-r232-bac120-taxonomy.qza \
  --p-targets 's__Escherichia coli' \
  --o-query-metadata genome/metagenome-containment-analysis/escherichia-coli-query.qza

# run time estimate: < 1 minute
# peak memory estimate: about 1 GB
qiime metadata tabulate \
  --m-input-file genome/metagenome-containment-analysis/escherichia-coli-query.qza \
  --o-visualization genome/metagenome-containment-analysis/escherichia-coli-query.qzv
```

On the tutorial data the search returns six rows: the three *Escherichia coli* clusters of r232 (`s__Escherichia coli`, `coli_E` and `coli_F`), each found in the fresh excrement (1135D, adjusted ANI 94 to 98) and in the day-1 compost (DB47D, 94 to 99) at effective coverage of 0.06x to 0.18x, and in none of the eight later or soil samples: *E. coli* arrives with the feedstock and is gone from the compost by day 2.
⚠️ `query-to-metadata` fails when no genome matches the targets, so a search for an organism that is absent from every sample stops here rather than tabulating an empty table.

## Workflow limitations

### Reference coverage

16S analysis can only identify the 88,481 bacterial species-representative genomes that are contained in the 16S reference, while metagenome analysis can identify any of the 189,801 bacterial genomes represented in the GTDB bacterial reference tree.
Relatedness-based diversity metrics (e.g., UniFrac) help manage these differences by down-weighting differences between similar organisms across samples.

The numbers of bacterial genomes and 16S rRNA sequences grow with each GTDB release (roughly annually):

 * r202 (2021): 45,555 genomes; 31,319 (69%) have 16S references
 * r207 (2022): 62,291 genomes; 38,474 (62%) have 16S references
 * r214 (2023): 80,789 genomes; 46,891 (58%) have 16S references
 * r220 (2024): 107,235 genomes; 58,102 (54%) have 16S references
 * r226 (2025): 136,646 genomes; 72,862 (53%) have 16S references
 * r232 (2026): 189,801 genomes; 88,481 (47%) have 16S references

⚠️ Two limitations of this mapping are worth knowing.
Only about half of the bacterial species representatives of GTDB r232 have a 16S sequence in the reference (88,481 of 189,801), so an ASV whose genome is among the rest can only land on a relative's genome, at a lower threshold.
And among references with identical V4 regions, vsearch returns the first one at or above the threshold rather than a best or a consensus hit (`cluster-features-closed-reference` does not expose vsearch's `maxaccepts`), so the particular genome an ASV lands on is arbitrary within such a group; relatedness-based diversity metrics (weighted UniFrac, here) control for that a bit, but the identity-based metrics (Bray-Curtis, here) do not.

### Real-world testing

This workflow has been assessed on one small (n=10) study with paired 16S and metagenome samples to date.
We will evaluate it on the remaining samples from that study (pending sequencing, n=183 samples).

### Sampling depth

Direct control of uneven sampling depth (e.g., with rarefaction) has not been applied and is an unsolved problem at this time.
For this reason, we recommend focusing only on abundance-weighted diversity metrics, such as weighted UniFrac and Bray-Curtis.
Paired with the note above regarding reference coverage, weighted UniFrac is the recommended beta diversity metric for exploring integrated 16S and metagenome data.

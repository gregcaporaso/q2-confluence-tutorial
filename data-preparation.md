# How the tutorial data were prepared

📝 None of this is part of the tutorial: it records how the artifacts the [tutorial](tutorial.md) downloads were produced, so that the same can be done for another data set.
Every step is also in the provenance of the artifacts themselves.

## Reference

🌳 Two reference artifacts are hosted with the study data: GTDB's r232 bacterial tree and genome taxonomy, imported from the files GTDB publishes with the commands below.
The other references are not re-hosted: the tutorial fetches the GTDB r232 16S reference sequences from the rachis Zenodo record (the training data of that record's GTDB classifier), the SILVA 144 V4 uniform classifier from SILVA, and the sylph database from the sylph authors with the `sylph` plugin's `fetch-database`.

The tree is imported through the `confluence` plugin's `GTDBNewickFormat`, which drops the quoted root label without a branch length that GTDB's Newick file ends in (`'100:d__Bacteria'`), because UniFrac's parser aborts on it; the GTDB file itself is unchanged and its md5 is in the artifact's provenance.
The rooting of the tree is documented on the imported artifact with a Note annotation (`annotation-create` below), which every artifact derived from it carries along; `qiime tools annotation-list --input-path <artifact>` shows it and `qiime tools annotation-fetch --input-path <artifact> --name rooting --verbose` prints its text.
The hosted artifacts were made on 2026-10-30 from GTDB files with md5 `a8b589ffabbf41ebd7e8ab45795b8e6a` (`bac120_r232.tree`) and `807e3221f5553142eb0544ce3247d079` (`bac120_taxonomy_r232.tsv.gz`); the taxonomy artifact's provenance records the md5 of the unzipped file, `4d42e137959485d57e8589bdf1b4c347`.

```shell
wget 'https://data.gtdb.ecogenomic.org/releases/release232/232.0/bac120_r232.tree'
wget 'https://data.gtdb.ecogenomic.org/releases/release232/232.0/bac120_taxonomy_r232.tsv.gz'

qiime tools import \
  --type 'Phylogeny[Rooted]' \
  --input-format GTDBNewickFormat \
  --input-path bac120_r232.tree \
  --output-path gtdb-r232-bac120-tree.qza

qiime tools annotation-create \
  --input-path gtdb-r232-bac120-tree.qza \
  --annotation-type Note \
  --name rooting \
  --text "This tree keeps the root of the GTDB r232 bac120 reference tree, \
which GTDB places arbitrarily: in the distributed tree it sits on the branch \
to the phylum Spirochaetota, splitting that branch into two equal halves. \
GTDB advises that its reference trees should be treated as unrooted \
(D. Parks, GTDB forum, 2021-07-12, \
https://forum.gtdb.ecogenomic.org/t/root-of-bacterial-tree/161), and its \
rank normalization averages over many plausible rootings because the rooting \
of the bacterial tree remains controversial (Parks et al. 2018, Nat \
Biotechnol 36:996, doi:10.1038/nbt.4229). The root is therefore not \
biologically meaningful; results that depend on root placement should be \
read with that in mind."

gunzip -k bac120_taxonomy_r232.tsv.gz

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path bac120_taxonomy_r232.tsv \
  --output-path gtdb-r232-bac120-taxonomy.qza
```

🏷️ For an analysis at a taxonomic level rather than in the genome space (the merged table collapsed with `taxa collapse`), the tree is collapsed once per release and level with `gtdb-tree-collapse`, on the tree imported as above; on r232 each collapse takes about ten seconds (34,834 genera, 6,048 families).
Each collapse log is feature metadata keyed by the collapsed tip names: the node's name in the GTDB tree, the number of genomes it stands for and their accessions (`qiime metadata tabulate` views it).

```shell
qiime confluence gtdb-tree-collapse \
  --i-tree gtdb-r232-bac120-tree.qza \
  --i-taxonomy gtdb-r232-bac120-taxonomy.qza \
  --p-level 6 \
  --o-collapsed-tree gtdb-r232-genus-tree.qza \
  --o-collapse-log gtdb-r232-genus-tree-collapse-log.qza
```

## Amplicon data

🧪 The 16S rRNA V4 amplicons (515F/806R) of the study were sequenced on a paired-end Illumina run of 199 samples.
The reads were imported from the run's Casava 1.8 fastq directory into the artifact the tutorial's 16S artifacts descend from (UUID `c25c70e1-0209-4b88-bfec-db2f815808be`), primer-trimmed with cutadapt, denoised with DADA2, renamed to the study's sample IDs and restricted to the ten samples with a metagenome profile.
For your own demultiplexed paired-end fastq files, [fq-manifestor](https://gregcaporaso.github.io/fq-manifestor-web/) builds the manifest file from which `qiime tools import` makes such a `demux.qza` (the metagenome reads below were imported that way); `demux summarize` shows the read counts and the per-position quality from which DADA2's truncation lengths are chosen.

```shell
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --input-path 16S-fastq/ \
  --output-path 16S-demux.qza

qiime demux summarize \
  --i-data 16S-demux.qza \
  --o-visualization 16S-demux.qzv
```

✂️ One cutadapt pass removes the primers from the 5' end of each read and trims the poly-G tails that two-colour Illumina chemistry writes where the signal runs out (`--p-nextseq-trim 1`: trailing Gs and bases below quality 1, leaving quality filtering to DADA2).
DADA2 then discards every read shorter than its truncation length, so reads that were mostly G leave there.
The primers' reverse complements are not searched at the 3' end, because the reads are truncated at 240 bases, before the far primer at the end of the V4 insert of about 253 bases.
The trimming statistics give, per sample, the share of reads in which a primer was found; a low share points at the wrong primers or at reads from which the sequencing provider already removed them.

```shell
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences 16S-demux.qza \
  --p-front-f GTGCCAGCMGCCGCGGTAA \
  --p-front-r GGACTACHVGGGTWTCTAAT \
  --p-nextseq-trim 1 \
  --p-cores 16 \
  --o-trimmed-sequences 16S-trimmed.qza \
  --o-stats 16S-trimming-stats.qza

qiime metadata tabulate \
  --m-input-file 16S-trimming-stats.qza \
  --o-visualization 16S-trimming-stats.qzv

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs 16S-trimmed.qza \
  --p-trunc-len-f 240 \
  --p-trunc-len-r 240 \
  --p-n-threads 0 \
  --o-table 16S-table-run-ids.qza \
  --o-representative-sequences 16S-asv-sequences-all.qza \
  --o-denoising-stats 16S-denoising-stats.qza \
  --o-base-transition-stats 16S-base-transition-stats.qza
```

The run's sample IDs carry a `CLINICAL_16S-` prefix (`CLINICAL_16S-1135D`); `rename-ids` maps them to the study's IDs with a two-column table (`id`, `new_id`) of the 199 samples, and the ten tutorial samples are then kept with the sample metadata of the [last section](#sample-metadata).

```shell
qiime feature-table rename-ids \
  --i-table 16S-table-run-ids.qza \
  --m-metadata-file 16S-sample-ids.tsv \
  --m-metadata-column new_id \
  --o-renamed-table 16S-table-all.qza

qiime feature-table filter-samples \
  --i-table 16S-table-all.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-filtered-table 16S-asv-table.qza

qiime feature-table filter-seqs \
  --i-data 16S-asv-sequences-all.qza \
  --i-table 16S-asv-table.qza \
  --o-filtered-data 16S-asv-sequences.qza
```

The hosted artifacts were made in April 2026 with three cutadapt passes that their provenance records: the primers, with their reverse complements as 3' adapters (`--p-times 2`); the same again with `--p-nextseq-trim 1`; and a pass discarding reads that contain nine Gs in a row (`--p-anywhere-f`/`-r GGGGGGGGG --p-discard-trimmed`).
⚠️ The single pass above is meant to do the same work but has not been run on these data, so its DADA2 output would differ slightly from the hosted artifacts.
The organelle filter and the closed-reference clustering are part of the tutorial, because they are what a reader runs on their own data; the Bacteria filter that preceded `integrate` until 2026-10-23 is gone, since `integrate` keeps only the genomes that are tips of the tree.

## Metagenome data

🦠 The metagenome reads of the same ten samples were imported from a fastq manifest (which [fq-manifestor](https://gregcaporaso.github.io/fq-manifestor-web/) makes) into the artifact the tutorial's reads descend from (UUID `ecb81f0a-0a5a-4dec-a2cb-44ee28e53940`), trimmed with fastp, cleared of the run's control samples, cleared of human reads with the MOSHPIT human pangenome filter, and subsampled to 10%.
The subset holds 2.4 to 4.8 million read pairs per sample (median 4.1 million); at that depth the sylph profile is indistinguishable from the full depth by weighted and unweighted UniFrac.
The hosted reads artifact carries the provenance of every step.

```shell
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-format PairedEndFastqManifestPhred33V2 \
  --input-path wgs-manifest.tsv \
  --output-path demux.qza

mosh fastp process-seqs \
  --i-sequences demux.qza \
  --p-length-required 90 --p-cut-mean-quality 30 --p-cut-tail \
  --o-processed-sequences reads.qza \
  --o-reports fastp-reports.qza

mosh demux filter-samples \
  --i-demux reads.qza \
  --m-metadata-file controls.tsv \
  --p-exclude-ids \
  --o-filtered-demux reads-nocontrols.qza

mosh quality-control filter-reads-human-pangenome \
  --i-reads reads-nocontrols.qza \
  --p-threads 16 \
  --o-filtered-reads reads-nohost.qza \
  --o-reference-index human-pangenome-bowtie2.qza

qiime demux subsample-paired \
  --i-sequences reads-nohost.qza \
  --p-fraction 0.1 \
  --o-subsampled-sequences metagenome-reads-10p.qza
```

⏳ The human pangenome index downloads GRCh38 and the HPRC pangenome and takes hours the first time (on a 16-core server: 4 h to build at 50 GB peak, then 5 h 42 min to filter 393 million pairs at 58 GB peak, removing 3.8% of them); pass `--i-index human-pangenome-bowtie2.qza` on later runs.

## Sample metadata

🗂️ The study's sample sheet was reduced to the ten tutorial samples and to five columns, renamed in kebab-case: `bin-location`, `sample-type`, `composting-time-point` and `core-temp-c` (the compost core temperature in °C; both are empty for the two samples that were not composting, the fresh excrement and the soil) and `sample-uuid`.
The table is hosted as an `ImmutableMetadata` artifact, imported from the TSV; the artifact is what the tutorial downloads and passes to every action that takes metadata.

```shell
qiime tools import \
  --type ImmutableMetadata \
  --input-path sample-metadata.tsv \
  --output-path sample-metadata.qza
```

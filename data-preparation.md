# How the tutorial data were prepared

<!-- Draft by Claude, pending @gregcaporaso's rewrite. Plain Markdown since
2026-10-16 (the MyST labels left; the links are GitHub heading anchors).
These steps are the record of what produced the hosted artifacts; a reader
of the tutorial does not run them, and the thermo-hec project's
slurm/tutorial.sbatch never extracts this page. The subsetting of the
amplicon data to the ten tutorial samples is not shown: it is in the
artifacts' provenance. 2026-10-21: the reference section shrank when the
tutorial moved to the genome space; the GTDB tree and taxonomy are now
imported on the tutorial page itself, and no collapsed tree is hosted. -->

None of this is part of the tutorial: it records how the artifacts the [tutorial](tutorial.md) downloads were produced, so that the same can be done for another data set.
Every step is also in the provenance of the artifacts themselves.

## Reference

No reference artifact is re-hosted: the tutorial fetches GTDB's r232 bacterial tree and genome taxonomy from GTDB and imports them itself, the GTDB r232 16S reference sequences and taxonomy from the rachis Zenodo record (the training data of that record's GTDB classifier), the SILVA 144 V4 uniform classifier from SILVA, and the sylph database from the sylph authors with the `sylph` plugin's `fetch-database`.

The tree is imported through the `confluence` plugin's `GTDBNewickFormat`, which drops the quoted root label without a branch length that GTDB's Newick file ends in (`'100:d__Bacteria'`), because UniFrac's parser aborts on it; the GTDB file itself is unchanged and its md5 is in the artifact's provenance.
The rooting of the tree is documented on the imported artifact with a Note annotation (the command is on the tutorial page), which every artifact derived from it carries along; `qiime tools annotation-list --input-path <artifact>` shows it and `qiime tools annotation-fetch --name rooting --verbose` prints its text.

For integration at a taxonomic level rather than in the genome space (`integrate --p-level`), the tree is collapsed once per release and level with `gtdb-tree-collapse`, on the tree imported as above; on r232 each collapse takes about ten seconds (34,834 genera, 6,048 families).
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

The 16S rRNA V4 amplicons (515F/806R) of the study were sequenced on an Illumina run of 199 samples and denoised with DADA2 in the QIIME 2 amplicon distribution, giving the ASV table and the ASV sequences.
The tutorial artifacts are those outputs restricted to the ten samples with a metagenome profile (`feature-table filter-samples` and `filter-seqs`; the step is in their provenance).
The organelle filter, the closed-reference clustering and the Bacteria filter are part of the tutorial, because they are what a reader runs on their own data.

## Metagenome data

The shotgun reads of the same ten samples were imported from a fastq manifest, trimmed with fastp, cleared of the run's control samples, cleared of human reads with the MOSHPIT human pangenome filter, and subsampled to 10%.
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
  --o-subsampled-sequences wgs-subset-reads.qza
```

The human pangenome index downloads GRCh38 and the HPRC pangenome and takes hours the first time (on a 16-core server: 4 h to build at 50 GB peak, then 5 h 42 min to filter 393 million pairs at 58 GB peak, removing 3.8% of them); pass `--i-index human-pangenome-bowtie2.qza` on later runs.

## Sample metadata

The study's sample sheet was reduced to the ten tutorial samples and to five columns, renamed in kebab-case: `bin-location`, `sample-type`, `composting-time-point` and `core-temp-c` (the compost core temperature in °C; both are empty for the two samples that were not composting, the fresh excrement and the soil) and `sample-uuid`.
The table is hosted as an `ImmutableMetadata` artifact, imported from the TSV; the artifact is what the tutorial downloads and passes to every action that takes metadata.

```shell
qiime tools import \
  --type ImmutableMetadata \
  --input-path sample-metadata.tsv \
  --output-path sample-metadata.qza
```

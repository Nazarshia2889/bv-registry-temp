# Bulk RNA-seq quantification

Selective-alignment quantification with Salmon. Output `quant.sf` files feed
directly into `tximport`/`DESeq2` in R.

## Tools

- `fastp` - read QC + trim
- `salmon` - index + quant (selective alignment)
- `samtools` - auxiliary indexing
- `multiqc` - aggregate report

## Inputs

- Paired-end FASTQ in `data/<sample>_{1,2}.fq.gz`
- A pre-built Salmon index at `data/salmon_index/` (build once via
  `salmon index -t transcripts.fa -i data/salmon_index -k 31`)

## Run

```sh
bv sync
./run.sh sample1
```

For STAR + featureCounts instead of Salmon, swap the quant step. Both paths
are supported by the registry - see `examples/rnaseq-bulk-star/` (TODO).

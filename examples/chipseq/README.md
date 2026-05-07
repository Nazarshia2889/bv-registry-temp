# ChIP-seq

Single-end ChIP-seq with input control: align → dedup → narrow peaks →
coverage track → motif discovery.

## Tools

8 tools. Most of the heavy lifting is bowtie2 (mapping), macs3 (peaks), and
homer (motifs). deeptools generates a normalized BigWig for IGV.

## Inputs

- ChIP single-end FASTQ + matched input FASTQ
- A pre-built bowtie2 index (prefix passed via `GENOME_INDEX=`)
- The genome FASTA at `${GENOME_INDEX}.fa` for HOMER

## Run

```sh
bv sync
GENOME_INDEX=data/hg38 ./run.sh data/chip.fq.gz data/input.fq.gz
```

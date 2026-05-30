# Germline variant calling

Short-read germline SNV and indel calling, from raw FASTQ through annotated
VCF. Roughly mirrors the GATK best-practices recipe.

## Tools

| Stage | Tool | Notes |
|---|---|---|
| QC + trim | `fastp` | per-sample read QC and adapter trimming |
| Map | `bwa-mem2` | faster bwa drop-in |
| Sort/index | `samtools` | sort, index, flagstat |
| Mark dups | `picard` | MarkDuplicates |
| Call | `gatk4` | HaplotypeCaller in GVCF mode |
| Joint | `gatk4` | GenotypeGVCFs |
| Filter | `bcftools` | hard filters / norm |
| Annotate | `ensembl-vep` | consequence + clinvar |
| Report | `multiqc` | aggregate metrics |

## Inputs

- Paired-end FASTQ in `data/<sample>_{1,2}.fq.gz`
- Reference FASTA at `data/ref.fa` (with `.fai` + `.dict` siblings)
- VEP cache at `~/.cache/bv/vep` (`bv data add vep-cache` if you want it pinned)

## Run

```sh
bv sync
./run.sh sample1
```

`run.sh` is intentionally a plain shell script for clarity. Swap in Snakemake
or Nextflow for production pipelines - `bv` is the tool layer either way.

## Reproducing this pipeline elsewhere

```sh
git clone <this-registry>
cd examples/variant-calling
bv sync           # pulls every tool by digest from bv.lock
./run.sh sample1
```

The exact bytes you ran are recorded in `bv.lock`. Three months from now,
six machines later, the same lockfile produces the same binaries.

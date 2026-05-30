# bv examples

Self-contained pipelines that demonstrate `bv` as the tool layer for common
bioinformatics workflows. Each example pins every tool by digest in
`bv.lock`, so cloning the registry and running `bv sync` reproduces the same
binaries on a laptop or HPC node.

## Layout

```
examples/
  variant-calling/      germline SNV+indel from FASTQ to annotated VCF
  rnaseq-bulk/          bulk RNA-seq quant + QC (Salmon path)
  longread-assembly/    ONT genome assembly + polish + busco
  metagenomics/         shotgun metagenomics (taxonomy + binning + MAG QC)
  protein-design/       RFDiffusion -> ProteinMPNN -> ColabFold loop
  structure-search/     fold a sequence and search for structural homologs
  phylo-pipeline/       gene-tree -> species-tree from genome FASTAs
  chipseq/              ChIP-seq peaks + motifs
  amr-surveillance/     bacterial AMR profiling from short reads
  papers/               ports of seminal/recent published pipelines
```

Each example contains:

- `bv.toml`: pinned tool list
- `bv.lock`: the digest-locked artifact
- `README.md`: what the pipeline does, what data it expects, how to run
- `run.sh` or `Snakefile`: the executable steps

## Running

```sh
cd examples/variant-calling
bv sync           # pulls images by digest
./run.sh sample1  # or `snakemake -j 8`, depending on the example
```

## Contributing

Add new examples as subdirectories. Keep them self-contained: don't reach into
sibling examples. Test with both Docker (laptop) and Apptainer (HPC) backends
before submitting.

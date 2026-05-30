# Shotgun metagenomics

Profile a microbial community at three levels:

1. **Taxonomy**: kraken2 + bracken (read-based) and metaphlan4 (marker-based)
2. **Function**: humann3 (gene families + pathways)
3. **Assembly + MAGs**: megahit → metabat2 → checkm2 → gtdb-tk

## Tools

13 tools, all factored. The kraken2/bracken/metaphlan4 layers share a
substantial amount with the bakta and humann layers (dustmasker, hmmer,
diamond), so adding them all costs roughly as much as adding two of them
individually thanks to layer dedup.

## Inputs

- Paired-end FASTQ at `data/<sample>_{1,2}.fq.gz`
- Pre-built kraken2 standard DB at `~/.cache/bv/kraken2-standard` (use
  `bv data add kraken2-standard`)
- GTDB-Tk + CheckM2 + bakta DBs in their respective `cache_paths`

## Run

```sh
bv sync
./run.sh sample1
```

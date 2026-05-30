# Bacterial AMR surveillance

From raw short reads to a multi-database AMR profile:

1. **fastp** - read QC + trim
2. **spades** - short-read assembly
3. **bakta** - bacterial annotation
4. **abricate** + **amrfinderplus** + **rgi** - three AMR databases for cross-validation

Three AMR tools because no single database has full coverage; the union gives
a more conservative call set with known false-positive characteristics.

## Inputs

- Paired-end FASTQ at `data/<sample>_{1,2}.fq.gz`
- Bakta DB cached at the path declared in the bakta manifest's `cache_paths`

## Run

```sh
bv sync
./run.sh isolate1
```

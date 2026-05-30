# CheckM2 2023 - paper port

A bv-pinned reproduction of the MAG quality assessment workflow from:

> Chklovski, A., Parks, D.H., Woodcroft, B.J., Tyson, G.W.
> **CheckM2: a rapid, scalable and accurate tool for assessing microbial
> genome quality using machine learning.**
> *Nat Methods* 20, 1203-1212 (2023).
> https://doi.org/10.1038/s41592-023-01940-w

## What it reproduces

Assemble a metagenome, recover MAGs, and quantify their quality with
CheckM2. The paper's headline result is that CheckM2's ML approach achieves
higher recall on novel lineages than CheckM's marker-gene approach. The
port produces the inputs needed to recreate that comparison locally.

1. **fastp** trims raw reads
2. **megahit** assembles contigs
3. **bwa-mem2** + **samtools** map reads back for coverage estimation
4. **metabat2** bins contigs into MAGs
5. **checkm2** scores completeness and contamination
6. **drep** dereplicates near-identical bins
7. **gtdb-tk** assigns GTDB taxonomy
8. **bakta** annotates each high-quality MAG

## Inputs

- Paired-end metagenomic FASTQ at `data/<sample>_{1,2}.fq.gz`
- CheckM2 database at `${CHECKM2_DB}` (set up via `checkm2 database --download`)
- GTDB-Tk reference at `${GTDBTK_DATA_PATH}`
- Bakta database at the path declared in the bakta manifest's `cache_paths`

The supplementary mock-community FASTQ from the paper (Mockrobiota MOCK7)
is one good starting input; any shotgun metagenome works.

## Run

```sh
bv sync
./run.sh sample1
```

## Citation

Cite Chklovski et al. 2023 if you use this port. The bv layer adds
reproducibility, not science.

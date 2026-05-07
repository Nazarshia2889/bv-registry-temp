# Foldseek 2024 - paper port

A bv-pinned reproduction of the structure-search benchmarks from:

> van Kempen, M., Kim, S.S., Tumescheit, C. *et al.*
> **Fast and accurate protein structure search with Foldseek.**
> *Nat Biotechnol* 42, 243-246 (2024).
> https://doi.org/10.1038/s41587-023-01773-0

## What it reproduces

The paper benchmarks Foldseek against MMseqs2 (sequence) and TM-align
(structure) on the SCOPe40 v2.01 dataset:

1. Fold the SCOPe40 query sequences with ColabFold (Foldseek search inputs)
2. Build a Foldseek database from SCOPe40 PDB structures
3. Run Foldseek `easy-search` and MMseqs2 `easy-search` on the query set
4. Re-score top hits with TM-align and US-align for ground truth
5. Compute sensitivity-vs-fold-rank curves matching paper Figure 2

This port runs only the open, public benchmark - not the AlphaFoldDB-scale
search, which requires ~2 TB of structures.

## Inputs

`data/scope40/` is downloaded by `setup.sh`; expected layout:

```
data/scope40/
  pdb/        # 11k PDB structures
  fasta/      # query FASTA per family
  family.tsv  # SCOPe family metadata
```

## Run

```sh
bv sync
./setup.sh   # downloads SCOPe40 (~2 GB)
./run.sh
```

## Tools

`colabfold`, `foldseek`, `mmseqs2`, `tmalign`, `usalign`, `seqkit`.

## Citation

If you use this port, cite the original paper. The bv layer adds
reproducibility, not science.

# Nextstrain 2018 - paper port

A bv-pinned reproduction of the alignment + tree + dating layer used by
Nextstrain builds, as described in:

> Hadfield, J., Megill, C., Bell, S.M. *et al.*
> **Nextstrain: real-time tracking of pathogen evolution.**
> *Bioinformatics* 34(23), 4121-4123 (2018).
> https://doi.org/10.1093/bioinformatics/bty407

## What it reproduces

The publicly orchestrated Nextstrain build wraps these tools through
`augur`. This port replaces `augur` with direct `bv exec` calls, so every
step is a pinned, reproducible binary:

1. **mafft** aligns input sequences to a reference
2. **iqtree2** infers a maximum-likelihood tree
3. **treetime** dates the tree using sample collection dates
4. **nextclade** assigns clade labels to each sequence
5. **mash** sketches help filter near-duplicate samples before alignment

A real Nextstrain build also runs ancestral state reconstruction, which
augur does itself; if you need that, run augur on top of this layer.

## Inputs

- `data/sequences.fasta` - sample sequences in FASTA
- `data/metadata.tsv` - one row per sequence with `strain` and `date` columns
- `data/reference.fasta` - the reference genome to align against
- A nextclade dataset at `${NEXTCLADE_DATASET}` (download with
  `nextclade dataset get --name <pathogen> --output-dir <path>`)

## Run

```sh
bv sync
./run.sh
```

## Citation

Cite Hadfield et al. 2018 if you use this port. The bv layer adds
reproducibility, not science.

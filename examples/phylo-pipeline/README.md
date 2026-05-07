# Phylogenetic pipeline

From a directory of genomes to a species tree:

1. **prodigal** predicts proteins per genome
2. **orthofinder** infers orthogroups
3. For each single-copy orthogroup: **mafft** → **trimal** → **iqtree2**
4. Concatenate single-copy alignments, run a partition-aware **iqtree2** to
   get the species tree with ultrafast bootstrap support

## Tools

8 tools. Most of the runtime is in iqtree2 model selection + bootstrap; the
rest is alignment-bound and parallelizes well.

## Inputs

- A directory of genome FASTAs (`*.fa`, `*.fasta`, or `*.fna`)

## Run

```sh
bv sync
./run.sh data/genomes/
```

Output: `out/species_tree.treefile` is the final ML tree with bootstrap
support values.

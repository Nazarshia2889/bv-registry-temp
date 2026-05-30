# Protein design loop

A canonical de novo design pipeline:

1. Start from a target backbone (or scaffold motif)
2. **ProteinMPNN** designs sequences for the backbone
3. **ColabFold** folds each candidate sequence
4. **TM-align / US-align** scores fold→target similarity
5. **Foldseek** searches for natural homologs of designed structures

The actual diffusion step (RFDiffusion) lives in a separate repo because it
requires SE(3) equivariant kernels not yet on bioconda. We start this example
from a precomputed backbone.

## Tools

7 tools across CPU and GPU. The GPU layers (proteinmpnn + colabfold) share
the CUDA runtime layer thanks to bv-builder's popularity-based packing, so
the marginal cost of adding both is small after the first.

## Inputs

- A backbone PDB at `data/backbone.pdb` (any monomer, ~50-250 residues)
- A target structure at `data/target.pdb` (for TM-score comparison)

## Run

```sh
bv sync
./run.sh
```

Output: `out/designs/` contains the top-scoring (TM>0.7, pLDDT>80) sequences
and their predicted structures.

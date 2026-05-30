# RFdiffusion 2023 - paper port (validation half)

A bv-pinned reproduction of the **validation** stage of the design loop in:

> Watson, J.L., Juergens, D., Bennett, N.R. *et al.*
> **De novo design of protein structure and function with RFdiffusion.**
> *Nature* 620, 1089-1100 (2023).
> https://doi.org/10.1038/s41586-023-06415-8

## Scope

RFdiffusion itself is not yet on bioconda (custom SE(3) kernels), so this
port starts from a precomputed backbone (provided in `data/backbones/`) and
runs the half of the pipeline that is fully reproducible today:

1. **ProteinMPNN** designs N sequences per backbone (paper used T=0.1, 8 seqs)
2. **ColabFold** folds each candidate
3. **TM-align / US-align** scores the predicted fold against the design backbone
4. **Foldseek** searches each successful design against AFDB / PDB100 to
   confirm the design is structurally novel (paper Figure 4 panel)

Filter: success = TM-score(prediction, design) > 0.7 AND mean pLDDT > 80.

## Inputs

- `data/backbones/*.pdb` - precomputed RFdiffusion backbones (use the
  authors' published example set or your own)
- A Foldseek DB at `${FOLDSEEK_DB}` (default: AFDB clusters)

## Run

```sh
bv sync
./run.sh
```

The protein-design example at `examples/protein-design/` runs the same logic
on a single backbone. This paper port runs the published 8-seq, multi-target
sweep so the success rates are statistically comparable.

## Citation

Cite Watson et al. 2023 if you use this port. The bv layer adds
reproducibility, not science.

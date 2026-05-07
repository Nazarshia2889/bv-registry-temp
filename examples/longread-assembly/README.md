# ONT long-read assembly

Assemble an Oxford Nanopore genome and polish it with medaka. QC with BUSCO
and QUAST.

## Tools

`chopper` (filter) → `flye` (assemble) → `minimap2` + `medaka` (polish) →
`busco` + `quast` (QC) → `samtools` (utility).

## Inputs

- Basecalled reads at `data/reads.fq.gz` (typically Q10+, R10.4.1)
- Optional: a reference assembly at `data/ref.fa` for QUAST comparison

## Run

```sh
bv sync
./run.sh
```

For PacBio HiFi data, swap `flye --nano-raw` for `--pacbio-hifi` and skip the
medaka polish; HiFi is already polished. See `examples/longread-assembly-hifi/`.

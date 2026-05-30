# Structure-based homolog search

"What does this protein do?" - when sequence-based search misses remote
homologs, fold first and search by structure.

1. **ColabFold** predicts the structure
2. **Foldseek** searches a structure database (PDB100 or AFDB) at near-MMseqs2 speed
3. **US-align** re-ranks top hits with rigorous TM-score

## Tools

6 tools. Foldseek + ColabFold share their CUDA layer with anything else GPU
in the registry.

## Inputs

- A protein FASTA at the path you pass to `run.sh`
- A Foldseek database at `${FOLDSEEK_DB}` (default
  `~/.cache/bv/foldseek-pdb100`). Build once with
  `foldseek databases PDB100 ~/.cache/bv/foldseek-pdb100 tmp`.

## Run

```sh
bv sync
./run.sh data/query.fa
```

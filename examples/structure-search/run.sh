#!/usr/bin/env bash
set -euo pipefail

QUERY="${1:?path to query FASTA required}"
DB="${FOLDSEEK_DB:-${HOME}/.cache/bv/foldseek-pdb100}"
OUT="out"
mkdir -p "${OUT}/predicted"

# 1. Fold query
bv exec colabfold_batch "${QUERY}" "${OUT}/predicted" --num-recycle 3

# 2. Foldseek search against PDB100 (or the AlphaFold DB, if you prefer)
bv exec foldseek easy-search \
    "${OUT}/predicted" "${DB}" \
    "${OUT}/hits.tsv" "${OUT}/foldseek_tmp" \
    --format-output "query,target,prob,evalue,bits,alntmscore"

# 3. Re-score top hits with US-align (more accurate but slower)
head -n 50 "${OUT}/hits.tsv" | while IFS=$'\t' read q t prob e bits tm; do
    bv exec USalign \
        "${OUT}/predicted/${q}.pdb" "${DB}/${t}.pdb" \
        >> "${OUT}/usalign.txt" 2>/dev/null || true
done

echo "done: ${OUT}/hits.tsv"

#!/usr/bin/env bash
set -euo pipefail

THREADS="${THREADS:-16}"
OUT="out"
mkdir -p "${OUT}/foldseek_db" "${OUT}/predicted" "${OUT}/foldseek_hits" \
         "${OUT}/mmseqs_hits" "${OUT}/tm_rescore"

# 1. Build Foldseek DB from SCOPe40 PDBs
bv exec foldseek createdb data/scope40/pdb "${OUT}/foldseek_db/scope40"

# 2. Fold the query sequences (one batch per family)
bv exec colabfold_batch data/scope40/queries.fa "${OUT}/predicted" \
    --num-recycle 3 --model-type alphafold2_ptm

# 3. Foldseek search
bv exec foldseek easy-search \
    "${OUT}/predicted" "${OUT}/foldseek_db/scope40" \
    "${OUT}/foldseek_hits/hits.tsv" "${OUT}/foldseek_tmp" \
    --format-output "query,target,prob,evalue,bits,alntmscore" \
    --threads "${THREADS}" -s 9.5

# 4. MMseqs2 sequence search (baseline)
bv exec mmseqs createdb data/scope40/queries.fa "${OUT}/mmseqs_db/queries"
bv exec mmseqs createdb data/scope40/all.fa "${OUT}/mmseqs_db/targets"
bv exec mmseqs search \
    "${OUT}/mmseqs_db/queries" "${OUT}/mmseqs_db/targets" \
    "${OUT}/mmseqs_hits/result" "${OUT}/mmseqs_tmp" \
    --threads "${THREADS}" -s 7.5
bv exec mmseqs convertalis \
    "${OUT}/mmseqs_db/queries" "${OUT}/mmseqs_db/targets" \
    "${OUT}/mmseqs_hits/result" "${OUT}/mmseqs_hits/hits.tsv"

# 5. Rescore top-100 Foldseek hits per query with US-align (ground truth)
awk '!seen[$1]++ || count[$1]++ < 100' "${OUT}/foldseek_hits/hits.tsv" \
  | while IFS=$'\t' read q t prob e bits alntm; do
    bv exec USalign \
        "${OUT}/predicted/${q}.pdb" "data/scope40/pdb/${t}.pdb" \
        2>/dev/null \
      | awk -v q="$q" -v t="$t" '/^TM-score=/ {print q"\t"t"\t"$2}'
done > "${OUT}/tm_rescore/usalign.tsv"

echo "done: ${OUT}/"

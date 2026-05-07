#!/usr/bin/env bash
set -euo pipefail

THREADS="${THREADS:-8}"
NEXTCLADE_DATASET="${NEXTCLADE_DATASET:?path to nextclade dataset required}"
OUT="out"
mkdir -p "${OUT}"

# 1. Optionally dereplicate near-duplicates with mash before alignment
bv exec mash sketch -p "${THREADS}" -o "${OUT}/sketch" data/sequences.fasta
bv exec seqkit rmdup -s data/sequences.fasta -o "${OUT}/dedup.fasta"

# 2. Align to reference
bv exec mafft --auto --thread "${THREADS}" \
    --keeplength --add "${OUT}/dedup.fasta" \
    data/reference.fasta \
  > "${OUT}/aligned.fasta"

# 3. Maximum-likelihood tree
bv exec iqtree2 -s "${OUT}/aligned.fasta" \
    -m GTR+G -B 1000 -T "${THREADS}" \
    --prefix "${OUT}/tree"

# 4. Time-resolved tree
bv exec treetime \
    --aln "${OUT}/aligned.fasta" \
    --tree "${OUT}/tree.treefile" \
    --dates data/metadata.tsv \
    --outdir "${OUT}/treetime" \
    --clock-filter 4

# 5. Clade calls
bv exec nextclade run \
    --input-dataset "${NEXTCLADE_DATASET}" \
    --output-tsv "${OUT}/nextclade.tsv" \
    --output-fasta "${OUT}/nextclade_aligned.fasta" \
    --jobs "${THREADS}" \
    "${OUT}/dedup.fasta"

echo "done: ${OUT}/treetime/timetree.nexus"

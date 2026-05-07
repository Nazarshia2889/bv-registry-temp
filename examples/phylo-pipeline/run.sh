#!/usr/bin/env bash
set -euo pipefail

GENOME_DIR="${1:?path to directory of genome FASTAs required}"
THREADS="${THREADS:-16}"
OUT="out"
mkdir -p "${OUT}/proteins"

# 1. Predict proteins from each genome
for fa in "${GENOME_DIR}"/*.fa "${GENOME_DIR}"/*.fasta "${GENOME_DIR}"/*.fna; do
    [ -e "${fa}" ] || continue
    base=$(basename "${fa}" | sed -e 's/\.fa$//' -e 's/\.fasta$//' -e 's/\.fna$//')
    bv exec prodigal -i "${fa}" -a "${OUT}/proteins/${base}.faa" -p meta -q
done

# 2. Orthology
bv exec orthofinder -f "${OUT}/proteins" -t "${THREADS}" -o "${OUT}/orthofinder"

# 3. For single-copy orthogroups, align + trim + tree
SC_DIR=$(find "${OUT}/orthofinder" -type d -name "Single_Copy_Orthologue_Sequences" | head -n1)
mkdir -p "${OUT}/aln" "${OUT}/trim" "${OUT}/genetrees"

for fa in "${SC_DIR}"/*.fa; do
    og=$(basename "${fa}" .fa)
    bv exec mafft --auto --thread "${THREADS}" "${fa}" > "${OUT}/aln/${og}.aln"
    bv exec trimal -in "${OUT}/aln/${og}.aln" -out "${OUT}/trim/${og}.aln" -gappyout
    bv exec iqtree2 -s "${OUT}/trim/${og}.aln" -m MFP -B 1000 -T 2 \
        --prefix "${OUT}/genetrees/${og}" -quiet
done

# 4. Concatenate alignments and infer species tree
bv exec seqkit concat "${OUT}/trim"/*.aln > "${OUT}/concat.aln"
bv exec iqtree2 -s "${OUT}/concat.aln" -m MFP -B 1000 -T "${THREADS}" \
    --prefix "${OUT}/species_tree"

echo "done: ${OUT}/species_tree.treefile"

#!/usr/bin/env bash
set -euo pipefail

SAMPLE="${1:?sample id required}"
THREADS="${THREADS:-16}"
OUT="out/${SAMPLE}"
mkdir -p "${OUT}"

bv exec fastp \
    -i "data/${SAMPLE}_1.fq.gz" -I "data/${SAMPLE}_2.fq.gz" \
    -o "${OUT}/trim_1.fq.gz" -O "${OUT}/trim_2.fq.gz" \
    --thread "${THREADS}" --json "${OUT}/fastp.json"

bv exec spades.py \
    -1 "${OUT}/trim_1.fq.gz" -2 "${OUT}/trim_2.fq.gz" \
    --only-assembler -t "${THREADS}" -o "${OUT}/spades"

ASM="${OUT}/spades/scaffolds.fasta"

bv exec bakta --output "${OUT}/bakta" --threads "${THREADS}" "${ASM}"
bv exec abricate "${ASM}" > "${OUT}/abricate.tsv"
bv exec amrfinder -n "${ASM}" --threads "${THREADS}" -o "${OUT}/amrfinder.tsv"
bv exec rgi main -i "${ASM}" -o "${OUT}/rgi" -t contig --clean

bv exec multiqc "${OUT}" -o "${OUT}/multiqc"
echo "done: ${OUT}"

#!/usr/bin/env bash
set -euo pipefail

SAMPLE="${1:?sample id required}"
THREADS="${THREADS:-8}"
INDEX="data/salmon_index"
OUT="out/${SAMPLE}"
mkdir -p "${OUT}"

bv exec fastp \
    -i "data/${SAMPLE}_1.fq.gz" -I "data/${SAMPLE}_2.fq.gz" \
    -o "${OUT}/trim_1.fq.gz"    -O "${OUT}/trim_2.fq.gz" \
    --json "${OUT}/fastp.json" --html "${OUT}/fastp.html" \
    --thread "${THREADS}"

bv exec salmon quant \
    -i "${INDEX}" -l A \
    -1 "${OUT}/trim_1.fq.gz" -2 "${OUT}/trim_2.fq.gz" \
    --validateMappings --gcBias --seqBias \
    -p "${THREADS}" -o "${OUT}/salmon"

bv exec multiqc "${OUT}" -o "${OUT}/multiqc"

echo "done: ${OUT}/salmon/quant.sf"

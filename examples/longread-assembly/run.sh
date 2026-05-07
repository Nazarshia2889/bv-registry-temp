#!/usr/bin/env bash
set -euo pipefail

THREADS="${THREADS:-16}"
OUT="out"
mkdir -p "${OUT}"

# 1. Filter reads (length and quality)
bv exec chopper -l 1000 -q 10 --threads "${THREADS}" \
    < data/reads.fq.gz > "${OUT}/reads.filt.fq"
gzip -f "${OUT}/reads.filt.fq"

# 2. Assemble with Flye
bv exec flye --nano-raw "${OUT}/reads.filt.fq.gz" \
    --threads "${THREADS}" -o "${OUT}/flye"

# 3. Map reads to draft, polish with medaka
bv exec minimap2 -ax map-ont -t "${THREADS}" \
    "${OUT}/flye/assembly.fasta" "${OUT}/reads.filt.fq.gz" \
  | bv exec samtools sort -@ "${THREADS}" -o "${OUT}/aln.bam" -
bv exec samtools index "${OUT}/aln.bam"

bv exec medaka_consensus \
    -i "${OUT}/reads.filt.fq.gz" \
    -d "${OUT}/flye/assembly.fasta" \
    -o "${OUT}/medaka" -t "${THREADS}"

# 4. QC
bv exec busco -i "${OUT}/medaka/consensus.fasta" \
    -o "${OUT}/busco" -m genome -l bacteria_odb10 -c "${THREADS}"

bv exec quast "${OUT}/medaka/consensus.fasta" -o "${OUT}/quast" \
    -t "${THREADS}" ${QUAST_REF:+-r "${QUAST_REF}"}

echo "done: ${OUT}/medaka/consensus.fasta"

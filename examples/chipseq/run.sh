#!/usr/bin/env bash
set -euo pipefail

CHIP="${1:?path to ChIP FASTQ required}"
INPUT="${2:?path to input FASTQ required}"
GENOME_INDEX="${GENOME_INDEX:?bowtie2 index prefix required}"
GENOME_SIZE="${GENOME_SIZE:-hs}"
THREADS="${THREADS:-8}"
OUT="out"
mkdir -p "${OUT}"

for tag in chip input; do
    src=$([ "${tag}" = chip ] && echo "${CHIP}" || echo "${INPUT}")
    bv exec fastp -i "${src}" -o "${OUT}/${tag}_trim.fq.gz" \
        --thread "${THREADS}" --json "${OUT}/${tag}_fastp.json"

    bv exec bowtie2 -x "${GENOME_INDEX}" -U "${OUT}/${tag}_trim.fq.gz" \
        -p "${THREADS}" --very-sensitive \
      | bv exec samtools sort -@ "${THREADS}" -o "${OUT}/${tag}.bam" -
    bv exec samtools index "${OUT}/${tag}.bam"

    bv exec picard MarkDuplicates -I "${OUT}/${tag}.bam" \
        -O "${OUT}/${tag}.dedup.bam" -M "${OUT}/${tag}.dups.txt" \
        --REMOVE_DUPLICATES true
    bv exec samtools index "${OUT}/${tag}.dedup.bam"
done

bv exec macs3 callpeak \
    -t "${OUT}/chip.dedup.bam" -c "${OUT}/input.dedup.bam" \
    -f BAM -g "${GENOME_SIZE}" \
    -n "${OUT}/peaks" --outdir "${OUT}/macs3" -q 0.01

bv exec bamCoverage -b "${OUT}/chip.dedup.bam" \
    -o "${OUT}/chip.bw" --normalizeUsing RPGC \
    --effectiveGenomeSize 2913022398 -p "${THREADS}"

bv exec findMotifsGenome.pl "${OUT}/macs3/peaks_peaks.narrowPeak" \
    "${GENOME_INDEX}.fa" "${OUT}/motifs" -size 200 -mask -p "${THREADS}"

bv exec multiqc "${OUT}" -o "${OUT}/multiqc"
echo "done: ${OUT}/macs3/peaks_peaks.narrowPeak"

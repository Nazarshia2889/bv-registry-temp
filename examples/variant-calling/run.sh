#!/usr/bin/env bash
# usage: ./run.sh <sample_id>
set -euo pipefail

SAMPLE="${1:?sample id required}"
REF="data/ref.fa"
THREADS="${THREADS:-8}"
OUT="out/${SAMPLE}"
mkdir -p "${OUT}"

# 1. QC + adapter trim
bv exec fastp \
    -i "data/${SAMPLE}_1.fq.gz" -I "data/${SAMPLE}_2.fq.gz" \
    -o "${OUT}/trim_1.fq.gz"    -O "${OUT}/trim_2.fq.gz" \
    --json "${OUT}/fastp.json"  --html "${OUT}/fastp.html" \
    --thread "${THREADS}"

# 2. Map (bwa-mem2 + sort to BAM)
bv exec bwa-mem2 mem -t "${THREADS}" \
    -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tLB:lib1\tPL:ILLUMINA" \
    "${REF}" "${OUT}/trim_1.fq.gz" "${OUT}/trim_2.fq.gz" \
  | bv exec samtools sort -@ "${THREADS}" -o "${OUT}/sorted.bam" -
bv exec samtools index "${OUT}/sorted.bam"

# 3. Mark duplicates
bv exec picard MarkDuplicates \
    -I "${OUT}/sorted.bam" \
    -O "${OUT}/dedup.bam" \
    -M "${OUT}/dup_metrics.txt"
bv exec samtools index "${OUT}/dedup.bam"

# 4. Call variants (single-sample; for joint calling, run HC in GVCF mode per
#    sample then GenotypeGVCFs across the cohort).
bv exec gatk HaplotypeCaller \
    -R "${REF}" \
    -I "${OUT}/dedup.bam" \
    -O "${OUT}/raw.vcf.gz"

# 5. Normalize and basic filter
bv exec bcftools norm -f "${REF}" "${OUT}/raw.vcf.gz" -Oz -o "${OUT}/norm.vcf.gz"
bv exec bcftools filter -e 'QUAL<30 || INFO/DP<10' "${OUT}/norm.vcf.gz" \
    -Oz -o "${OUT}/filtered.vcf.gz"
bv exec bcftools index -t "${OUT}/filtered.vcf.gz"

# 6. Annotate
bv exec vep \
    --input_file "${OUT}/filtered.vcf.gz" \
    --output_file "${OUT}/annotated.vcf.gz" \
    --vcf --compress_output bgzip \
    --cache --offline --everything

# 7. QC report
bv exec multiqc "${OUT}" -o "${OUT}/multiqc"

echo "done: ${OUT}/annotated.vcf.gz"

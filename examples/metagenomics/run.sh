#!/usr/bin/env bash
set -euo pipefail

SAMPLE="${1:?sample id required}"
THREADS="${THREADS:-16}"
OUT="out/${SAMPLE}"
KRAKEN_DB="${KRAKEN_DB:-${HOME}/.cache/bv/kraken2-standard}"
mkdir -p "${OUT}"

# 1. QC + trim
bv exec fastp \
    -i "data/${SAMPLE}_1.fq.gz" -I "data/${SAMPLE}_2.fq.gz" \
    -o "${OUT}/trim_1.fq.gz" -O "${OUT}/trim_2.fq.gz" \
    --thread "${THREADS}" --json "${OUT}/fastp.json"

# 2. Read-based taxonomy
bv exec kraken2 --db "${KRAKEN_DB}" --paired --threads "${THREADS}" \
    --output "${OUT}/kraken.out" --report "${OUT}/kraken.report" \
    "${OUT}/trim_1.fq.gz" "${OUT}/trim_2.fq.gz"
bv exec bracken -d "${KRAKEN_DB}" -i "${OUT}/kraken.report" \
    -o "${OUT}/bracken.tsv" -r 150 -l S

# 3. Marker-based taxonomy + function
bv exec metaphlan "${OUT}/trim_1.fq.gz","${OUT}/trim_2.fq.gz" \
    --bowtie2out "${OUT}/metaphlan.bz2" \
    --nproc "${THREADS}" --input_type fastq \
    -o "${OUT}/metaphlan.tsv"
bv exec humann --input "${OUT}/trim_1.fq.gz" --output "${OUT}/humann" \
    --threads "${THREADS}"

# 4. Assemble + bin + QC MAGs
bv exec megahit \
    -1 "${OUT}/trim_1.fq.gz" -2 "${OUT}/trim_2.fq.gz" \
    -o "${OUT}/megahit" -t "${THREADS}"

bv exec bwa-mem2 index "${OUT}/megahit/final.contigs.fa"
bv exec bwa-mem2 mem -t "${THREADS}" "${OUT}/megahit/final.contigs.fa" \
    "${OUT}/trim_1.fq.gz" "${OUT}/trim_2.fq.gz" \
  | bv exec samtools sort -@ "${THREADS}" -o "${OUT}/contigs.bam" -
bv exec samtools index "${OUT}/contigs.bam"

bv exec jgi_summarize_bam_contig_depths \
    --outputDepth "${OUT}/depth.txt" "${OUT}/contigs.bam"
bv exec metabat2 -i "${OUT}/megahit/final.contigs.fa" \
    -a "${OUT}/depth.txt" -o "${OUT}/bins/bin"

bv exec checkm2 predict --threads "${THREADS}" \
    --input "${OUT}/bins" --extension fa \
    --output-directory "${OUT}/checkm2"

bv exec gtdbtk classify_wf \
    --genome_dir "${OUT}/bins" --extension fa \
    --out_dir "${OUT}/gtdbtk" --cpus "${THREADS}" --skip_ani_screen

# 5. Annotate the highest-quality MAG
TOP_BIN=$(awk -F'\t' '$2>=90 && $3<=5 {print $1}' \
    "${OUT}/checkm2/quality_report.tsv" | head -n 1 || true)
if [ -n "${TOP_BIN}" ]; then
    bv exec bakta --output "${OUT}/bakta_${TOP_BIN}" \
        --threads "${THREADS}" "${OUT}/bins/${TOP_BIN}.fa"
fi

bv exec multiqc "${OUT}" -o "${OUT}/multiqc"
echo "done: ${OUT}"

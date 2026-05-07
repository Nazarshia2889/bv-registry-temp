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

bv exec megahit -1 "${OUT}/trim_1.fq.gz" -2 "${OUT}/trim_2.fq.gz" \
    -o "${OUT}/megahit" -t "${THREADS}"

CONTIGS="${OUT}/megahit/final.contigs.fa"
bv exec bwa-mem2 index "${CONTIGS}"
bv exec bwa-mem2 mem -t "${THREADS}" "${CONTIGS}" \
    "${OUT}/trim_1.fq.gz" "${OUT}/trim_2.fq.gz" \
  | bv exec samtools sort -@ "${THREADS}" -o "${OUT}/contigs.bam" -
bv exec samtools index "${OUT}/contigs.bam"

bv exec jgi_summarize_bam_contig_depths \
    --outputDepth "${OUT}/depth.txt" "${OUT}/contigs.bam"
bv exec metabat2 -i "${CONTIGS}" -a "${OUT}/depth.txt" \
    -o "${OUT}/bins/bin"

bv exec checkm2 predict --threads "${THREADS}" \
    --input "${OUT}/bins" --extension fa \
    --output-directory "${OUT}/checkm2"

bv exec dRep dereplicate "${OUT}/drep" \
    -g "${OUT}/bins"/*.fa \
    --S_algorithm fastANI -p "${THREADS}"

bv exec gtdbtk classify_wf \
    --genome_dir "${OUT}/drep/dereplicated_genomes" --extension fa \
    --out_dir "${OUT}/gtdbtk" --cpus "${THREADS}" --skip_ani_screen

# Annotate MAGs that pass the paper's high-quality threshold
# (completeness >= 90, contamination <= 5).
awk -F'\t' 'NR>1 && $2>=90 && $3<=5 {print $1}' \
    "${OUT}/checkm2/quality_report.tsv" \
  | while read bin; do
    bv exec bakta --output "${OUT}/bakta_${bin}" \
        --threads "${THREADS}" "${OUT}/bins/${bin}.fa" || true
done

echo "done: ${OUT}/checkm2/quality_report.tsv"

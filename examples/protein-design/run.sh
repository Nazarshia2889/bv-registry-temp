#!/usr/bin/env bash
set -euo pipefail

OUT="out"
mkdir -p "${OUT}/mpnn" "${OUT}/colabfold" "${OUT}/scores" "${OUT}/designs"

NUM_SEQS="${NUM_SEQS:-32}"
TEMP="${TEMP:-0.1}"

# 1. Design sequences for the backbone
bv exec protein_mpnn_run.py \
    --pdb_path data/backbone.pdb \
    --out_folder "${OUT}/mpnn" \
    --num_seq_per_target "${NUM_SEQS}" \
    --sampling_temp "${TEMP}" \
    --batch_size 8

# 2. Pull sequences out of the MPNN .fa
bv exec seqkit seq -i "${OUT}/mpnn/seqs/backbone.fa" \
    > "${OUT}/designs.fa"

# 3. Fold each design with ColabFold
bv exec colabfold_batch \
    "${OUT}/designs.fa" "${OUT}/colabfold" \
    --num-recycle 3 --model-type alphafold2_ptm

# 4. Score TM-alignment to target
: > "${OUT}/scores/tmscores.tsv"
for pdb in "${OUT}"/colabfold/*_unrelaxed_rank_001*.pdb; do
    name=$(basename "${pdb}" .pdb)
    score=$(bv exec USalign "${pdb}" data/target.pdb \
              | awk '/TM-score/{print $2; exit}')
    echo -e "${name}\t${score}" >> "${OUT}/scores/tmscores.tsv"
done

# 5. Filter top designs (TM > 0.7) and search foldseek for natural homologs
awk -F'\t' '$2>0.7 {print $1}' "${OUT}/scores/tmscores.tsv" \
    | while read name; do
    cp "${OUT}/colabfold/${name}.pdb" "${OUT}/designs/${name}.pdb"
done

if [ -n "${FOLDSEEK_DB:-}" ]; then
    bv exec foldseek easy-search "${OUT}/designs/" "${FOLDSEEK_DB}" \
        "${OUT}/foldseek_hits.tsv" "${OUT}/foldseek_tmp" \
        --format-output "query,target,prob,evalue,alntmscore"
fi

echo "done: top designs in ${OUT}/designs/"

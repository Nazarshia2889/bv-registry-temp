#!/usr/bin/env bash
set -euo pipefail

NUM_SEQS="${NUM_SEQS:-8}"
TEMP="${TEMP:-0.1}"
THREADS="${THREADS:-16}"
OUT="out"
FOLDSEEK_DB="${FOLDSEEK_DB:-${HOME}/.cache/bv/foldseek-afdb}"
mkdir -p "${OUT}"/{mpnn,colabfold,scores,success,foldseek}

for bb in data/backbones/*.pdb; do
    name=$(basename "${bb}" .pdb)

    bv exec protein_mpnn_run.py \
        --pdb_path "${bb}" \
        --out_folder "${OUT}/mpnn/${name}" \
        --num_seq_per_target "${NUM_SEQS}" \
        --sampling_temp "${TEMP}" --batch_size 1

    bv exec colabfold_batch \
        "${OUT}/mpnn/${name}/seqs/${name}.fa" \
        "${OUT}/colabfold/${name}" \
        --num-recycle 3 --model-type alphafold2_ptm

    : > "${OUT}/scores/${name}.tsv"
    for pred in "${OUT}/colabfold/${name}/${name}_unrelaxed_rank_001"*.pdb; do
        plddt=$(awk '$1=="REMARK"&&$2=="pLDDT"{print $3}' "${pred}" | head -1)
        tm=$(bv exec USalign "${pred}" "${bb}" 2>/dev/null \
              | awk '/^TM-score/{print $2; exit}')
        echo -e "${name}\t$(basename ${pred} .pdb)\t${tm}\t${plddt}" \
            >> "${OUT}/scores/${name}.tsv"
    done
done

cat "${OUT}/scores"/*.tsv \
  | awk -F'\t' '$3>0.7 && $4>80 {print}' \
  > "${OUT}/success/success.tsv"

awk -F'\t' '{print $1"_"$2}' "${OUT}/success/success.tsv" \
  | while read pose; do
    name=${pose%_*}
    pred=${pose#*_}
    cp "${OUT}/colabfold/${name}/${pred}.pdb" "${OUT}/success/${pose}.pdb"
done

if [ -d "${FOLDSEEK_DB}" ]; then
    bv exec foldseek easy-search "${OUT}/success/" "${FOLDSEEK_DB}" \
        "${OUT}/foldseek/hits.tsv" "${OUT}/foldseek_tmp" \
        --format-output "query,target,prob,evalue,alntmscore" \
        --threads "${THREADS}"
fi

echo "done: ${OUT}/success/  ($(wc -l < ${OUT}/success/success.tsv) successes)"

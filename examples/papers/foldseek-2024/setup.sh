#!/usr/bin/env bash
# Download SCOPe40 v2.01 inputs (PDBs + family FASTAs).
set -euo pipefail
mkdir -p data/scope40
cd data/scope40

if [ ! -f pdb.tar.gz ]; then
    curl -fsSL -o pdb.tar.gz \
      "https://scop.berkeley.edu/downloads/scopeseq-2.01/astral-scopedom-seqres-gd-sel-gs-bib-40-2.01.fa"
fi

# NB: a full SCOPe40 PDB dump requires registration; this stub only
# downloads the FASTA. Consult the paper's data-availability statement
# for the exact PDB tarball used in the benchmark.

echo "After download, expand pdb.tar.gz into data/scope40/pdb/"

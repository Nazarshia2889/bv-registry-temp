# Paper-port shortlist

Candidate papers whose pipelines port cleanly to bv. Criteria:

1. The science is multi-tool. The port composes several bv tools rather
   than wrapping the paper's own tool only.
2. Public input data. The port is reproducible end-to-end.
3. Either seminal/foundational or recent high-impact (Nature/Cell/Science/NMeth).

## Drafted

### 1. Foldseek - *van Kempen et al. 2024, Nat Biotechnol*
**"Fast and accurate protein structure search with Foldseek"**

Reproduces the SCOPe40 benchmark: fold queries with ColabFold, search with
Foldseek and MMseqs2, ground-truth with US-align. Uses
`colabfold`, `foldseek`, `mmseqs2`, `tmalign`, `usalign`.

See `examples/papers/foldseek-2024/`.

### 2. RFdiffusion - *Watson et al. 2023, Nature* (validation half)
**"De novo design of protein structure and function with RFdiffusion"**

Runs the design loop downstream of RFdiffusion: ProteinMPNN sequence
design, ColabFold folding, TM-score / pLDDT filter, Foldseek novelty
search. Uses `proteinmpnn`, `colabfold`, `foldseek`, `tmalign`, `usalign`.

See `examples/papers/rfdiffusion-2023/`.

### 3. CheckM2 - *Chklovski et al. 2023, Nat Methods*
**"CheckM2: a rapid, scalable and accurate tool for assessing microbial
genome quality using machine learning"**

Reproduces the MAG quality benchmark: assemble, bin, score with CheckM2,
dereplicate, place in GTDB, and annotate. Uses `fastp`, `megahit`,
`bwa-mem2`, `metabat2`, `checkm2`, `drep`, `gtdb-tk`, `bakta`, `samtools`.

See `examples/papers/checkm2-2023/`.

### 4. Nextstrain - *Hadfield et al. 2018, Bioinformatics*
**"Nextstrain: real-time tracking of pathogen evolution"**

Reproduces the alignment + tree + dating layer that augur orchestrates.
Replaces augur with direct bv exec calls so every step is pinned. Uses
`mafft`, `iqtree2`, `treetime`, `nextclade`, `minimap2`, `mash`, `seqkit`,
`samtools`.

See `examples/papers/nextstrain-2018/`.

## Candidates not yet drafted

The criteria above rule out paper ports whose only point is to introduce a
single tool already in the registry (Bakta, AlphaFold2, ProteinMPNN,
hifiasm). Those papers don't add reproducibility value beyond running the
tool itself.

Open candidates with multi-tool pipelines:

- **Tara Oceans microbial reference catalogue** - *Sunagawa et al. 2015,
  Science*. Microbiome assembly + annotation at scale. Tools: `bowtie2`,
  `megahit`, `metabat2`, `bakta`, `humann`, `gtdb-tk`. Heavy on data; the
  port runs on a single Tara station's read set.
- **GATK germline best-practices** - *Van der Auwera and O'Connor 2020*.
  Already covered by `examples/variant-calling/`. A papers/ version pins
  the exact NA12878 chromosome-22 benchmark.
- **ESM-Atlas / metagenomic protein folding** - *Lin et al. 2023, Science*.
  Folds metagenomic proteins at scale with ESMFold, structurally clusters
  with foldseek. Tools: `fair-esm`, `foldseek`, `mmseqs2`. Covered by the
  registry's new `fair-esm` tool.
- **Earth Microbiome Project / 16S meta-analysis** - *Thompson et al.
  2017, Nature*. 16S taxonomy across thousands of samples. Tools: `qiime2`
  (not yet in registry), `vsearch` (not yet in registry), `mafft`,
  `iqtree2`. Add the missing tools first, then port.
- **HOMER ChIP-seq / motif discovery** - *Heinz et al. 2010, Mol Cell*.
  Already covered by `examples/chipseq/`. A papers/ version reproduces the
  motif analysis on the published macrophage dataset.

## How a port lands

1. Branch, drop a directory under `examples/papers/<short-name>/`.
2. Pin tools in `bv.toml`. Run `bv lock --check` in CI.
3. Author `README.md` (citation + scope), `run.sh` (executable steps),
   and `setup.sh` if the data isn't trivial to fetch.
4. Open a PR. The maintainer rebuilds the registry tools as needed.

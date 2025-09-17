#!/usr/bin/env bash
set -euo pipefail

# Requirements: hmmer, unzip, wget; seqkit optional (falls back to awk)
# Usage: bash hmm.sh  [threads]
THREADS="${1:-8}"

WORKDIR="${PWD}/hop_mlo_run"
mkdir -p "$WORKDIR" && cd "$WORKDIR"

# 1) Hop proteome from NCBI
datasets download genome accession GCF_963169125.1 --include protein --filename hop.zip
unzip -q -o hop.zip
PROT_FASTA="$(find ncbi_dataset/data -type f -name '*.faa' | head -n1)"
[ -s "$PROT_FASTA" ] || { echo "[ERROR] No .faa found"; exit 1; }

# 2) Get PF03094 HMM (two safe options)

# Option A: extract from full Pfam (bigger download, but reliable)
if [ ! -s PF03094.hmm ]; then
  wget -q https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
  gunzip -c Pfam-A.hmm.gz > Pfam-A.hmm
  hmmfetch --index Pfam-A.hmm                              # build SSI for text HMM
  hmmfetch Pfam-A.hmm PF03094.20 > PF03094.hmm || hmmfetch Pfam-A.hmm Mlo > PF03094.hmm
fi
[ -s PF03094.hmm ] || { echo "[ERROR] PF03094.hmm not created"; exit 1; }

# 3) HMMER search
hmmsearch --cpu "$THREADS" -E 1e-5 --domE 1e-5 \
  --tblout mlo_hits.tbl PF03094.hmm "$PROT_FASTA" > mlo_hits.txt

awk '!/^#/{print $1}' mlo_hits.tbl | sort -u > mlo_ids.txt

# 4) Subset FASTA (seqkit if present, else awk)
if command -v seqkit >/dev/null 2>&1; then
  seqkit grep -n -f mlo_ids.txt "$PROT_FASTA" > english_hop_MLO_candidates.faa
else
  awk 'BEGIN{while((getline<"mlo_ids.txt")>0)ids[$1]=1}
       /^>/{split(substr($0,2),a,/[ \t]/); keep=(a[1] in ids)}
       {if(keep)print}' "$PROT_FASTA" > english_hop_MLO_candidates.faa
fi

echo "Done. Candidates: $(grep -c '^>' english_hop_MLO_candidates.faa)"
echo "Files: mlo_hits.tbl, mlo_ids.txt, english_hop_MLO_candidates.faa"

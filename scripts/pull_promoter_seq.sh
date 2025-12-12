#!/bin/bash
set -euo pipefail

GENOME="dovetailCascade10ScaffoldsUnmasked.fasta" # download from hop base
GENES_BED="genes.bed" # custom made file from hop base

# Output files
PROM_BED="hop_promoters_minus2000_to_plus5.bed"
PROM_FA="hop_promoters_minus2000_to_plus5.fa"

# Window sizes
UP=2000   # upstream of TSS
DOWN=5    # downstream of TSS

# 1) Build promoter BED (TSS -2000 to +5), strand-aware
#
# Assumes standard BED6+:
#   chrom  start  end  name  score  strand
# BED is 0-based, half-open: [start, end)
#
# TSS definition:
#   + strand: TSS = start
#   - strand: TSS = end
#
# Promoter intervals:
#   +: [TSS-UP, TSS+DOWN)
#   -: [TSS-DOWN, TSS+UP)
#
# Length (if not truncated at scaffold ends) = UP + DOWN = 2005 bp.

awk -v UP="$UP" -v DOWN="$DOWN" 'BEGIN{OFS="\t"}
  # Skip empty or comment lines; expect at least 6 columns
  $0 ~ /^#/ || NF < 6 { next }

  {
    chrom  = $1
    start  = $2
    end    = $3
    name   = $4
    score  = $5
    strand = $6

    if (strand == "+") {
      tss    = start
      pstart = tss - UP
      pend   = tss + DOWN
    } else if (strand == "-") {
      tss    = end
      pstart = tss - DOWN
      pend   = tss + UP
    } else {
      # skip entries with no valid strand
      next
    }

    # Clamp to chromosome start (no negative coords)
    if (pstart < 0) pstart = 0

    # You could also clamp pend to chrom length via bedtools slop/coverage,
    # but bedtools getfasta will handle overshoot by truncating at contig end.

    print chrom, pstart, pend, name, score, strand
  }
' "$GENES_BED" > "$PROM_BED"

echo "Wrote promoter BED: $PROM_BED"

# 2) Extract sequences, strand-aware
#
# -s     : respect strand and reverse-complement (-)
# -name+ : include coordinates in FASTA header (useful for debugging)
bedtools getfasta \
  -fi "$GENOME" \
  -bed "$PROM_BED" \
  -s \
  -name+ \
  -fo "$PROM_FA"

echo "Wrote promoter FASTA: $PROM_FA"

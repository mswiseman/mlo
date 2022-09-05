Many of these scripts were started from [here](https://github.com/tobjores/Synthetic-Promoter-Designs-Enabled-by-a-Comprehensive-Analysis-of-Plant-Core-Promoters/blob/main/promoter_annotation/extract_promoter_seqs.sh).

#!/bin/bash

requires:
- bedtools (version 2.29.2)
- bedops (version 2.4.35)
- R (version 4.0.0) with libraries:
-	 dplyr (version 1.0.0)
	-- tidyr (version 1.1.0)
	-- readr (version 1.3.1)
	-- tibble (version 3.0.1)


### download genomes and annotations ###
```sh
if [ ! -f "cascadeDovetail.fasta" ]; then
  curl http://hopbase.cqls.oregonstate.edu/content/cascadeDovetail/assemblyData/dovetailCascade10ScaffoldsUnmasked.fasta.gz | gunzip > dovetailCascade10ScaffoldsUnmasked.fasta
fi
if [ ! -f "cascadeDovetail.gff3" ]; then
  curl http://hopbase.cqls.oregonstate.edu/content/cascadeDovetail/geneData/transdecoder/transdecoderOutput/transcripts.fasta.transdecoder.genomeCentric.gff3.gz | gunzip | grep -v "^#" | sed 's/^Scaffold//g' > transcripts.fasta.transdecoder.genomeCentric.gff3.gff3
fi

```

### extract coordinates of the chromosomal genes ###
	```sh
	awk '{if($3 == "gene" && $1 ~ /[0-9]+/) print}' combinedGeneModels.fullAssembly.repeatFiltered.gff \
			| awk -v OFS='\t' '{print $1, $2, $3, $4, $5, $6, $7, $8, $9}' \
			> genes.gff111
	
	### generate bed file with promoter coordinates (+5 to -165) ###
	```sh
	awk -v OFS='\t' '{
		ID=substr($9, 4, index($9, ";") - 4);
		sub(/gene:/, "", ID);
		if($7 == "+") {print $1, ($4 - 166), ($4 + 4), ID, 0, $7}
		else if($7 == "-") {print $1, ($5 - 5), ($5 + 165), ID, 0, $7}
	}' genes.gff | awk '$2 >= 0' > Humulus_protein_coding_promoters.bed
	
	```
	
	### for longer analyses (+5 to -2000) ###
	```sh
	awk -v OFS='\t' '{
		ID=substr($9, 4, index($9, ";") - 4);
		sub(/gene:/, "", ID);if($7 == "+") {print $1, ($4 - 2000), ($4 + 4), ID, 0, $7}
		else if($7 == "-") {print $1, ($5 - 5), ($5 + 2000), ID, 0, $7}
		}' genes.gff | awk '$2 >= 0' > Humulus_protein_coding_promoters2k.bed
		
		```

	### get fasta sequences ###
	```sh
	echo' bedtools getfasta -s -nameOnly -fi dovetailCascade10ScaffoldsUnmasked.fasta -bed  Humulus_protein_coding_promoters.bed> Humulus_protein_coding_promoters.fasta' > sge.promoter1
	bedtools getfasta -s -nameOnly -fi dovetailCascade10ScaffoldsUnmasked.fasta -bed  Humulus_protein_coding_promoters2k.bed> Humulus_protein_coding_promoters2k.fasta > sge.promoter2
	```
	
	```sh
	SGE_Array -c sge.promoter1 -r SGE_promoterSeq -p 32 
	```

	
### To just look at MLO promoters, make a list of MLO geneIDs and run the following ###
seqtk subseq Humulus_protein_coding_promoters3.fasta dovetailMloList > mloPromoters.fasta

### identify protein-coding genes without an annotated 5' UTR (TSS = first base of CDS) ###
awk -v FS='[\t;]' -v OFS='\t' '$3 == "CDS" {sub("ID=", "", $9); print $1, $4 - 1, $5, $9, $6, $7}' Humulus_annotation.gff3 \
| sort-bed - > ${SPECIES}_CDS.bed

	awk -v FS='[\t;]' -v OFS='\t' '$4 < $5 {sub("ID=(gene:)?", "", $9); print $1, $4 - 1, $5, $9, $6, $7}' Humulus_protein_coding_genes.gff3 \
		| sort-bed - > Humulus_protein_coding_genes.bed

	bedmap --echo --echo-map-range --delim '\t' Humulus_protein_coding_genes.bed Humulus_CDS.bed \
		| awk -v OFS='\t' -v species=Humulus} '{
			print $1, $8, $9, $4, $5, $6;
			if (($6 == "+" && $2 == $8) || ($6 == "-" && $3 == $9)) print $4 > species"_noUTR.txt"
		}' > Humulus_CDS-range.bed
	
done


### Correct a "K" nucleotide in the promoter of AT2G39050 ###
sed -i 's/K/T/g' Arabidopsis_all_promoters.tsv


### collapse identical sequences and create reference sequences ###
Rscript unique_promoters.R

#!/usr/bin/env Rscript

library(readr)
library(dplyr)

for (species in c('Humulus', 'Cannabis')) {
  noUTR <- read_lines(paste0(species, '_noUTR.txt'))

  promoters <- read_tsv(paste0(species, '_all_promoters.tsv')) %>%
    mutate(
      UTR = (! gene %in% noUTR)
    ) %>%
    group_by(sequence, type, strand, mutations) %>%
    summarise(
      gene = paste0(gene, collapse = ';'),
      UTR = all(UTR)
    ) %>%
    ungroup() %>%
    group_by(sequence) %>%
    summarise(
      across(-UTR, ~if_else(n_distinct(.x) == 2, paste0(.x, collapse = '/'), first(.x))),
      UTR = all(UTR)
    ) %>%
    ungroup() %>%
    select(gene, type, sequence, strand, UTR, mutations) %>%
    arrange(gene)
  
  write_tsv(promoters, paste0(species, '_all_promoters_unique.tsv'), na = '')

  fasta <- promoters %>%
    select(gene, sequence) %>%
    bind_rows(c(gene = '35Spr', sequence = 'GCAAGACCCTTCCTCTATATAAGGAAGTTCATTTCATTTGGAGAGGACACG')) %>%
    mutate(
      gene = paste0('>', gene)
    ) %>%
    select(gene, sequence)

  write_delim(fasta, paste0(species, '_all_promoters_unique.fa'), delim = '\n', col_names = FALSE)

  assign(species, promoters)
}

all.promoters <- bind_rows(Humulus, Cannabis) %>%
  select(gene, sequence) %>%
  bind_rows(c(gene = '35Spr', sequence = 'GCAAGACCCTTCCTCTATATAAGGAAGTTCATTTCATTTGGAGAGGACACG')) %>%
  mutate(
    gene = paste0('>', gene)
  ) %>%
  select(gene, sequence)

write_delim(all.promoters, 'all_promoters_unique.fa', delim = '\n', col_names = FALSE)
Footer


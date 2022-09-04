#!/bin/bash

# requires:
#	- bedtools (version 2.29.2)
#	- bedops (version 2.4.35)
#	- R (version 4.0.0) with libraries:
#		- dplyr (version 1.0.0)
#		- tidyr (version 1.1.0)
#		- readr (version 1.3.1)
#		- tibble (version 3.0.1)


### download genomes and annotations ###
if [ ! -f "cascadeDovetail.fasta" ]; then
  curl http://hopbase.cqls.oregonstate.edu/content/cascadeDovetail/assemblyData/dovetailCascade10ScaffoldsUnmasked.fasta.gz | gunzip > cascadeDovetail.fa
fi
if [ ! -f "cascadeDovetail.gff3" ]; then
  curl http://hopbase.cqls.oregonstate.edu/content/cascadeDovetail/geneData/transdecoder/transdecoderOutput/transcripts.fasta.transdecoder.genomeCentric.gff3.gz | gunzip | grep -v "^#" | sed 's/^Scaffold//g' > transcripts.fasta.transdecoder.genomeCentric.gff3.gff3
fi


### get promoter sequences for Arabidopsis, maize, and sorghum ###
for SPECIES in "Humulus"
do

	### extract coordinates of the chromosomal genes ###
awk '{if($3 == "gene" && $1 ~ /[0-9]+/) print}' Humulus_annotation.gff3 \
			| grep "type=mRNA" \
			| awk -v OFS='\t' '{print $1, $2, $3, $4, $5, $6, $7, $8, $9}' \
			> Humulus_mRNA_genes.gff3
	
	### generate bed file with promoter coordinates (+5 to -165) ###
	if [ ${SPECIES} = 'Maize' ]
	then
		Rscript correct_Maize_TSSs.R
	fi
	
	awk -v OFS='\t' '{
		ID=substr($9, 4, index($9, ";") - 4);
		sub(/gene:/, "", ID);
		if($7 == "+") {print $1, ($4 - 166), ($4 + 4), ID, 0, $7}
		else if($7 == "-") {print $1, ($5 - 5), ($5 + 165), ID, 0, $7}
	}' Humulus_protein_coding_genes.gff3 | awk '$2 >= 0' > ${SPECIES}_protein_coding_promoters.bed

	awk -v OFS='\t' '{
		ID=substr($9, 4, index($9, ";") - 4);
		sub(/gene:/, "", ID);
		if($7 == "+") {print $1, ($4 - 166), ($4 + 4), ID, 0, $7}
		else if($7 == "-") {print $1, ($5 - 5), ($5 + 165), ID, 0, $7}
	}' ${SPECIES}_miRNA_genes.gff3 | awk '$2 >= 0' > ${SPECIES}_miRNA_promoters.bed


	### get fasta sequences ###
	bedtools getfasta -s -nameOnly -fi cascadeDovetail.fa -bed Humulus_protein_coding_genes.gff3 > Humulus_protein_coding_promoters.fasta
	
	bedtools getfasta -s -nameOnly -fi cascadeDovetail.fa -bed Humulus_mRNA_promoters.bed > Humulus_mRNA_promoters.fasta

	
	### mutate BsaI (GGTCTC/GAGACC)/BbsI (GAAGAC/GTCTTC) sites and list mutations (T>A in BsaI fwd; A>T in BsaI rev; G>C in BbsI fwd; C>G in BbsI rev) ###
	awk -v OFS='\t' 'BEGIN{print "gene", "type", "sequence", "strand", "mutations"} {
	  GENE=substr($1, 2, index($1, "(") - 2); STRAND=substr($1, index($1, "(") + 1, 1);
	  getline;
	  if($1 !~ /N/) {
		SEQ=$1; MUT="";
		while(index(SEQ, "GGTCTC") > 0) {MUT=MUT index(SEQ, "GGTCTC") + 2 "T>A;"; sub(/GGTCTC/, "GGACTC", SEQ)};
		while(index(SEQ, "GAGACC") > 0) {MUT=MUT index(SEQ, "GAGACC") + 3 "A>T;"; sub(/GAGACC/, "GAGTCC", SEQ)};
		while(index(SEQ, "GAAGAC") > 0) {MUT=MUT index(SEQ, "GAAGAC") + 3 "G>C;"; sub(/GAAGAC/, "GAACAC", SEQ)};
		while(index(SEQ, "GTCTTC") > 0) {MUT=MUT index(SEQ, "GTCTTC") + 2 "C>G;"; sub(/GTCTTC/, "GTGTTC", SEQ)};
		sub(/;$/, "", MUT);
		print GENE, "protein_coding", SEQ, STRAND, MUT
	  }
	}' ${SPECIES}_protein_coding_promoters.fasta > ${SPECIES}_all_promoters.tsv

	awk -v OFS='\t' '{
	  GENE=substr($1, 2, index($1, "(") - 2); STRAND=substr($1, index($1, "(") + 1, 1);
	  getline;
	  if($1 !~ /N/) {
		SEQ=$1; MUT="";
		while(index(SEQ, "GGTCTC") > 0) {MUT=MUT index(SEQ, "GGTCTC") + 2 "T>A;"; sub(/GGTCTC/, "GGACTC", SEQ)};
		while(index(SEQ, "GAGACC") > 0) {MUT=MUT index(SEQ, "GAGACC") + 3 "A>T;"; sub(/GAGACC/, "GAGTCC", SEQ)};
		while(index(SEQ, "GAAGAC") > 0) {MUT=MUT index(SEQ, "GAAGAC") + 3 "G>C;"; sub(/GAAGAC/, "GAACAC", SEQ)};
		while(index(SEQ, "GTCTTC") > 0) {MUT=MUT index(SEQ, "GTCTTC") + 2 "C>G;"; sub(/GTCTTC/, "GTGTTC", SEQ)};
		sub(/;$/, "", MUT);    
		print GENE, "miRNA", SEQ, STRAND, MUT
	  }
	}' ${SPECIES}_miRNA_promoters.fasta >> ${SPECIES}_all_promoters.tsv




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

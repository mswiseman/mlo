Many of these scripts were started from [here](https://github.com/tobjores/Synthetic-Promoter-Designs-Enabled-by-a-Comprehensive-Analysis-of-Plant-Core-Promoters/blob/main/promoter_annotation/extract_promoter_seqs.sh).

requires:
- bedtools (version 2.29.2)
- bedops (version 2.4.35)
- seqtk (version 1.3-r106)


Download genomes and annotations
```shell
if [ ! -f "cascadeDovetail.fasta" ]; then
  curl http://hopbase.cqls.oregonstate.edu/content/cascadeDovetail/assemblyData/dovetailCascade10ScaffoldsUnmasked.fasta.gz | gunzip > dovetailCascade10ScaffoldsUnmasked.fasta
fi
if [ ! -f "combinedGeneModels.fullAssembly.repeatFiltered.gff" ]; then
  curl http://hopbase.cqls.oregonstate.edu/content/cascadeDovetail/geneData/combinedGeneModels/combinedGeneModels.fullAssembly.gff.gz | gunzip | grep -v "^#" | sed 's/^Scaffold//g' > combinedGeneModels.fullAssembly.repeatFiltered.gff
fi
```

Extract coordinates of the chromosomal genes
```shell
	
awk '{if($3 == "gene" && $1 ~ /[0-9]+/) print}' combinedGeneModels.fullAssembly.repeatFiltered.gff \
		| awk -v OFS='\t' '{print $1, $2, $3, $4, $5, $6, $7, $8, $9}' \
		> genes.gff
			
```
	
Generate bed file with promoter coordinates (+5 to -165)
```shell
awk -v OFS='\t' '{
	ID=substr($9, 4, index($9, ";") - 4);
	sub(/gene:/, "", ID);
	if($7 == "+") {print $1, ($4 - 166), ($4 + 4), ID, 0, $7}
	else if($7 == "-") {print $1, ($5 - 5), ($5 + 165), ID, 0, $7}
}' genes.gff | awk '$2 >= 0' > Humulus_protein_coding_promoters.bed
```
	
For longer analyses (+5 to -2000)
```shell
awk -v OFS='\t' '{
	ID=substr($9, 4, index($9, ";") - 4);
	sub(/gene:/, "", ID);if($7 == "+") {print $1, ($4 - 2000), ($4 + 4), ID, 0, $7}
	else if($7 == "-") {print $1, ($5 - 5), ($5 + 2000), ID, 0, $7}
	}' genes.gff | awk '$2 >= 0' > Humulus_protein_coding_promoters2k.bed
```

Get fasta sequences
```shell
	echo 'bedtools getfasta -s -nameOnly -fi dovetailCascade10ScaffoldsUnmasked.fasta -bed  Humulus_protein_coding_promoters.bed > Humulus_protein_coding_promoters.fasta \
	bedtools getfasta -s -nameOnly -fi dovetailCascade10ScaffoldsUnmasked.fasta -bed  Humulus_protein_coding_promoters2k.bed > Humulus_protein_coding_promoters2k.fasta' > sge.promoter	
```

Submit through SGE_array
```shell	
SGE_Array -c sge.promoter -r SGE_promoterSeq -p 32 	
```

	
To just look at MLO promoters, make a list of MLO geneIDs and run 
```shell
seqtk subseq Humulus_protein_coding_promoters3.fasta dovetailMloList > mloPromoters.fasta
```

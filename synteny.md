#!/bin/bash

for i in `ls -1 *.bam| cut -c -17 |uniq`
do

echo " Running samtools"
samtools sort -@ 4 -o $i.sam.bam $i.sam

echo " Running stringtie"
stringtie -p 4 -e -G combinedGeneModels.fullAssembly.repeatFiltered.gff -o $i.gtf $i.sam.bam
done


####  agat  ####
 
# run conda from bash
`bash`

# enter agat env
`conda activate agat`

# pull out mapped sequences
agat_sp_extract_sequences.pl --cdna -gff cascade.HiFi.minimap2_shin.gtf --fasta shinshuwase_assembly.fa -o shin-cas.fa


#!/bin/bash

DIR=/Users/mswiseman/Desktop/MLO
FILES=${DIR}/*.fasta

for f in $FILES
do
  echo "Processing $f file..."
  # take action on each file. $f store current file name

  #0. Get filename
  filename=$(basename $f)

  # 1. MSA alignment
  #muscle -in $f -out ${f}.aln
  #prank -d=$f -o=${f}.aln -codon -F -f=phylip
  prank -d=$f -o=${f}.aln -codon -F

  # 2. Covert fasta file in Phylip format
  Fasta2Phylip.pl ${f}.aln.best.fas ${DIR}/${filename}.aln.best.phy

  # 3. Tree reconstruction
  phyml -i ${DIR}/${filename}.aln.best.phy -m 'GTR' -t 'e' -a 'e' -f 'm'

  # 4. Prepare control file codeml
  cp ${DIR}/codeml_template.txt ${DIR}/codeml_${filename}.ctl
  echo "seqfile = ${DIR}/${filename}.aln.best.phy" >> ${DIR}/codeml_${filename}.ctl
  echo "treefile = ${DIR}/${filename}.phy_phyml_tree.txt" >> ${DIR}/codeml_${filename}.ctl
  echo "outfile = ${DIR}/${filename}_fr.txt" >> ${DIR}/codeml_${filename}.ctl

  # 5. Execute codeml
  codeml ${DIR}/codeml_${filename}.ctl
done



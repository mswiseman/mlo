#!/bin/bash

for i in `ls -1 *.fastq| cut -c -17 |uniq`
do
  echo "Input: $i.fastq"
  echo "Counting reads"
  touch readcount.txt
  grep -c '@' $i.fastq >> readcount.txt

done

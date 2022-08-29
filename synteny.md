```sh
#!/bin/bash

for i in `ls -1 *.bam| cut -c -17 |uniq`
do

echo " Running samtools"
samtools sort -@ 4 -o $i.sam.bam $i.sam

echo " Running stringtie"
stringtie -p 4 -e -G combinedGeneModels.fullAssembly.repeatFiltered.gff -o $i.gtf $i.sam.bam
done
```

### Agat
 
Run conda from bash:

```bash```

Enter agat env:

```conda activate agat```

Either qrsh or SGE submit

```qrsh```

Pull out mapped sequences:

```agat_sp_extract_sequences.pl --cdna -gff myFolder/Hu_lup/other_cultivar_genomes/shin/cascade.HiFi.minimap2_shin.gtf --fasta myFolder/Hu_lup/other_cultivar_genomes/shin/Shinshuwase_assembly.fa -o shin-cas.fa```

```agat_sp_extract_sequences.pl --cdna -gff myFolder/Hu_lup/other_cultivar_genomes/teammaker/cascade.HiFi.minimap2_teamaker.gtf --fasta myFolder/Hu_lup/other_cultivar_genomes/teammaker/Teammaker_assembly.fa -o team-cas.fa```

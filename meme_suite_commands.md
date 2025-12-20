# Meme Suite Commands Used in this Study

```bash

meme cascade_mlos_aa.fasta -protein -oc . -nostatus -time 14400 -mod zoops -nmotifs 10 -minw 6 -maxw 50 -objfun de -neg combinedGeneModels.tenScaffolds_without_Mlos.pep.fasta -markov_order 0

meme sequences.fa -protein -oc . -nostatus -time 14400 -mod zoops -nmotifs 10 -minw 6 -maxw 50 -objfun de -neg control_sequences.fa -markov_order 0

tomtom -no-ssc -min-overlap 4 -dist pearson -evalue -thresh 1 -oc MEME_Results_CladeVMLOs_vs_allOtherMLOs_SurreySaazCascade_elm MEME_Results_CladeVMLOs_vs_allOtherMLOs_SurreySaazCascade.html motif_databases/PROTEIN/elm2024.meme

tomtom -no-ssc -min-overlap 4 -dist pearson -evalue -thresh 1 -oc MEME_Results_CascadeMLOs_vs_all_other_proteins_tomtom_elm MEME_Results_CascadeMLOs_vs_all_other_proteins.html   motif_databases/PROTEIN/elm2024.meme

sea --p MLO_promoters_minus2000_to_plus5_fixed.fa --n nonMLO_promoters_minus2000_to_plus5_fixed.fa -o mlo_in_silico_visualizations/seaout -m JASPAR_plants_2024.meme  --thresh 10.0 --verbosity 5

centrimo --oc centrimo_mlo_bg.out --neg nonMLO_promoters_minus500_to_plus200_fixed.fa MLO_promoters_minus500_to_plus200_fixed.fa JASPAR_plants_2024.meme

```

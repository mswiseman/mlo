SRA Download using [SRA-Toolkit](https://hpc.nih.gov/apps/sratoolkit.html).

## downloading SRA data

`printf 'SRR13528958\nSRR13528959\nSRR13528960\nSRR13066396\nSRR5832178\nSRR5832176\nSRR5832177\nSRR5832170\nSRR5832171\nSRR5832172\nSRR21169023' > accs.txt`

## ensure on file transfer server
`export TMPDIR=/tmp
cat accs.txt | parallel -j 4 prefetch`

## move to job submission server
`SGE_Batch -c "cat accs.txt | xargs -n 1 fasterq-dump -t /nfs5/BPP/Gent_Lab/home/wiseman/ncbi/tmp" -r sge.fasterq-dump -P 6`

## Gene Annotation of the Discradisca Antillarum Genome using Braker3:

The raw script **BRAKER3_piepline.sh** has more detail about defining file paths, but this README will go over the steps to recreate this analysis.

### Setup:

```bash

#Remove linebreaks from fasta files
awk '!/^>/ { printf "%s", $0; n = "\n" } 
/^>/ { print n $0; n = "" }
END { printf "%s", n }
' $GENOME > $GENOME.nent
mv $GENOME $GENOME.bak

awk '!/^>/ { printf "%s", $0; n = "\n" } 
/^>/ { print n $0; n = "" }
END { printf "%s", n }
' protein_evidence.fas > protein_evidence.fas.nent
mv protein_evidence.fas protein_evidence.fas.bak

rename 's/.nent//g' *.nent
```

### Make RepeatModeler database and run RepeatModeler:

```bash
#Make RepeatModeler database
BuildDatabase -engine rmblast -name repeats $GENOME


#Run RepeatModeler
RepeatModeler -pa $CORES -engine rmblast -LTRStruct -database repeats 2>&1 | tee repeatmodeler.log
```

### Filter transcriptome reads and then map to the genome:

```bash
#Quality filter and trim transcriptome reads
#May want to include these flags if data isn't awesome: --clip_R1 5 --clip_R2 5 --three_prime_clip_R1 5 --three_prime_$
trim_galore --cores $TRIM_GALORE_CORES --fastqc --quality 30 --length 50 --illumina --paired $FORWARD_READS $REVERSE_R$
gunzip *_val_1.fq.gz
gunzip *_val_2.fq.gz


#Make hisat2 index for masked genome
hisat2-build $GENOME".masked" index


#Map transcriptome reads to masked genome with hisat2
hisat2 -x index -1 *_val_1.fq -2 *_val_2.fq -S Aligned.out.sam


#Make BAM from SAM and get rid of SAM:
samtools view -bS Aligned.out.sam > RNAseq.bam
rm -rf *.sam

```

### Run BRAKER:

This is run using braker v.3.0.8.

```
perl /home/wirenia/bin/BRAKER-3.0.8/scripts/braker.pl --threads $CORES --softmasking --makehub --email kmkocot@ua.edu --gff3 --species $AUGUSTUS_SPECIES --prot_seq protein_evidence.fas --bam RNAseq.bam --genome $GENOME".masked"
```

### Run BUSCO to asses completness:

```
busco --cpu $CORES -m proteins -l metazoa_odb10 --download_path /home/wirenia/databases -i ./braker/braker.aa -o BUSCO_braker.aa
```


#https://github.com/Gaius-Augustus/BRAKER
#https://www.biostars.org/p/411101/
#Make sure to remove line breaks in sequences in protein_evidence.fas
#Make sure to remove whitespace in genome fasta header


#Set correct paths for GeneMark and Augustus 3.4.0
export AUGUSTUS_BIN_PATH=/home/wirenia/bin/Augustus-3.5.0/bin
export AUGUSTUS_SCRIPTS_PATH=/home/wirenia/bin/Augustus-3.5.0/scripts
export AUGUSTUS_CONFIG_PATH=/home/wirenia/bin/Augustus-3.5.0/config


#Define variables
GENOME=Discradisca_antillarum_collapsed_phased.fa
FORWARD_READS=XFTP_0040_1.fastq.gz
REVERSE_READS=XFTP_0040_2.fastq.gz
PROTEIN_EVIDENCE=protein_evidence.fas
AUGUSTUS_SPECIES=`date +%Y-%m-%d_%H.%M_$GENOME`
CORES=16
TRIM_GALORE_CORES=$(( CORES > 8 ? 8 : CORES ))


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


#Make RepeatModeler database
BuildDatabase -engine rmblast -name repeats $GENOME


#Run RepeatModeler
RepeatModeler -pa $CORES -engine rmblast -LTRStruct -database repeats 2>&1 | tee repeatmodeler.log


#Run RepeatMasker
cp ./*/consensi.fa.classified .
RepeatMasker -parallel $CORES -engine rmblast -gccalc -lib ./consensi.fa.classified $GENOME -xsmall


#Quality filter and trim transcriptome reads
#May want to include these flags if data isn't awesome: --clip_R1 5 --clip_R2 5 --three_prime_clip_R1 5 --three_prime_clip_R2 5 
trim_galore --cores $TRIM_GALORE_CORES --fastqc --quality 30 --length 50 --illumina --paired $FORWARD_READS $REVERSE_READS
gunzip *_val_1.fq.gz
gunzip *_val_2.fq.gz


#Make hisat2 index for masked genome
hisat2-build $GENOME".masked" index


#Map transcriptome reads to masked genome with hisat2
hisat2 -x index -1 *_val_1.fq -2 *_val_2.fq -S Aligned.out.sam


#Make BAM from SAM and get rid of SAM:
samtools view -bS Aligned.out.sam > RNAseq.bam
rm -rf *.sam


#Run BRAKER
#Don't use --crf
perl /home/wirenia/bin/BRAKER-3.0.8/scripts/braker.pl --threads $CORES --softmasking --makehub --email kmkocot@ua.edu --gff3 --species $AUGUSTUS_SPECIES --prot_seq protein_evidence.fas --bam RNAseq.bam --genome $GENOME".masked"


#Run BUSCO
busco --cpu $CORES -m proteins -l metazoa_odb10 --download_path /home/wirenia/databases -i ./braker/braker.aa -o BUSCO_braker.aa

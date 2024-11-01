#! /bin/bash

### Headers for the cluster.

#!/bin/bash
#SBATCH --job-name bwa
#SBATCH --mem=500G
#SBATCH -n 1 #tasks
#SBATCH -N 1 #nodes
#SBATCH -c 28 #number of cores per task
#SBATCH -o slurm_output_bwa.%J
#SBATCH -e slurm_error_bwa.%J
#SBATCH -p highmem
#SBATCH --qos highmem
#SBATCH --mail-type=ALL
#SBATCH --mail-user=

#Load relevant modules

module load bio/samtools/1.10
module load miniconda3/base/py38_4.13.0

conda activate /bighome/ngroberts/.conda/envs/haphic

### Create a BWA index
/kmk/scripts/bwa/bwa index /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/Discradisca_HiC.asm.hic.hap1.p_ctg.fasta
/kmk/scripts/bwa/bwa index /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/Discradisca_HiC.asm.hic.hap2.p_ctg.fasta

### Align HiC reads to each haplotype
/kmk/scripts/bwa/bwa mem -5SP -t 28 /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/Discradisca_HiC.asm.hic.hap1.p_ctg.fasta /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/KK3956-2C_R_1.fastq.gz /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/KK3956-2C_R_2.fastq.gz | /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/samblaster/samblaster | samtools view - -@ 14 -S -h -b -F 3340 -o HiC_hap1.bam
/kmk/scripts/bwa/bwa mem -5SP -t 28 /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/Discradisca_HiC.asm.hic.hap2.p_ctg.fasta /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/KK3956-2C_R_1.fastq.gz /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/KK3956-2C_R_2.fastq.gz | /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/samblaster/samblaster | samtools view - -@ 14 -S -h -b -F 3340 -o HiC_hap2.bam

### Filter: MAPQ>1 Max edit distance 3 (these are what HapHiC recommends)
/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/utils/filter_bam HiC_hap1.bam 1 --nm 3 --threads 16 | samtools view - -b -@ 14 -o HiC_hap1.filtered.bam
/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/utils/filter_bam HiC_hap2.bam 1 --nm 3 --threads 16 | samtools view - -b -@ 14 -o HiC_hap2.filtered.bam

conda deactivate

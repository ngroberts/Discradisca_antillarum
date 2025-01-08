#!/bin/bash
#SBATCH --job-name bwa
#SBATCH --mem=500G
#SBATCH -n 1 #tasks
#SBATCH -N 1 #nodes
#SBATCH -c 16 #number of cores per task
#SBATCH -o slurm_output_bwa.%J
#SBATCH -e slurm_error_bwa.%J
#SBATCH -p threaded
#SBATCH --qos threaded
#SBATCH --mail-type=ALL
#SBATCH --mail-user=

#Load relevant modules

module load bio/samtools/1.10
module load miniconda3/base/py38_4.13.0

conda activate /bighome/ngroberts/.conda/envs/haphic

### Create a BWA index
/kmk/scripts/bwa/bwa index hifiasm.asm.hic.p_ctg.fasta

### Align HiC reads to all_haps.fasta
/kmk/scripts/bwa/bwa mem -5SP -t 28 hifiasm.asm.hic.p_ctg.fasta /grps2/kmk/2023-01-03_HudsonAlpha_Discradisca_antillarum_HiFi/XFTP-0019_R1_001_val_1.fq.gz /grps2/kmk/2023-01-03_HudsonAlpha_Discradisca_antillarum_HiFi/XFTP-0019_R2_001_val_2.fq.gz | /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/samblaster/samblaster | samtools view - -@ 14 -S -h -b -F 3340 -o HiC.bam

### Filter: MAPQ>1 Max edit distance 3 (these are what HapHiC recommends)
/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/utils/filter_bam HiC.bam 1 --nm 3 --threads 16 | samtools view - -b -@ 14 -o HiC.filtered.bam

conda deactivate

#! /bin/bash

### Headers for the cluster.

#!/bin/bash
#SBATCH --job-name hap_hic
#SBATCH --mem=500G
#SBATCH -n 1 #tasks
#SBATCH -N 1 #nodes
#SBATCH -c 16 #number of cores per task
#SBATCH -o slurm_output_hapHic_quickview.%J
#SBATCH -e slurm_error_hapHic_quickview.%J
#SBATCH -p highmem
#SBATCH --qos highmem
#SBATCH --mail-type=ALL
#SBATCH --mail-user=

FILTEREDBAM=HiC.filtered.bam
ASSEMBLY=Discradisca_HiC.asm.hic.p_utg.fasta
GFA=Discradisca_HiC.asm.hic.p_utg.gfa

module load miniconda3/base/py38_4.13.0

conda activate /bighome/ngroberts/.conda/envs/haphic

FILTEREDBAM=HiC.filtered.bam
ASSEMBLY=Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta
nchrs=0

### Partition contigs into different haplotypes in quick view mode

/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/haphic pipeline $nchrs $ASSEMBLY $FILTEREDBAM --quick-view --gfa "Discradisca_HiC.asm.hic.hap1.p_ctg.gfa,Discradisca_HiC.asm.hic.hap2.p_ctg.gfa" --correct_nrounds 2 --RE "GATC,GANTC,CTNAG,TTAA"

conda deactivate

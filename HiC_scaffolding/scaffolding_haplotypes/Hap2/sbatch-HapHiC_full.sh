#! /bin/bash

### Headers for the cluster.

#!/bin/bash
#SBATCH --job-name hap_hic
#SBATCH --mem=500G
#SBATCH -n 1 #tasks
#SBATCH -N 1 #nodes
#SBATCH -c 16 #number of cores per task
#SBATCH -o slurm_output.%J
#SBATCH -e slurm_error.%J
#SBATCH -p highmem
#SBATCH --qos highmem
#SBATCH --mail-type=ALL
#SBATCH --mail-user=

module load miniconda3/base/py38_4.13.0
conda activate /bighome/ngroberts/.conda/envs/haphic

FILTEREDBAM=HiC_hap2.filtered.bam
ASSEMBLY=/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/Discradisca_HiC.asm.hic.hap2.p_ctg.fasta
nchrs=9

/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/haphic pipeline $ASSEMBLY $FILTEREDBAM $nchrs --threads 16 --max_inflation 50 --gfa "/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/scaffolding_haplotypes/Hap2/Discradisca_HiC.asm.hic.hap2.p_ctg.gfa" --correct_nrounds 2 --RE "GATC,GANTC,CTNAG,TTAA"

conda deactivate

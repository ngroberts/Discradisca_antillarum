#!/bin/bash

#SBATCH --job-name=
#SBATCH -n 1 #tasks
#SBATCH -N 1 #nodes
#SBATCH -c 16 #cores here
#SBATCH --mem=600G
#SBATCH -o slurm_output-.%J
#SBATCH -e slurm_error-.%J
#SBATCH -p threaded
#SBATCH --qos threaded
#SBATCH --mail-type=ALL
#SBATCH --mail-user=

me=`whoami`

module load bio/quast/5.0

quast.py -e -m 0 -t 16 --space-efficient out_JBAT.FINAL.fa

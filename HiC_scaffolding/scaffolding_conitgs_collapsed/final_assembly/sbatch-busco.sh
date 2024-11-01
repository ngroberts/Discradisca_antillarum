#!/bin/bash

#SBATCH --job-name busco
#SBATCH --mem=500G
#SBATCH -n 1 #tasks
#SBATCH -N 1 #nodes
#SBATCH -c 16 #number of cores per task
#SBATCH -o slurm_output_busco.%J
#SBATCH -e slurm_error_busco.%J
#SBATCH -p highmem
#SBATCH --qos highmem
#SBATCH --mail-type=ALL
#SBATCH --mail-user=

export DK_ROOT=/share/apps/dotkit
. /share/apps/dotkit/bash/.dk_init

module load bio/busco
module load bio/augustus/3.3.2

export BUSCO_CONFIG_FILE="/kmk/scripts/busco/config.ini"
export AUGUSTUS_CONFIG_PATH="/kmk/scripts/augustus-3.3.2/config"

#You may want to change "metazoa" to "mollusca" or vice versa for the different databses we are likely to use
#This script uses the new "--long" feature that is more sensitive
busco -c 16 -m genome --long --offline -l /kmk/databases/metazoa_odb10 -i Discradisca_antillarum_collapsed_phased.fa  -o BUSCO_metazoa.fasta

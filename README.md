## HiC Scaffolding of the Discradisca antillarum genome using HapHiC:

### Assembly of the genome with HiC data:

From **sbatch-Hifisasm_highmem.sh**

Using Hifiasm 0.19.7


```bash

#Assemble
/kmk/scripts/hifiasm-0.19.7/hifiasm -o /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/Discradisca_HiC.asm -t 16 --h1 /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/KK3956-2C_R_1.fastq.gz --h2 /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/KK3956-2C_R_1.fastq.gz /grps2/kmk/2023-01-03_HudsonAlpha_Discradisca_antillarum_HiFi/6759-THS-011-HiFi_only.fasta

#Make fasta from primary contigs (phased blocks)
awk '/^S/{print ">"$2"\n"$3}' Discradisca_HiC.asm.hic.p_ctg.gfa | fold > Discradisca_HiC.asm.hic.p_ctg.fasta

#Make fasta from haplotype-resolved processed untig graph.
awk '/^S/{print ">"$2"\n"$3}' Discradisca_HiC.asm.hic.p_utg.gfa | fold > Discradisca_HiC.asm.hic.p_utg.fasta

#Make fasta from haplotype-resolved raw unitig graph. This graph keeps all haplotype information.
awk '/^S/{print ">"$2"\n"$3}' Discradisca_HiC.asm.hic.r_utg.gfa | fold > Discradisca_HiC.asm.hic.r_utg.fasta

#Do this also for all haplotypes: (phased blocks)
awk '/^S/{print ">"$2"\n"$3}' Discradisca_HiC.asm.hic.hap1.p_ctg.gfa | fold > Discradisca_HiC.asm.hic.hap1.p_ctg.fasta
awk '/^S/{print ">"$2"\n"$3}' Discradisca_HiC.asm.hic.hap2.p_ctg.gfa | fold > Discradisca_HiC.asm.hic.hap2.p_ctg.fasta

#Concatenate fastas from each haplotype to create all_haps.fa
cat Discradisca_HiC.asm.hic.hap1.p_ctg.fasta Discradisca_HiC.asm.hic.hap2.p_ctg.fasta > Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta

```

### Align Hi-C reads to the genome:

From **sbatch-bwa_HapHic.sh**

Using samtools1.10

Using bwa0.7.17-r1188

Here we are going to align all our reads to both haplotypes: Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta

```bash

### Create a BWA index
/kmk/scripts/bwa/bwa index Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta

### Align HiC reads to all_haps.fasta
/kmk/scripts/bwa/bwa mem -5SP -t 28 Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/KK3956-2C_R_1.fastq.gz /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/KK3956-2C_R_2.fastq.gz | /grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/samblaster/samblaster | samtools view - -@ 14 -S -h -b -F 3340 -o HiC.bam

### Filter: MAPQ>1 Max edit distance 3 (these are what HapHiC recommends)
/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/utils/filter_bam HiC.bam 1 --nm 3 --threads 16 | samtools view - -b -@ 14 -o HiC.filtered.bam

```

### Use quickview in HapHiC to estimate diploid chromosome number manually:
We need to do this because we do not know the number of chromosomes. Also notice how we specify the chemistry of restriction sites. We used Arima 4.5

We also specify nchrs to be 0 because for quickview it disregards this value.

From **sbatch-HapHiC_quickview.sh**

```bash

FILTEREDBAM=HiC.filtered.bam
ASSEMBLY=Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta
nchrs=0

### Partition contigs into different haplotypes in quick view mode

/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/haphic pipeline $nchrs $ASSEMBLY $FILTEREDBAM --quick-view --gfa "Discradisca_HiC.asm.hic.hap1.p_ctg.gfa,Discradisca_HiC.asm.hic.hap2.p_ctg.gfa" --correct_nrounds 2 --RE "GATC,GANTC,CTNAG,TTAA"

```

### Manually curate in juicer to get diploid chromosome number:

Haphic produces a file, juicebox.sh in 04.build, you can adde the appropriate headers and run this to get the files needed for juicer.

The files we need for juicebox are:

> out_JBAT.hic
> out_JBAT.assembly 

Take these into juicer, and look at the raw data.

![]("pngs/discradisca_no_curation.png")

Do manual curation in juicer:

![]("pngs/discradisca_curated.png")

We now have some idea of the diploid chromsosome number being ()

### Run HapHic with our diploid chromsosome number:

```bash
```

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

#### **Issue:**

For this genome when filtered, the bamfile is only 63M compared to the unfiltered 224M and 590M allhaps.fasta. This is not enough coverage of HiC for proper scaffolding according to HapHic.

This results in Hi-C depth of only 0.1x. This is not enough for scaffolding.

See: [HapHiC Issue #47](https://github.com/zengxiaofei/HapHiC/issues/47)

I now attempted to solve this in two ways: 

1. I attempted to scaffold each haplotype separetely, this is done by aligning HiC reads to each haplotype and scaffolding.

[Scaffolding Haplotypes Seperately](#haplotype-graph-scaffolding)

2. I attempted to just scaffold the haplotype collapsed unitg graph from Hifiasm. *.p_utg.fasta. This is done by aligning HiC reads to this and proceeding.

[Scaffolding untig Graph](#untig-graph-scaffolding)

The following steps proceed without solving this issue, but the steps are the same to produce the results. Please see the sections mentioned above to see these results.

### Use quickview in HapHiC to estimate diploid chromosome number manually:
We need to do this because we do not know the number of chromosomes. Also notice how we specify the chemistry of restriction sites. We used Arima 4.5

We also specify nchrs to be 0 because for quickview it disregards this value.

From **sbatch-HapHiC_quickview.sh**

```bash

FILTEREDBAM=HiC.filtered.bam
ASSEMBLY=Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta
nchrs=0

### Partition contigs into different haplotypes in quick view mode

/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/haphic pipeline $ASSEMBLY $FILTEREDBAM $nchrs --quick_view --gfa "Discradisca_HiC.asm.hic.hap1.p_ctg.gfa,Discradisca_HiC.asm.hic.hap2.p_ctg.gfa" --correct_nrounds 2 --RE "GATC,GANTC,CTNAG,TTAA"

```

### Manually curate in juicer to get diploid chromosome number:

Haphic produces a file, juicebox.sh in 04.build, you can add the appropriate headers and run this to get the files needed for juicer.

The files we need for juicebox are:

> out_JBAT.hic
> out_JBAT.assembly 

Do manual curation in juicer:

![](https://github.com/ngroberts/Discradisca_HiC/blob/master/images/Hic_haplotype_resolved_quickview.png)

We now have some idea of the diploid chromsosome number being 18.

### Run HapHic with our diploid chromsosome number:

We can now remove the quickview flag and make sure to specify the gfas for each haplotype. Giving it our expected chromsosome number it will try and scaffold the data.

```bash
FILTEREDBAM=HiC.filtered.bam
ASSEMBLY=/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta
nchrs=18

/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/haphic pipeline $ASSEMBLY $FILTEREDBAM $nchrs --threads 16 --gfa "/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/scaffolding_all_haps/Discradisca_HiC.asm.hic.hap1.p_ctg.gfa,/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/scaffolding_all_haps/Discradisca_HiC.asm.hic.hap2.p_ctg.gfa" --max_inflation 3 --correct_nrounds 2 --RE "GATC,GANTC,CTNAG,TTAA"
```

Using the same steps above (running juicer.sh) we can take a look at the HiC map and do some manual scaffolding in Juicebox.

Here is the final HiC map: N= 9, 2N = 18.

![](https://github.com/ngroberts/Discradisca_HiC/blob/master/images/HIC_Discradisca_diploid.png)

Lastly we can use juicer post after saving this assembly in juicebox to produce the final fasta, and remove the debris generated in juicebox.

From juicer_post.sh

```bash
/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/scripts/../utils/juicer post -o out_JBAT out_JBAT.review.assembly out_JBAT.liftover.agp Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta
```

This will produce:

>out_JBAT.FINAL.fa

Then we need to remove the debris using seqkit.

```bash
/grps2/kmk/Nick/2024-02-27_MDA_Seqkit_Samtools/scripts/seqkit head -n 18 out_JBAT.FINAL.fa > Discradisca_antillarum_diploid.fa
```
## Results

### Haplotype Resolved Assembly [N=9, 2N=18]

![](https://github.com/ngroberts/Discradisca_HiC/blob/master/images/HIC_Discradisca_diploid.png)

BUSCO:
> ##### Results:
> 
> ```
> C:95.6%[S:10.3%,D:85.3%],F:0.8%,M:3.6%,n:954
> 912     Complete BUSCOs (C)
> 98	    Complete and single-copy BUSCOs (S)
> 814     Complete and duplicated BUSCOs (D)
> 8	    Fragmented BUSCOs (F)
> 34	    Missing BUSCOs (M)
> 954     Total BUSCO groups searched
> ```

Quast:
> ```
> Assembly                    Discradisca_antillarum_diploid
> # contigs (>= 0 bp)         18
> # contigs (>= 1000 bp)      18
> # contigs (>= 5000 bp)      18
> # contigs (>= 10000 bp)     18
> # contigs (>= 25000 bp)     18
> # contigs (>= 50000 bp)     18
> Total length (>= 0 bp)      590625809
> Total length (>= 1000 bp)   590625809
> Total length (>= 5000 bp)   590625809
> Total length (>= 10000 bp)  590625809
> Total length (>= 25000 bp)  590625809
> Total length (>= 50000 bp)  590625809
> # contigs                   18
> Largest contig              59648151
> Total length                590625809
> GC (%)                      35.42
> N50                         36278936
> N75                         24445255
> L50                         6
> L75                         12
> # N's per 100 kbp           0.36
> ```

### Haplotype Graph Scaffolding

Analysis still ongoing...

### Untig Graph Scaffolding

Analysis still ongoing...

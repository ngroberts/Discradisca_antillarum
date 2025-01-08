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

For this genome when filtered, the bamfile is 71Gb which is a Hi-C depth of around 120x. This is a great depth for scaffolding. 

If the depth is poor (lower than 5x) scaffolding will be rather difficult.

See: [HapHiC Issue #47](https://github.com/zengxiaofei/HapHiC/issues/47)

In order to produce the best possible assembly, I scaffolded 4 seperate assemblies: 

1. I attempted to scaffold the haplotype combined assembly. (concatinated hap1 and hap2). This will give the diploid assembly.

[Scaffolding allhaps](#haplotype-resolved-assembly)

1. I attempted to scaffold each haplotype separetely, this is done by aligning HiC reads to each haplotype and scaffolding.

[Scaffolding Haplotypes Seperately](#haplotype-graph-scaffolding)

2. I attempted to just scaffold the haplotype collapsed phased assembly, unlike the utg (untig graph) haplotype information is not retained, this should be the best one.

[Scaffolding phased graph](#haplotype-resolved-collapsed-graph-scaffolding)


## Setup

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

Haphic produces a file, juicebox.sh in 04.build, you can add the appropriate parameters (sbatch headers) and run this to get the files needed for juicer.

The files we need for juicebox are:

> out_JBAT.hic
> out_JBAT.assembly 

Do manual curation in juicer. This just means assigning your own pseuodmolecules manually based on contact information. In a genome that is already well assembled with high HiC depth this should not be an issue.

We now have some idea of the diploid chromsosome number being 16.

### Run HapHic with our diploid chromsosome number:

We can now remove the quickview flag and make sure to specify the gfas for each haplotype. Giving it our expected chromsosome number it will try and scaffold the data.

```bash
FILTEREDBAM=HiC.filtered.bam
ASSEMBLY=/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta
nchrs=16

/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/haphic pipeline $ASSEMBLY $FILTEREDBAM $nchrs --threads 16 --gfa "/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/scaffolding_all_haps/Discradisca_HiC.asm.hic.hap1.p_ctg.gfa,/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/Discradisca/scaffolding_all_haps/Discradisca_HiC.asm.hic.hap2.p_ctg.gfa" --max_inflation 3 --correct_nrounds 2 --RE "GATC,GANTC,CTNAG,TTAA"
```

Using the same steps above (running juicer.sh) we can take a look at the HiC map and do some manual scaffolding in Juicebox.

Here is the final HiC map: N=8, 2N = 16.

![]()

Lastly we can use juicer post after saving this assembly in juicebox to produce the final fasta, and remove the debris generated in juicebox.

From juicer_post.sh

```bash
/grps2/kmk/Nick/2024-07-02-HiC_Discradisca/programs/HapHiC/scripts/../utils/juicer post -o out_JBAT out_JBAT.review.assembly out_JBAT.liftover.agp Discradisca_HiC.asm.hic.all_haps.p_ctg.fasta
```

This will produce:

>out_JBAT.FINAL.fa

Then we need to remove the debris using seqkit. I have not done this as NCBI wants debris in the upload. For annotation I will leave debris in.

```bash
/grps2/kmk/Nick/2024-02-27_MDA_Seqkit_Samtools/scripts/seqkit head -n 18 out_JBAT.FINAL.fa > Discradisca_antillarum_diploid.fa
```
## Results

### Haplotype Resolved Assembly 

[N=8, 2N=16]

![](https://github.com/ngroberts/Discradisca_antillarum/blob/master/HiC_scaffolding/images/ctg.png)

BUSCO:

```
>	***** Results: *****
>
>	C:95.2%[S:94.8%,D:0.4%],F:1.0%,M:3.8%,n:954	   
>	908	Complete BUSCOs (C)			   
>	904	Complete and single-copy BUSCOs (S)	   
>	4	Complete and duplicated BUSCOs (D)	   
>	10	Fragmented BUSCOs (F)			   
>	36	Missing BUSCOs (M)			   
>	954	Total BUSCO groups searched
```

Quast

```
> Assembly                    out_JBAT.FINAL
> # contigs (>= 0 bp)         208           
> # contigs (>= 1000 bp)      208           
> # contigs (>= 5000 bp)      208           
> # contigs (>= 10000 bp)     206           
> # contigs (>= 25000 bp)     190           
> # contigs (>= 50000 bp)     72            
> Total length (>= 0 bp)      308701191     
> Total length (>= 1000 bp)   308701191     
> Total length (>= 5000 bp)   308701191     
> Total length (>= 10000 bp)  308690191     
> Total length (>= 25000 bp)  308343930     
> Total length (>= 50000 bp)  303915753     
> # contigs                   208           
> Largest contig              59427719      
> Total length                308701191     
> GC (%)                      36.00         
> N50                         48854149      
> N75                         26316845      
> L50                         3             
> L75                         6             
> # N's per 100 kbp           0.39  
```

### Haplotype Graph Scaffolding

#### Haplotype 1

HiC Graph:

![](https://github.com/ngroberts/Discradisca_antillarum/blob/master/HiC_scaffolding/images/hap1.png)

Metrics:

Quast: 

```
> Assembly                    out_JBAT.FINAL
> # contigs (>= 0 bp)         196           
> # contigs (>= 1000 bp)      196           
> # contigs (>= 5000 bp)      196           
> # contigs (>= 10000 bp)     196           
> # contigs (>= 25000 bp)     180           
> # contigs (>= 50000 bp)     53            
> Total length (>= 0 bp)      305238177     
> Total length (>= 1000 bp)   305238177     
> Total length (>= 5000 bp)   305238177     
> Total length (>= 10000 bp)  305238177     
> Total length (>= 25000 bp)  304896358     
> Total length (>= 50000 bp)  300289961     
> # contigs                   196           
> Largest contig              60427462      
> Total length                305238177     
> GC (%)                      35.90         
> N50                         48440619      
> N75                         26101642      
> L50                         3             
> L75                         5             
> # N's per 100 kbp           1.18
```

Busco:

```
>	***** Results: *****
>
>	C:95.1%[S:94.9%,D:0.2%],F:1.2%,M:3.7%,n:954	   
>	907	Complete BUSCOs (C)			   
>	905	Complete and single-copy BUSCOs (S)	   
>	2	Complete and duplicated BUSCOs (D)	   
>	11	Fragmented BUSCOs (F)			   
>	36	Missing BUSCOs (M)			   
>	954	Total BUSCO groups searched
```

#### Haplotype 2

![](https://github.com/ngroberts/Discradisca_antillarum/blob/master/HiC_scaffolding/images/hap2.png)

Metrics:

Quast: 

```
> Assembly                    out_JBAT.FINAL
> # contigs (>= 0 bp)         98            
> # contigs (>= 1000 bp)      98            
> # contigs (>= 5000 bp)      98            
> # contigs (>= 10000 bp)     98            
> # contigs (>= 25000 bp)     89            
> # contigs (>= 50000 bp)     46            
> Total length (>= 0 bp)      303338868     
> Total length (>= 1000 bp)   303338868     
> Total length (>= 5000 bp)   303338868     
> Total length (>= 10000 bp)  303338868     
> Total length (>= 25000 bp)  303136924     
> Total length (>= 50000 bp)  301546227     
> # contigs                   98            
> Largest contig              58825145      
> Total length                303338868     
> GC (%)                      35.74         
> N50                         48971102      
> N75                         26474007      
> L50                         3             
> L75                         5             
> # N's per 100 kbp           0.66
```
Busco:

```
>	***** Results: *****
>
>	C:95.6%[S:95.2%,D:0.4%],F:0.9%,M:3.5%,n:954	   
>	912	Complete BUSCOs (C)			   
>	908	Complete and single-copy BUSCOs (S)	   
>	4	Complete and duplicated BUSCOs (D)	   
>	9	Fragmented BUSCOs (F)			   
>	33	Missing BUSCOs (M)			   
>	954	Total BUSCO groups searched
```

### Haplotype Resolved Collapsed Graph Scaffolding 

HiC Graph:

![]()

Quast:


Busco:

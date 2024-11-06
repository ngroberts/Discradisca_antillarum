#!/bin/bash 
awk '
BEGIN { OFS="\t"; chr_num=1 } 
/^>/ { 
    if (seq) { 
        print "chr", "-", contig_name, chr_num, 0, length(seq), "black";
        chr_num++;
    }
    contig_name = substr($0, 2);
    seq = "";
    next;
}
{ seq = seq $0 }
END { 
    if (seq) { 
        print "chr", "-", contig_name, chr_num, 0, length(seq), "black";
    }
}' Discradisca_antillarum_collapsed_phased.fa > karyotype.txt

sed -i 's/\t/ /g' karyotype.txt

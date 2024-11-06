#!/bin/bash

# Input and output filenames
input_file="Discradisca_antillarum_collapsed_phased.fa.out"
output_file="Discradisca_antillarum_repeat_content.bed"

# Process RepeatMasker .out file and write to BED file
awk 'NR > 3 && NF > 1 {
    query = $5;
    start = $6 - 1;  # BED is 0-based
    end = $7;
    repeat = $11;
    repeat_start = $14 - 1;  # BED is 0-based
    repeat_end = $15;
    strand = $9;

    # Convert strand notation
    if (strand == "+") {
        strand = "-";
    } else {
        strand = "+";
    }

    # Write BED format
    print query "\t" start "\t" end "\t" repeat "\t.\t" strand;
}' "$input_file" > "$output_file"


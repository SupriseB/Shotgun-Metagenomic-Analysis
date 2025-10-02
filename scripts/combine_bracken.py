#!/usr/bin/env python3
import argparse
import csv
import os

def combine_bracken_row_samples(files, output):
    """
    Combine multiple Bracken result files into one table.
    Rows = samples, Columns = taxa
    """
    taxa_set = set()
    sample_taxa_counts = {}  # {sample: {taxon: count}}

    # First pass: collect all taxa and per-sample counts
    for f in files:
        sample = os.path.basename(f).replace("_bracken_S.txt", "").replace("_bracken_G.txt", "").replace("_bracken_F.txt", "")
        sample_taxa_counts[sample] = {}

        with open(f, "r") as infile:
            reader = csv.DictReader(infile, delimiter="\t")
            for row in reader:
                taxon = row["name"].strip()
                count = int(float(row["new_est_reads"]))
                taxa_set.add(taxon)
                sample_taxa_counts[sample][taxon] = count

    taxa_list = sorted(taxa_set)

    # Write merged table: samples as rows
    with open(output, "w", newline="") as out:
        writer = csv.writer(out, delimiter="\t")
        writer.writerow(["Sample"] + taxa_list)
        for sample in sample_taxa_counts:
            row = [sample] + [sample_taxa_counts[sample].get(taxon, 0) for taxon in taxa_list]
            writer.writerow(row)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Combine Bracken outputs with samples as rows")
    parser.add_argument("--files", nargs="+", required=True, help="List of Bracken files (species, genus, family)")
    parser.add_argument("-o", "--output", required=True, help="Output combined file")
    args = parser.parse_args()

    combine_bracken_row_samples(args.files, args.output)


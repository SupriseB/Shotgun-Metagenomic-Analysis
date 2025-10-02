# Save this as bracken_to_krona.py
import csv
import sys

# ---- Check arguments ----
if len(sys.argv) < 3:
    print("Usage: python bracken_to_krona.py <bracken_input.txt> <krona_output.txt>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

# ---- Convert Bracken output to Krona input ----
with open(input_file, 'r') as infile, open(output_file, 'w', newline='') as outfile:
    reader = csv.DictReader(infile, delimiter='\t')
    writer = csv.writer(outfile, delimiter='\t')

    for row in reader:
        count = row["new_est_reads"]
        taxon = row["name"].strip()

        # Write to file in format: count <tab> taxon
        writer.writerow([count, taxon])


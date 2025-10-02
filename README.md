**Gut Microbiome Metagenomic Pipeline**


This repository contains a reproducible pipeline for shotgun metagenomic analysis of gut microbiome sequencing data. It performs:

Quality control (adapter trimming, filtering)

Host read removal (Bowtie2 against GRCh38)

Taxonomic classification (Kraken2)

Abundance estimation (Bracken)

Interactive visualization (Krona plots)

Summary reports (MultiQC, merged Bracken tables)

**Repository Contents**

gut_microbiome_pipeline.sh → Main pipeline script

bracken_to_krona.py → Helper script to convert Bracken output to Krona input

README.md → This documentation

**Requirements**

The pipeline relies on the following tools:

Fastp
 (QC & trimming)

Bowtie2
 (host read removal)

Samtools
 (alignment stats)

Kraken2
 (taxonomic classification)

Bracken
 (abundance estimation)

Krona
 (interactive plots)

MultiQC
 (report aggregation)

Singularity/Apptainer
 (for containerized execution)

Databases & References

Human genome index (GRCh38) → Bowtie2 index (unzipped in dbs/GRCh38_noalt_as/)

Kraken2 standard DB (8GB version recommended) → extracted in dbs/k2_standard_08gb_20230605/

**Usage**
1. Prepare inputs

Place paired-end FASTQ files in the working directory.
Example filenames:

SAMPLE1_R1_001.fastq.gz
SAMPLE1_R2_001.fastq.gz
SAMPLE2_R1_001.fastq.gz
SAMPLE2_R2_001.fastq.gz


Download & unzip the GRCh38 Bowtie2 index into dbs/GRCh38_noalt_as/.

Download & extract the Kraken2 database into dbs/k2_standard_08gb_20230605/.

2. Run the pipeline
bash gut_microbiome_pipeline.sh

3. Outputs

For each sample (SAMPLE):

QC results:

${SAMPLE}_results/${SAMPLE}_fastp.html

${SAMPLE}_results/${SAMPLE}_fastp.json

Host removal:

${SAMPLE}_results/${SAMPLE}_host_alignment.sam

${SAMPLE}_results/${SAMPLE}_mapping_stats.txt

${SAMPLE}_results/${SAMPLE}_non_host_reads.1.fastq.gz

${SAMPLE}_results/${SAMPLE}_non_host_reads.2.fastq.gz

Taxonomic classification:

${SAMPLE}_results/${SAMPLE}_kraken_report.txt

${SAMPLE}_results/${SAMPLE}_kraken_output.txt

Bracken abundance estimates:

${SAMPLE}_results/${SAMPLE}_bracken_S.txt (species)

${SAMPLE}_results/${SAMPLE}_bracken_G.txt (genus)

${SAMPLE}_results/${SAMPLE}_bracken_F.txt (family)

Krona plots:

${SAMPLE}_results/${SAMPLE}_bracken_krona.html

4. Combined outputs

multiqc_report/ → aggregated QC & alignment summary

merged_bracken_species.txt → combined Bracken species counts

merged_bracken_genus.txt → combined Bracken genus counts

merged_bracken_family.txt → combined Bracken family counts

krona_combined.html → merged Krona visualization

**Notes**

Ensure that Singularity/Apptainer is installed and accessible.

The script automatically detects .fastq or .fastq.gz files.

Default read length for Bracken is set to 150 bp (modify -r if needed).

The pipeline is modular—steps can be skipped or extended as required.

**Example Workflow**
# Run on 2 samples
SAMPLE1_R1_001.fastq.gz
SAMPLE1_R2_001.fastq.gz
SAMPLE2_R1_001.fastq.gz
SAMPLE2_R2_001.fastq.gz

# Launch
bash gut_microbiome_pipeline.sh

# View results
firefox SAMPLE1_results/SAMPLE1_bracken_krona.html

**Author**

Suprise Baloyi
📧 suprisebaloyi17@gmail.com

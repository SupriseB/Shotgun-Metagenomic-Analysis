#!/bin/bash
set -e  # Exit on any error

# =======================================
# Gut Microbiome Metagenomic Pipeline
# (QC -> Host Removal -> Kraken2 + Bracken)
# =======================================

THREADS=8
HUMAN_INDEX_ZIP="GRCh38_noalt_as.zip"
KRAKEN_DB_TAR="k2_standard_08gb_20230605.tar.gz"
KRAKEN_SIF="kraken2.sif"
BRACKEN_SIF="bracken_2.6.2--py39hc16433a_0.sif"
KRONA_SIF="krona_2.7.1.sif"

# ---- Create database folder ----
mkdir -p dbs

# ---- Human index (extract from scratch) ----
rm -rf dbs/GRCh38_noalt_as
echo "Extracting human index from scratch..."
unzip -q "$HUMAN_INDEX_ZIP" -d dbs

HUMAN_INDEX_DIR="/home/baloyis/mini/dbs/GRCh38_noalt_as/GRCh38_noalt_as"
  # points to the folder containing the .bt2 files

# ---- Kraken2 database (extract from scratch) ----
KRAKEN_DB_DIR="/home/baloyis/mini/ddbs/k2_standard_08gb_20230605"
rm -rf "$KRAKEN_DB_DIR"
mkdir -p "$KRAKEN_DB_DIR"
echo "Extracting Kraken2 DB from scratch..."
tar -xzf "$KRAKEN_DB_TAR" -C "$KRAKEN_DB_DIR"

# ---- Detect samples (.fastq or .fastq.gz) ----
SAMPLES=$(ls *_R1_001.fastq.gz *_R1_001.fastq 2>/dev/null | sed -E 's/_R1_001\.fastq(\.gz)?//' | sort | uniq)

if [ -z "$SAMPLES" ]; then
    echo "No FASTQ files found. Exiting."
    exit 1
fi

# ---- Loop over samples ----
for SAMPLE in $SAMPLES; do
    echo "===== Processing $SAMPLE ====="

    mkdir -p "${SAMPLE}_results"

    # Detect file extensions
    if [ -f "${SAMPLE}_R1_001.fastq.gz" ]; then
        R1="${SAMPLE}_R1_001.fastq.gz"
        R2="${SAMPLE}_R2_001.fastq.gz"
    elif [ -f "${SAMPLE}_R1_001.fastq" ]; then
        R1="${SAMPLE}_R1_001.fastq"
        R2="${SAMPLE}_R2_001.fastq"
    else
        echo "FASTQ files for $SAMPLE not found. Skipping."
        continue
    fi

    # Step 1: Quality Control
    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "${SAMPLE}_results/${SAMPLE}_trimmed_R1.fastq.gz" \
        -O "${SAMPLE}_results/${SAMPLE}_trimmed_R2.fastq.gz" \
        --detect_adapter_for_pe \
        --thread "$THREADS" \
        --html "${SAMPLE}_results/${SAMPLE}_fastp.html" \
        --json "${SAMPLE}_results/${SAMPLE}_fastp.json"

    # Step 2: Host Read Removal
    bowtie2 -x "$HUMAN_INDEX_DIR" \
        -1 "${SAMPLE}_results/${SAMPLE}_trimmed_R1.fastq.gz" \
        -2 "${SAMPLE}_results/${SAMPLE}_trimmed_R2.fastq.gz" \
        --very-sensitive \
        --un-conc-gz "${SAMPLE}_results/${SAMPLE}_non_host_reads.fastq.gz" \
        --threads "$THREADS" \
        -S "${SAMPLE}_results/${SAMPLE}_host_alignment.sam"

    samtools flagstat "${SAMPLE}_results/${SAMPLE}_host_alignment.sam" \
        > "${SAMPLE}_results/${SAMPLE}_mapping_stats.txt"

    # Step 3: Kraken2
    singularity exec "$KRAKEN_SIF" kraken2 \
        --db "$KRAKEN_DB_DIR" \
        --paired "${SAMPLE}_results/${SAMPLE}_non_host_reads.fastq.1.gz" "${SAMPLE}_results/${SAMPLE}_non_host_reads.fastq.2.gz" \
        --report "${SAMPLE}_results/${SAMPLE}_kraken_report.txt" \
        --output "${SAMPLE}_results/${SAMPLE}_kraken_output.txt" \
        --threads "$THREADS"

    # Step 4: Bracken (species, genus, family)
    for LEVEL in S G F; do
        singularity exec "$BRACKEN_SIF" bracken \
            -d "$KRAKEN_DB_DIR" \
            -i "${SAMPLE}_results/${SAMPLE}_kraken_report.txt" \
            -o "${SAMPLE}_results/${SAMPLE}_bracken_${LEVEL}.txt" \
            -r 150 \
            -l "$LEVEL"
    done

  # Step 5: Krona (species-level)
python3 bracken_to_krona.py \
    "${SAMPLE}_results/${SAMPLE}_bracken_S.txt" \
    "${SAMPLE}_results/${SAMPLE}_bracken_krona_input.txt"

singularity exec "$KRONA_SIF" ktImportText \
    "${SAMPLE}_results/${SAMPLE}_bracken_krona_input.txt" \
    -o "${SAMPLE}_results/${SAMPLE}_bracken_krona.html"


    echo "===== Finished $SAMPLE ====="
done

# -------- POST-PROCESSING --------
multiqc . -o multiqc_report

# Merge Bracken outputs for all samples
./combine_bracken.py --files *_results/*_bracken_S.txt -o merged_bracken_species.txt
./combine_bracken.py --files *_results/*_bracken_G.txt -o merged_bracken_genus.txt
./combine_bracken.py --files *_results/*_bracken_F.txt -o merged_bracken_family.txt

# Combine Krona inputs into one interactive HTML
singularity exec "$KRONA_SIF" ktImportText *_results/*_bracken_krona_input.txt -o krona_combined.html

echo "===== Pipeline Finished Successfully ====="


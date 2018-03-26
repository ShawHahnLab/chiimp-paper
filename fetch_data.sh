#!/usr/bin/env bash

attrs="metadata/sample_attrs.csv"
dir="data/raw"

runs_gombe="170710_M00281_0242_000000000-BBC66
170712_M00281_0243_000000000-BBD2K
170717_M00281_0245_000000000-BBYDN
170721_M00281_0248_000000000-BBWCL
171208_M05588_0019_000000000-BKN3H"

runs_ugalla="170724_M00281_0249_000000000-G1BK4
170725_M00281_0250_000000000-G1BWR
170727_M00281_0251_000000000-G1BUY
170731_M00281_0253_000000000-G1CH1
170802_M00281_0254_000000000-G1CYB
170807_M00281_0256_000000000-BBYRT
170728_M00281_0252_000000000-BBWBJ
170810_M00281_0258_000000000-G1C9B"
# Ugalla Blinded Test, Rep2
run_external="170801_M04734_0044_000000000-G1CRK"

runs_ugalla_multiplex="170922_M00281_0273_000000000-BBWWD
170925_M00281_0274_000000000-BBW8V"


# Download the SRA data with fastq-dump and rename to match the sample_name
# entries.
function fetch_sra {
	# Cut out just the SRR accession numbers and the sample names.
	SRR_NUM=$(   head -n 1 "$attrs" | tr -d '"' | sed s/,/\\n/g | grep -n SRR | cut -f 1 -d :)
	SAMPLE_NUM=$(head -n 1 "$attrs" | tr -d '"' | sed s/,/\\n/g | grep -n sample_name | cut -f 1 -d :)
	SRR=$(   tail -n +2 "$attrs" | tr -d '"' | cut -f $SRR_NUM,$SAMPLE_NUM -d ,)

	if [[ ! -d "$dir" ]]; then
		echo "Downloading raw data from SRA.  This may take a while."
	fi
	mkdir -p "$dir"
	# Fetch each file pair, renaming each time.
	echo "$SRR" | while read entry; do
		sample=$(echo "$entry" | cut -f 1 -d ,)
		srr=$(echo "$entry" | cut -f 2 -d ,)
		dest_r1="$dir/${sample}_R1_001.fastq.gz"
		dest_r2="$dir/${sample}_R2_001.fastq.gz"
		if [[ ! -e "$dest_r1" || ! -e "$dest_r2" ]]; then
			# Completely empty files won't upload to the SRA;
			# instead we'll just re-create them now.
			if [[ "$srr" == "EMPTY" ]]; then
				echo "Dumping placeholder for empty files to $sample..."
				echo -n "" | gzip > "$dest_r1"
				echo -n "" | gzip > "$dest_r2"
			else
				echo "Downloading $srr to $sample..."
				fastq-dump --gzip --split-files --keep-empty-files --outdir "$dir" "$srr" > /dev/null
				mv "$dir/${srr}_1.fastq.gz" "$dest_r1"
				mv "$dir/${srr}_2.fastq.gz" "$dest_r2"
			fi
		fi
	done
}

# Copies the original fastq files directly from the MiSeq run output.
function fetch_local {
	runs=$1
	mkdir -p "$dir"
	for run in $runs; do
		for f in /seq/runs/$run/Data/Intensities/BaseCalls/*fastq.gz; do
			if echo $f | grep -q Undetermined; then
				continue
			fi
			if [[ ! $f =~ ([-_][ABCD1234][-_]|ABC3|D124) || $f =~ pool ]]; then
				continue
			fi
			dst=$(echo "$f" | sed "s/.*\///;s/^/${run}_/")
			cp -u $f $dir/$dst
		done
	done
}

function fetch_local_gombe {
	fetch_local "$runs_gombe"
}

function fetch_local_ugalla {
	fetch_local "$runs_ugalla"
	for f in /seq/external/20170804-ugalla-plates5and6/*gz; do
		# Need to correct filenames
		dst=$(echo "$f" | sed "s/Rep2\\(.*\\)TZ/Rep2-\\1-TZ/;s/.*\///;s/^/${run_external}_/")
		if [[ ! $dst =~ [-_][ABCD1234][-_] ]]; then
			continue
		fi
		cp -u $f $dir/$dst
	done
}

function fetch_local_ugalla_multiplex {
	fetch_local "$runs_ugalla_multiplex"
}

fetch_sra

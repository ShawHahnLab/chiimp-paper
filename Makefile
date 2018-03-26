# This directory is laid out assuming that code and data are not necessarily
# included, so they will be obtained if needed by the rules here.  If both are
# provided, only the analysis and figure-generating rules should need to run.

# CHIIMP git repository commit to check out, if a copy isn't already present
REPO   = "https://github.com/ShawHahnLab/chiimp.git"
COMMIT = 0.1.0

# The forward and reverse Illumina adapters in the raw sequence data.  We only
# rely on R1 here, but both are given.
ADAPT_R1 = "CTGTCTCTTATACACATCTCCGAGCCCACGAGAC"
ADAPT_R2 = "CTGTCTCTTATACACATCTGACGCTGCCGACGA"

# Final product is the figures.
all: results/figures.html

# Storing the sample download code separately so the Makefile can parse the
# resulting filenames
# https://stackoverflow.com/a/41303169/6073858
ifneq (n,$(findstring n,$(firstword -$(MAKEFLAGS))))
data_result := $(shell bash fetch_data.sh >&2)
endif

pat_data = $(subst raw/,prepared/,$(gz))
pat_raw = $(subst data/prepared,data/raw,$@)

d_raw_R1 = $(wildcard data/raw/*R1_001.fastq.gz)
d_raw_R2 = $(wildcard data/raw/*R2_001.fastq.gz)
d_R1 = $(foreach gz, $(d_raw_R1), $(pat_data))
d_R2 = $(foreach gz, $(d_raw_R2), $(pat_data))

# Data prep: trim adapters and keep the R1 reads

# Trim adapters from the R1 reads
$(d_R1):
	mkdir -p $(dir $@)
	cutadapt -a $(ADAPT_R1) $(pat_raw) | gzip > $@
# We don't use the R2 reads, but here's a rule for them
$(d_R2):
	mkdir -p $(dir $@)
	cutadapt -a $(ADAPT_R2) $(pat_raw) | gzip > $@

# We need a full analysis on the various datasets to make the figures
results/figures.html: figures.Rmd \
	results/gombe-round24/report.html \
	results/gombe-blinded-test-2/report.html \
	results/gombe-blinded-test-2-simple/report.html \
	results/gombe-blinded-test-2-full/report.html \
	results/gme/report.html \
	results/gme-mplex/report.html
	R --slave --vanilla -e "rmarkdown::render('$<', output_file = '$@', quiet = TRUE)"

### Full reports
#
# These depend on the trimmed forward reads, the input spreadsheets, and the
# chiimp package.
# The known_genotypes and known_alleles spreadsheets were generated separately
# from the combined results of many samples and replicates across our genotyped
# Gombe chimps, validated with additional information such as known
# inheritance.  The locus_attrs spreadsheet corresponds to the known attributes
# of our selected loci.

spreadsheets = metadata/known_alleles.csv metadata/known_alleles_combined.csv metadata/known_genotypes.csv metadata/locus_attrs.csv

# This allows the $$ below to find the data files after the download script
# runs
.SECONDEXPANSION:

# The first dataset, just using the replicate 1 files
results/gombe-blinded-test-2/report.html: config/config-gmblind2.yml metadata/samples-gmblind2.csv $(spreadsheets) | chiimp $$(d_R1)
	chiimp/inst/bin/chiimp $<

# The first dataset, just using the replicate 1 files, with no artifact/stutter
# filter
results/gombe-blinded-test-2-simple/report.html: config/config-gmblind2-simple.yml metadata/samples-gmblind2.csv $(spreadsheets) | chiimp $$(d_R1)
	chiimp/inst/bin/chiimp $<

# The first dataset, all files
results/gombe-blinded-test-2-full/report.html: config/config-gmblind2-full.yml  metadata/samples-gmblind2-full.csv $(spreadsheets) | chiimp $$(d_R1)
	chiimp/inst/bin/chiimp $<

# The second dataset
results/gombe-round24/report.html: config/config-round24.yml metadata/samples-round24.csv $(spreadsheets) | chiimp $$(d_R1)
	chiimp/inst/bin/chiimp $<

# The third dataset (GME, singleplex)
results/gme/report.html: config/config-gme.yml metadata/samples-gme.csv $(spreadsheets) | chiimp $$(d_R1)
	chiimp/inst/bin/chiimp $<

# The fourth dataset (GME, multiplex)
results/gme-mplex/report.html: config/config-gme-mplex.yml metadata/samples-gme-mplex.csv $(spreadsheets) | chiimp $$(d_R1)
	chiimp/inst/bin/chiimp $<

# Sample attributes for the first dataset, just replicate 1 files
metadata/samples-gmblind2.csv: metadata/sample_attrs.csv
	awk -F, '{if (NR == 1 || ( $$9 == 1 && $$12 == 1 ) ) {print $$0}}' $^ | cut -f 9,11,12,13,15,31 -d , > $@

# Sample attributes for the first dataset, all files
metadata/samples-gmblind2-full.csv: metadata/sample_attrs.csv
	awk -F, '{if (NR == 1 || $$9 == 1) {print $$0}}' $^ | cut -f 9,11,12,13,15,31 -d , > $@

# Sample attributes for the second dataset
metadata/samples-round24.csv: metadata/sample_attrs.csv
	awk -F, '{if (NR == 1 || $$9 == 2) {print $$0}}' $^ | cut -f 9,11,12,13,15,31 -d , > $@

# Sample attributes for the third dataset
metadata/samples-gme.csv: metadata/sample_attrs.csv
	awk -F, '{if (NR == 1 || $$9 == 3) {print $$0}}' $^ | cut -f 9,11,12,14,15,31 -d , > $@

# Sample attributes for the fourth dataset
metadata/samples-gme-mplex.csv: metadata/sample_attrs.csv
	awk -F, '{if (NR == 1 || $$9 == 4) {print $$0}}' $^ | cut -f 9,11,12,14,15,31 -d , > $@

# The chiimp software
# Also installing the development packages as they're required for
# devtools::load_all().
chiimp:
	git clone $(REPO) && cd chiimp && git checkout $(COMMIT)
	R --slave --vanilla -e "pkgs<-c('devtools','roxygen2','testthat');to_inst<-pkgs[!pkgs%in%installed.packages()[,'Package']];if(length(to_inst)>0)install.packages(to_inst,repos='https://cloud.r-project.org')"
	R --slave --vanilla -e " if (!'msa' %in% installed.packages()){source('https://bioconductor.org/biocLite.R');biocLite();biocLite('msa')}"
	R --slave --vanilla -e "devtools::install_deps('$@')"

# Removes the targets of rules above, but not input data or the CHIIMP
# directory.
clean:
	# Figures
	rm -f results/figures.html
	# Sample sheets
	rm -f metadata/samples-gmblind2.csv
	rm -f metadata/samples-gmblind2-full.csv
	rm -f metadata/samples-gme.csv
	rm -f metadata/samples-gme-mplex.csv
	rm -f metadata/samples-round24.csv
	# Reports
	rm -f results/gme-mplex/report.html
	rm -f results/gme/report.html
	rm -f results/gombe-blinded-test-2-full/report.html
	rm -f results/gombe-blinded-test-2-simple/report.html
	rm -f results/gombe-blinded-test-2/report.html
	rm -f results/gombe-round24/report.html
	# Summary spreadsheets
	rm -f results/gme-mplex/summary.csv
	rm -f results/gme/summary.csv
	rm -f results/gombe-blinded-test-2-full/summary.csv
	rm -f results/gombe-blinded-test-2-simple/summary.csv
	rm -f results/gombe-blinded-test-2/summary.csv
	rm -f results/gombe-round24/summary.csv


# As above, but also including all input data and the CHIIMP directory.
veryclean: clean
	rm -f data/raw/*
	rm -f data/prepared/*
	rmdir data/raw
	rmdir data/prepared
	rm -rf chiimp/
	rm -rf results/

### Other stuff

# The SRA metadata table.  This info should already be in the local copy, but
# here's a way to fetch it.
SRP = SRP132984
RunInfoTable.csv:
	wget -O $@ "http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=runinfo&term=$(SRP)"

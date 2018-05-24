# Non-Invasive Genotyping of Wild Chimpanzees Using High Throughput Microsatellite Sequencing

This directory contains supporting analysis code for the microsatellite
genotyping paper submitted to Ecology and Evolution (in review).

This code repository as stored on GitHub does not contain data files or the 
microsatellite analysis program, [CHIIMP], itself.  These will be downloaded
automatically at run-time from the SRA BioProject entry and the program's GitHub
page:

 * https://www.ncbi.nlm.nih.gov/bioproject/PRJNA434411
 * https://github.com/ShawHahnLab/chiimp

The version archived on Dryad includes a snapshot of all code and data as
published.  In that case the scripts here will use the same input data and
program version as used for the published paper to generate a selection of
figures presented.

## Usage

This code requires a Linux environment with these programs available:

 * Common Utilities:
   * [GNU Bash](https://www.gnu.org/software/bash/)
   * [GNU Awk](https://www.gnu.org/software/gawk/)
   * [GNU Make](https://www.gnu.org/software/make/)
 * [R](https://www.r-project.org/) (libraries will be installed automatically)
 * [Pandoc](http://pandoc.org/)
 * [SRA Toolkit](https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/), if data
   files not already present
 * [Cutadapt](https://github.com/marcelm/cutadapt), if data files not already
   present

If the requirements are satisfied, running the `make` command from within this
directory will run all steps to generate output in the "results" directory.  If
make reports "Nothing to be done for 'all'," run `make clean` first to remove
any existing output files.

## Organization

 * `Makefile`: All processing rules to download data and software, run the
   analysis, and generate figures
 * `fetch_data.sh`: Script to download raw data from
   [the SRA entry](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA434411)
 * `data/`: Sequence files
   * `raw/`: Raw read files as created by the associated MiSeq runs
   * `prepared/`: Processed version of the files in `data/raw` for use in the
     analysis
 * `metadata/`: supporting spreadsheets describing the data files and analysis
   * `locus_attrs.csv` Microsatellite locus attributes
   * `known_alleles.csv`:  Short allele names presented in summaries
   * `known_genotypes.csv`: Genotypes of known individuals used in analysis
   * `sample_attrs.csv`: A combined sample attributes table, listing all
     columns submitted to the SRA as well as our own metadata.  This is used to
     prepare dataset spreadsheets during analysis.
 * `chiimp/`: The microsatellite analysis program, [CHIIMP]
 * `results/`: the output of all analysis here
 * `figures.Rmd`: Post-processing R Markdown script using output of [CHIIMP] to
    generate some of the published figures.
 * `config/` [CHIIMP] configuration files for each dataset

### Datasets

The numbering of the datasets in the metadata spreadsheets corresponds to:

 1. Known Gombe samples
 2. New Gombe samples
 3. GME samples, PCR singleplex
 4. GME samples, PCR multiplex

[CHIIMP]: https://github.com/ShawHahnLab/chiimp

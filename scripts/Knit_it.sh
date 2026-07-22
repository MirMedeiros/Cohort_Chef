#!/bin/bash
#SBATCH --time=3:0:0
#SBATCH --ntasks=1
#SBATCH --mem=4G
#SBATCH --account=$RAP_ID
#SBATCH --job-name=Knit_Report


# assign arguments:
outdir=$1

# load module
module load mugqic/R_Bioconductor/4.3.2_3.18

# Knit it
Rscript Knit_it.R

# copy output to output_directory:
cp custom_report.html ${outdir}

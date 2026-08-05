#!/bin/bash
#SBATCH --time=6:0:0
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --account=$RAP_ID
#SBATCH --job-name=PLINK_generate_refs


# load modules
module load StdEnv/2023 plink/2.00-20231024-avx2


#################################
####         GRCh38          ####
#################################

# decompress files
plink2 --zst-decompress all_hg38.pgen.zst all_hg38.pgen
plink2 --zst-decompress all_hg38.pvar.zst all_hg38.pvar

# ensure same samples are in both references:
awk '!/^#/ {print "0", $1}' all_hg37.psam > samples.txt

# Clean and convert to plink binary files:
plink2 --pfile all_hg38 \
--memory 55000 \
--max-alleles 2 \
--allow-extra-chr \
--keep samples.txt \
--chr 1-22 \
--maf 0.05 \
--hwe 0.000001 midp \
--geno 0.02 \
--set-all-var-ids @:#:\$1:\$2 \
--new-id-max-allele-len 1000 \
--make-bed \
--snps-only \
--out 1KG_hg38_maf_hwe_geno



#################################
####         GRCh37          ####
#################################

# decompress files
plink2 --zst-decompress all_hg37.pgen.zst all_hg37.pgen
plink2 --zst-decompress all_hg37.pvar.zst all_hg37.pvar

# Clean and convert to plink binary files:
plink2 --pfile all_hg37 \
--memory 55000 \
--max-alleles 2 \
--allow-extra-chr \
--chr 1-22 \
--maf 0.05 \
--hwe 0.000001 midp \
--geno 0.02 \
--set-all-var-ids @:#:\$1:\$2 \
--new-id-max-allele-len 1000 \
--make-bed \
--snps-only \
--out 1KG_hg37_maf_hwe_geno


#########################
# Clean up:
rm all_hg3*.p*

mv 1KG_hg3*_maf_hwe_geno* ../lib

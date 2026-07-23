#!/bin/bash

########################################################
#                                                      #
#                  PULLING 1KG FILES                   #
#                                                      #
########################################################

#################################
####         GRCh38          ####
#################################

wget -L "https://www.dropbox.com/s/j72j6uciq5zuzii/all_hg38.pgen.zst?dl=1" -O all_hg38.pgen.zst
wget -L "https://www.dropbox.com/scl/fi/fn0bcm5oseyuawxfvkcpb/all_hg38_rs.pvar.zst?rlkey=przncwb78rhz4g4ukovocdxaz&dl=1" -O all_hg38.pvar.zst
wget -L "https://www.dropbox.com/scl/fi/u5udzzaibgyvxzfnjcvjc/hg38_corrected.psam?rlkey=oecjnk4vmbhc8b1p202l0ih4x&dl=1" -O all_hg38.psam

wget -L "https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel" -O all_hg38.ref

sed -i 's/super_pop/SuperPop/g' all_hg38.ref
sed -i 's/sample/IID/g' all_hg38.ref

#################################
####         GRCh37          ####
#################################

wget -L "https://www.dropbox.com/s/y6ytfoybz48dc0u/all_phase3.pgen.zst?dl=1" -O all_hg37.pgen.zst
wget -L "https://www.dropbox.com/s/odlexvo8fummcvt/all_phase3.pvar.zst?dl=1" -O all_hg37.pvar.zst
wget -L "https://www.dropbox.com/scl/fi/haqvrumpuzfutklstazwk/phase3_corrected.psam?rlkey=0yyifzj2fb863ddbmsv4jkeq6&dl=1" -O all_hg37.psam

wget -L "https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel" -O all_hg37.ref

cp all_hg38.ref all_hg37.ref


#########################
# Clean up PLINK files: #
#########################

sbatch --account=$RAP_ID PLINK_commands_1KG.sh


########################################################
#                                                      #
#               PULLING BLACKLIST FILES                #
#                                                      #
########################################################

#################################
####         GRCh38          ####
#################################

wget -L "http://mitra.stanford.edu/kundaje/akundaje/release/blacklists/hg38-human/hg38.blacklist.bed.gz" -O hg38-blacklist.bed


#################################
####         GRCh37          ####
#################################

wget -L "https://www.encodeproject.org/files/ENCFF001TDO/@@download/ENCFF001TDO.bed.gz" -O hg37-blacklist.bed

mv *blacklist.bed ../lib
mv all_hg*.ref ../lib

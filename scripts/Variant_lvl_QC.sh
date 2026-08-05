#!/bin/bash
#SBATCH --time=3:0:0
#SBATCH --ntasks=1
#SBATCH --mem=4G
#SBATCH --account=$RAP_ID
#SBATCH --job-name=Variant_lvl_QC

################# SET UP VARIABLES #################

genpipes_dir=$1
output_dir=$3
genome_build=$4
genome_ref=/cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh${genome_build}/genome/Homo_sapiens.GRCh${genome_build}.fa
VCF=${genpipes_dir}/Sample_QC/Post_Sample_QC_Post_VQSR.vcf.gz
P_DIR=$(echo "$PWD" | sed 's|/[^/]*$||')
cp ${P_DIR}/lib/hg${genome_build}-blacklist.bed ${genpipes_dir}
BL=${genpipes_dir}/hg${genome_build}-blacklist.bed 
OUTNAME=varQC_Post_sampleQC


# make outdir and navigate to it:
mkdir ${genpipes_dir}/Sample_QC/Variant_QC
cd ${genpipes_dir}/Sample_QC/Variant_QC

############### SET FILTERING CUTOFFS  ##################
GQ=20
DP=$2   #20 for WES and 10 for WGS - defined by config file


########## INDEX VCF ##########
module load ngstools/1.0.1 StdEnv/2023 gcc/12.3
tabix -p vcf ${VCF}

######## REMOVE BLACKLIST ##########
# load modules:
module unload ngstools/1.0.1 StdEnv/2023 gcc/12.3
module load StdEnv/2023
module load gatk/4.6.1.0
module load python/3.13.2 


bcftools view \
  -T ^${BL}  \
  -Oz -o blacklist_filtered_VQSR.vcf.gz ${VCF}

# index:
module load ngstools/1.0.1 StdEnv/2023 gcc/12.3
tabix -p vcf blacklist_filtered_VQSR.vcf.gz

# set up proper modules again:
module unload ngstools/1.0.1 StdEnv/2023 gcc/12.3
module load StdEnv/2023
module load gatk/4.6.1.0
module load python/3.13.2

########### START VARIANT FILTERING ####################
# QG:
gatk VariantFiltration \
  -R $genome_ref \
  -V blacklist_filtered_VQSR.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --genotype-filter-expression "GQ < ${GQ}" \
  --genotype-filter-name "GQ${GQ}" \
  --set-filtered-genotype-to-no-call \
  --missing-values-evaluate-as-failing

# remove flagged variants:
gatk SelectVariants \
  -R $genome_ref \
  -V ${OUTNAME}_GQ${GQ}.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}_filtered.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --exclude-filtered \
  --exclude-non-variants

# DP:
gatk VariantFiltration \
  -R $genome_ref \
  -V ${OUTNAME}_GQ${GQ}_filtered.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}_DP${DP}.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --genotype-filter-expression "DP < ${DP}" \
  --genotype-filter-name "DP${DP}" \
  --set-filtered-genotype-to-no-call \
  --missing-values-evaluate-as-failing

# remove flagged:
gatk SelectVariants \
  -R $genome_ref \
  -V ${OUTNAME}_GQ${GQ}_DP${DP}.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}_DP${DP}_filtered.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --exclude-filtered \
  --exclude-non-variants

# MISSINGNESS:
gatk SelectVariants \
  -R $genome_ref \
  -V ${OUTNAME}_GQ${GQ}_DP${DP}_filtered.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}_DP${DP}_MISS_filtered.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --max-nocall-fraction 0.05 \
  --exclude-filtered \
  --exclude-non-variants



##### HWE #####
# load in modules:
module load StdEnv/2023
module load vcftools/0.1.16

# start HWE:
vcftools \
--gzvcf ${OUTNAME}_GQ${GQ}_DP${DP}_MISS_filtered.vcf.gz \
--hwe 0.00001 \
--recode \
--out ${OUTNAME}

bgzip -c ${OUTNAME}.recode.vcf > ${OUTNAME}_MISS_HWE10e5_PASSED.vcf.gz


###### Allelic Balance #######
# load module:
module load picard/3.1.0

java -jar $EBROOTPICARD/picard.jar FilterVcf \
--INPUT ${OUTNAME}_MISS_HWE10e5_PASSED.vcf.gz \
--MIN_AB 0.2 \
--OUTPUT ${OUTNAME}_MISS_HWE10e5_PASSED_AB.vcf.gz


# load appropriate modules:
module unload mugqic/python/3.10.4
module load StdEnv/2023 gcc/12.3
module load gatk/4.6.1.0
module load python/3.13.2

# remove flagged variants:
gatk SelectVariants \
 -R $genome_ref \
 -V ${OUTNAME}_MISS_HWE10e5_PASSED_AB.vcf.gz  \
 -O ${OUTNAME}_MISS_HWE10e5_PASSED_AB_filtered.vcf.gz \
 --java-options "-Xmx7g"  --exclude-filtered  --exclude-non-variants

###############################################################

# set list of files to counts
list_files=(blacklist_filtered_VQSR.vcf.gz varQC_Post_sampleQC_GQ20_filtered.vcf.gz varQC_Post_sampleQC_GQ20_DP${DP}_filtered.vcf.gz varQC_Post_sampleQC_GQ20_DP${DP}_MISS_filtered.vcf.gz varQC_Post_sampleQC_MISS_HWE10e5_PASSED.vcf.gz varQC_Post_sampleQC_MISS_HWE10e5_PASSED_AB_filtered.vcf.gz)

## Get counts
output="variant_counts_next.csv"

# Get chromosomes from first file
for CN in {1..22} X Y; do echo "chr"${CN}; done > chrom_list.txt

# Build header:
echo "CHROM,Blacklist + VQSR,GQ >20,DP > 20,Missingess < 5%,HWE PASS,Allele Balance" > "$output"

# Per chromosome counts
while read chrom; do
    row="$chrom"
    for f in "${list_files[@]}"; do
        count=$(bcftools query -f '%CHROM\n' "$f" | grep -w "^${chrom}$" | wc -l)
        row="${row},${count}"
    done
    echo "$row" >> "$output"
done < chrom_list.txt


# Total row
row="TOTAL"
for f in "${list_files[@]}"; do
    total=$(bcftools view -H "$f" | wc -l)
    row="${row},${total}"
done
echo "$row" >> "$output"

######
# Rename final file: 
mv varQC_Post_sampleQC_MISS_HWE10e5_PASSED_AB_filtered.vcf.gz ${output_dir}/BestSamples_FullQC.vcf.gz
mv variant_counts_next.csv ${output_dir}

##################################################################
#
## REPEAT EVERYTHING FOR THE NO SAMPLES REMOVED FILE ###
#

### VCF name (where no samples were removed):
VCF=${genpipes_dir}/Sample_QC/VQSR_Pass_vcf.gz


########## INDEX VCF ##########
module load ngstools/1.0.1 StdEnv/2023 gcc/12.3
tabix -p vcf ${VCF}

######## REMOVE BLACKLIST ##########
# load modules:
module unload ngstools/1.0.1 StdEnv/2023 gcc/12.3
module load StdEnv/2023
module load gatk/4.6.1.0
module load python/3.13.2 


bcftools view \
  -T ^${BL}  \
  -Oz -o blacklist_filtered_VQSR.vcf.gz ${VCF}

# index:
module load ngstools/1.0.1 StdEnv/2023 gcc/12.3
tabix -p vcf blacklist_filtered_VQSR.vcf.gz

# set up proper modules again:
module unload ngstools/1.0.1 StdEnv/2023 gcc/12.3
module load StdEnv/2023
module load gatk/4.6.1.0
module load python/3.13.2

########### START VARIANT FILTERING ####################
# QG:
gatk VariantFiltration \
  -R $genome_ref \
  -V blacklist_filtered_VQSR.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --genotype-filter-expression "GQ < ${GQ}" \
  --genotype-filter-name "GQ${GQ}" \
  --set-filtered-genotype-to-no-call \
  --missing-values-evaluate-as-failing

# remove flagged variants:
gatk SelectVariants \
  -R $genome_ref \
  -V ${OUTNAME}_GQ${GQ}.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}_filtered.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --exclude-filtered \
  --exclude-non-variants

# DP:
gatk VariantFiltration \
  -R $genome_ref \
  -V ${OUTNAME}_GQ${GQ}_filtered.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}_DP${DP}.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --genotype-filter-expression "DP < ${DP}" \
  --genotype-filter-name "DP${DP}" \
  --set-filtered-genotype-to-no-call \
  --missing-values-evaluate-as-failing

# remove flagged:
gatk SelectVariants \
  -R $genome_ref \
  -V ${OUTNAME}_GQ${GQ}_DP${DP}.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}_DP${DP}_filtered.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --exclude-filtered \
  --exclude-non-variants

# MISSINGNESS:
gatk SelectVariants \
  -R $genome_ref \
  -V ${OUTNAME}_GQ${GQ}_DP${DP}_filtered.vcf.gz \
  -O ${OUTNAME}_GQ${GQ}_DP${DP}_MISS_filtered.vcf.gz \
  --java-options "-Xmx7g" \
  --tmp-dir ${SLURM_TMPDIR} \
  --max-nocall-fraction 0.05 \
  --exclude-filtered \
  --exclude-non-variants



##### HWE #####
# load in modules:
module load StdEnv/2023
module load vcftools/0.1.16

# start HWE:
vcftools \
--gzvcf ${OUTNAME}_GQ${GQ}_DP${DP}_MISS_filtered.vcf.gz \
--hwe 0.00001 \
--recode \
--out ${OUTNAME}

bgzip -c ${OUTNAME}.recode.vcf > ${OUTNAME}_MISS_HWE10e5_PASSED.vcf.gz


###### Allelic Balance #######
# load module:
module load picard/3.1.0

java -jar $EBROOTPICARD/picard.jar FilterVcf \
--INPUT ${OUTNAME}_MISS_HWE10e5_PASSED.vcf.gz \
--MIN_AB 0.2 \
--OUTPUT ${OUTNAME}_MISS_HWE10e5_PASSED_AB.vcf.gz


# load appropriate modules:
module unload mugqic/python/3.10.4
module load StdEnv/2023 gcc/12.3
module load gatk/4.6.1.0
module load python/3.13.2

# remove flagged variants:
gatk SelectVariants \
 -R $genome_ref \
 -V ${OUTNAME}_MISS_HWE10e5_PASSED_AB.vcf.gz  \
 -O ${OUTNAME}_MISS_HWE10e5_PASSED_AB_filtered.vcf.gz \
 --java-options "-Xmx7g"  --exclude-filtered  --exclude-non-variants

###############################################################

# set list of files to counts
list_files=(blacklist_filtered_VQSR.vcf.gz varQC_Post_sampleQC_GQ20_filtered.vcf.gz varQC_Post_sampleQC_GQ20_DP${DP}_filtered.vcf.gz varQC_Post_sampleQC_GQ20_DP${DP}_MISS_filtered.vcf.gz varQC_Post_sampleQC_MISS_HWE10e5_PASSED.vcf.gz varQC_Post_sampleQC_MISS_HWE10e5_PASSED_AB_filtered.vcf.gz)

## Get counts
output="variant_counts_noSamplesRemoved.csv"

# Get chromosomes from first file
for CN in {1..22} X Y; do echo "chr"${CN}; done > chrom_list.txt

# Build header:
echo "CHROM,Blacklist + VQSR,GQ >20,DP > 20,Missingess < 5%,HWE PASS,Allele Balance" > "$output"

# Per chromosome counts
while read chrom; do
    row="$chrom"
    for f in "${list_files[@]}"; do
        count=$(bcftools query -f '%CHROM\n' "$f" | grep -w "^${chrom}$" | wc -l)
        row="${row},${count}"
    done
    echo "$row" >> "$output"
done < chrom_list.txt


# Total row
row="TOTAL"
for f in "${list_files[@]}"; do
    total=$(bcftools view -H "$f" | wc -l)
    row="${row},${total}"
done
echo "$row" >> "$output"

###
# Rename:
mv varQC_Post_sampleQC_MISS_HWE10e5_PASSED_AB_filtered.vcf.gz ${output_dir}/FullCohort_FullQC.vcf.gz
mv variant_counts_noSamplesRemoved.csv ${output_dir}

## Clean
#rm varQC*
#rm black*
#rm chrom_list.txt
#rm ${BL}

#!/bin/bash
#SBATCH --time=6:0:0
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --account=$RAP_ID
#SBATCH --job-name=OC_run_full


# Assign Directory:
out_dir=$1
Genome_build=$2

# Setup OpenCRAVAT
module purge
module load StdEnv/2023  python/3.11.5
source oc_env/bin/activate

cd ${out_dir}

# CLEAN VCF:
bcftools annotate -x ^FORMAT/AD,^FORMAT/DP,^FORMAT/FT,^FORMAT/GQ,^FORMAT/GT,^FORMAT/MIN_DP,^FORMAT/PGT,^FORMAT/PID,^FORMAT/PL,^FORMAT/PS,^FORMAT/RGQ,^FORMAT/SB,^INFO/AC,^INFO/AF,^INFO/AN,^INFO/ANN,^INFO/BaseQRankSum,^INFO/DP,^INFO/END,^INFO/ExcessHet,^INFO/FS,^INFO/InbreedingCoeff,^INFO/MLEAC,^INFO/MLEAF,^INFO/MQ,^INFO/MQRankSum,^INFO/QD,^INFO/RAW_MQandDP,^INFO/ReadPosRankSum,^INFO/SOR FullCohort_FullQC.vcf.gz  -O z -o cleaned_fullQC.vcf.gz

# run
oc run cleaned_fullQC.vcf.gz -l hg${Genome_build} -a alphamissense bayesdel cadd clinvar clingen ensembl_regulatory_build esm1b gerp gnomad4 go metarnn ncbigene omim revel spliceai vest ucscgenomebrowser dbsnp -t excel -d ./ --mp 8


# Make a copy of the sqlite to use for filtering 
cp cleaned_fullQC.vcf.gz.sqlite filtered_cleaned_fullQC.vcf.gz.sqlite

# start filtering sqlite
sqlite3 filtered_cleaned_fullQC.vcf.gz.sqlite <<EOF
-- 1. Eliminate common variants
DELETE FROM variant
WHERE 
    (gnomad4__af >= 0.05)
    OR 
    -- 2. Eliminate variants where fewer than 2 tools agree are pathogenic (from alphamissense, revel, and cadd) 
    (
        (
            (COALESCE(alphamissense__am_class, '') = 'likely_pathogenic') +
            (COALESCE(revel__score, 0) >= 0.644) +
            (COALESCE(cadd__phred, 0) >= 20)
        ) < 2
    );

-- 3. Clean up sub tables to prevent ghost entries
DELETE FROM sample WHERE base__uid NOT IN (SELECT base__uid FROM variant);
DELETE FROM mapping WHERE base__uid NOT IN (SELECT base__uid FROM variant);

-- 4. Rename the input file paths (Fixed SQL Escaping)
UPDATE info 
SET colval = 'prioritized_variants.vcf' 
WHERE colkey = 'Input file name';

UPDATE info 
SET colval = '{''0'': ''prioritized_variants.vcf''}' 
WHERE colkey = '_input_paths';  

-- 5. Rebuild and compress the database
VACUUM;
EOF

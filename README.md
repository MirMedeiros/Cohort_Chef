# Cohort Chef 👩‍🍳 
This pipeline takes in a joint called vcf from GenPipes v.6.1.0 and provides additional sample level and variant level quality control. A full html report is then written describing the cohort quality control.

```text
  --------------------                    .----.
   ___      _                _           (      )
 / ___|___ | |__   ___  _ __| |_         |`----'|
| |   / _ \|  _ \ / _ \| '__| __|        || | | |         ___________________________
| |__| (_) | | | | (_) | |  | |_       .-'-'-'-'- .      /         Alright.          \
 \____\___/|_| |_|\___/|_|   \__|     /            \   <    Let's get this cohort     |
  / ___| |__   ___ / _|              |   . ＾▽＾ .  |    \         cooking!          /
 | |   |  _ \ / _ \ |_                \            /       -------------------------
 | |___| | | |  __/  _|                '-.______.-'
  \____|_| |_|\___|_|                   /   \/   \
                                       /    /\    \
```

## Requirements:
This pipeline is designed to run on Digital Research Alliance of Canada (DRAC) hosted servers and work on the output of GenPipes v.6.1.0. As such you must ensure that your environment is configured as per the requirements of GenPipes v.6.1.0 described here: https://genpipes.readthedocs.io/en/genpipes-v6.1.0/deploy/access_gp_pre_installed.html

The modules loaded throughout this pipeline are as follows:
```text
StdEnv/2023
gcc/12.3
bcftools/1.22
gatk/4.4.0.0
python/3.13.2
plink/2.00-20231024-avx2
r/4.5.0
ngstools/1.0.1
gatk/4.6.1.0
vcftools/0.1.16
picard/3.1.0
```

The R packages used in this pipeline are as follows:
The modules loaded throughout this pipeline are the following:
```text
ggplot2
dplyr
tidyr
knitr
DT
plotly
```

You can check if all these dependencies are satisfied and if any are missing by running the `Check_dependencies.sh` script from the dependencies folder. Just type `bash Check_dependencies.sh` and the modules and libraries you have and need will be listed. If you are missing any of the R libraries, the `Check_dependencies.sh` script will ask you if you wish to install them. Type "y" to initiate this installation.

Note: The genome reference file is set to `/cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh38/genome/Homo_sapiens.GRCh38.fa` if this is not to your liking please find and change the path for the "hg38ref" variable in the `Sample_lvl_QC.sh` and `Variant_lvl_QC.sh` scripts to change the reference.  

## Quick Start
### Config File
**A config file is necessary to run the pipeline.** 
You will simply need to indicate 4 pieces of information to start cooking:
1. What directory you ran genpipes in
2. Whether your dataset is whole exome (WES) or whole genome sequencing (WGS)
3. Where you want your QCd data outputed
4. The clinical recorded sex of your samples (if available). If not available you must indicate "NONE".

Take this example config file and modify it with your own details leaving the varibles names unchanged:
```text
genpipes_dir = ~/projects/Miranda/genpipes
WES_or_WGS = WES
output_dir = ~/projects/Miranda/chef_out
clinical_sex_file_with_path = ~/projects/Miranda/clinical_sexes.txt
```

Note that you must indicate WES for exome sequencing data or WGS for genome sequencing data. The clinical_sex_file_with_path parameter is optional but highly recommended to include as providing this file means we can do a sex check of your samples. If there is no clinical sex file, please write "NONE" or leave is entry blank. 

The clinical sex file should look as follows:
```text
Sample_1  F
Sample_2  M
Sample_3  F
```

The clinical sex file is tab delimited with each row capturing a sample ID and that sample's recorded sex. Ensure that you denote female samples by "F" and male samples by "M". Also ensure your sample IDs match the sample IDs within your VCF.  

### How to run
Simply navigate to the directory where you have downloaded the script and run the `Master.sh` script as follows with your Conf file as input. Chef will take care of it from there.  

```text
bash MasterQC.sh Conf_file.txt
```

A summary of the run will be written to final_report.txt, please check this file to ensure the pipeline ran with no errors.

Your QCd files along with some QC summaries will be found in your indicated output directory along with the **custom_report.html** where you will find a full explanation of your cohort QC.

Happy cooking! 🍳 

## How the pipeline works
The Cohort Chef pipeline will QC your WES or WGS cohort joint-called VCF. This is done at the sample level and the variant level for your cohort. 

### QC at the sample level
Many QC parameters at the sample level were already obtained via GenPipes. These included Chimeric Reads, Contamination, Mean Depth, and Call Rate. Cohort Chef leverages these existing files as well as generating addition ones necessary for QC. These additional files includes the Sample Mean Genotype Quality (GQ) which is computed at the sample level for all samples in the cohort using BCFtools. Relatedness is calculated using the KING implementation in PLINK. Ancestry and sample cohort prinical components (PCs) are calculated in PLINK. Sex imputation and check (if available) is done with PLINK.

**Summary of Sample QC Steps:**

**- Chimeric Reads:** samples with >5% chimeric reads are removed 

**- Contamination:** samples with >5% contamination are removed

**- Mean Depth:** samples with outlier mean depth are removed

**- Mean Genotype Quality:** samples with outlier mean quality are removed

**- Missingness:** samples with outlier missingess are removed 

**- Relatedness:** samples must have no relations of 2nd degree or closer, or else at least one sample of the related pair will be removed.

**- Ancestry:** sample ancestry can be infered by principal component analysis with the 1000 Genomes Project as ancestry reference samples. The generated HTML report from Cohort Chef will allow you to inspect your samples to see if any do not match with your expected cohort. The chef will not remove samples based on their ancestry, this will be up to you to decide who ought to be retained or removed based on the *"Prinicipal Component Analysis (PCA) Population Overlay"* figure found in your HTML report file.

**- Sex Check:** This step can only be done if you provided a clinical sex file to the Cohort Chef. If this information is provided, you will find the list of samples with discordant sex in the HTML report file in *Table 3: Samples with discordant sex*. Be wary of these samples since they do not match with your clinical recordings they may not be the samples you think they are, these should be removed from your cohort.


### QC at the variant level
Variant level quality control directly follows sample level quality control for the **BestSamples_FullQC.vcf.gz** file. Conversely, for the **FullCohort_FullQC.vcf.gz** file, no samples are removed and variant quality control is done directly on the *allSamples.hc.vqsr.vt.mil.snpId.snpeff.dbnsfp.vcf.gz* file. 

For both files, at the variant level, quality control can be summarized as per the following tables:

**Summary of Variant QC Steps:**

**- VQSR flagged variants and variants overlapping with the ENCODE Blacklist are removed.** Variant Quality Score Recalibration (VQSR) is a score from GATK which identifies probable artifacts across the VCF callset. These are simply flagged in the GenPipes VCF output but we remove this in the rigorous QC steps as these variants are likely problematic. Any variants which overlap with problematic regions of the genome recorded in the ENCODE Blacklist are removed from the VCF. The ENCODE Blacklist is a comprehensive list of anomalous, unstructured, and otherwise untrustworthy genomic regions.

**- Variants with quality (GQ) below 20 are removed.** A quality cut-off of 20 is a typical threshold for sequencing data. We apply this standard threshold here where any variant below this threshold is removed.

**- Variants with depth (DP) below 20 for WES or below 10 for WGS are removed.** A depth cut-off of 20 is a typical and forgiving threshold for WES data whereas 10 is typical for WGS. We apply this standard threshold here where any variant below this threshold is removed.

**- Variants which are missing across more than 5% of samples in the cohort are removed.** This step is done to ensure that the variants which we are looking at are indeed reasonably recorded across the majority of samples within the cohort. It is important to not just have good quality variants but also to make sure these variants are consistently present across 95% of samples.

**- Hardy-Weinberg Equilibrium (HWE) filtering.** Variants which significantly deviate away from expected HWE genotype frequencies (our selected p-value cut-off =1x10e5) represent genotyping errors and artifacts. These significant variants are removed from the VCF.

**- Allele Balance (AB) heterozygous variant filtering.** Variant genotypes are called as homozygous or heterozygous based on the allelic balance of reads. In theory a homozygous call should be supported by 100% of reads (either all reference or all alternative), whereas a heterozygous call should have 50% of reads be of the reference allele and the other 50% be the alternative allele. In practice these numbers are not as clear cut, so we define a minimum allele balance threshold of 0.2 for heterozygous reads. This means that any heterozygous call where one of the two alleles has fewer than 20% of reads is deemed an ambiguous call and removed from the dataset.


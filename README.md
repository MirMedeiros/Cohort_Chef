# Cohort Chef 👩‍🍳 
This pipeline takes in a joint called vcf from GenPipes v.6.1.0 and provides additional sample level and variant level quality control. A full html report is then written describing the cohort quality control.

```text
  --------------------                    .----.
   ___      _                _           (      )
 / ___|___ | |__   ___  _ __| |_         |`----'|
| |   / _ \|  _ \ / _ \| '__| __|        || | | |         ___________________________
| |__| (_) | | | | (_) | |  | |_       .-'-'-'-'- .      /         Alright.          \
 \____\___/|_| |_|\___/|_|   \__|     /            \   <    Let's get this cohort     |
  / ___| |__   ___ / _|              |   . ＾▽＾ .   |    \         cooking!          /
 | |   |  _ \ / _ \ |_                \            /       -------------------------
 | |___| | | |  __/  _|                '-.______.-'
  \____|_| |_|\___|_|                   /   \/   \
                                       /    /\    \
```

## Requirements:
This pipeline is designed to run on Digital Research Alliance of Canada (DRAC) hosted servers and work on the output of GenPipes v.6.1.0. As such you must ensure that your environment is configured as per the requirements of GenPipes v.6.1.0 described here: https://genpipes.readthedocs.io/en/genpipes-v6.1.0/deploy/access_gp_pre_installed.html

In brief, this means that after logging into your DRAC account you should have your Bash profiles set up as follows:

**open bash_profile**
`user@machine:~$ nano $HOME/.bash_profile`

Next, you need to load the software modules in your shell environment. These are required to run GenPipes as well as Cohort Chef. Paste the following lines of code into the .bash_profile, save it, then exit (Ctrl-X). Start a new shell to source these environment variables:

```text
umask 0006

## GenPipes/MUGQIC genomes and modules
export MUGQIC_INSTALL_HOME=/cvmfs/soft.mugqic/CentOS6
module use $MUGQIC_INSTALL_HOME/modulefiles
module load mugqic/genpipes/<latest_version>
export JOB_MAIL=<my.name@my.email.ca>
export RAP_ID=<my-rap-id>
The full list of modules available on the DRAC servers can be accessed via the module page.
```

Within the above bash configuration text you must replace the text in “<>” with your DRAC account specific information.

**JOB_MAIL** is the environment variable that needs to be set to the email ID on which GenPipes and Cohort Chef job status notifications are sent corresponding to each job initiated by your account. It is advised that you create a separate email for jobs since you can receive hundreds of emails per pipeline. You can also de-activate the email sending in the individual Bash scripts of Cohort Chef.

**RAP_ID** is the Resource Allocation Project ID from DRAC. It is usually in the format: rrg-lab-xy OR def-lab.

**REQUIRED MODULES AND PACKAGES**

The modules loaded throughout this pipeline are as follows:
```text
StdEnv/2023
gcc/12.3
bcftools/1.22
gatk/4.4.0.0
python/3.13.2
python/3.11.5
plink/2.00-20231024-avx2
mugqic/R_Bioconductor/4.3.2_3.18
ngstools/1.0.1
gatk/4.6.1.0
vcftools/0.1.16
picard/3.1.0
```

The R packages used in this pipeline should already be installed in the mugqic/R_Bioconductor/4.3.2_3.18 module. The required P packages are as follows:

```text
ggplot2
dplyr
tidyr
knitr
DT
plotly
```

You can check if all these dependencies are satisfied and if any are missing by running the `Check_dependencies.sh` script from the dependencies folder. Just type `bash Check_dependencies.sh` and the modules and libraries you have and need will be listed. If you are missing any of the R libraries, the `Check_dependencies.sh` script will ask you if you wish to install them. Type "y" to initiate this installation.

**OpenCRAVAT**

If you will be running OpenCRAVAT, you will need to first install it by running the `Activate_OpenCRAVAT.sh` script once on it's own:
```text
bash Activate_OpenCRAVAT.sh
```
This will create a python environment for OpenCravat to run in and install all the required annoations modules. The annotation modules will be placed in a new directory called `/OC_modules`. This subdirectory will be nested in the directory where you've place this github pull so ensure you have 139 GB of free space available to house this data. Please note that you will have to answer a few prompts while installing OpenCRAVAT, for these select "No" when asked *Enter 'No' or 'Opt Out' to opt out of providing an email address.* and select "y" to installing modules. Note that the installation of OpenCravat and it's dependent annotation modules will take a while to complete. After this initial installation, OpenCRAVAT (oc) commands can be run after activating the environment `source oc_env/bin/activate`.

*Already have the OpenCRAVAT annotation modules installed someplace?:* Don't worry, you don't have to reinstall them again. When running `Activate_OpenCRAVAT.sh` you will be asked *"Do you already have OpenCRAVAT modules installed elsewhere and want to use them? (y/n):"*. If you select "n" for no, you will be asked to *"Enter the full path to your existing OpenCRAVAT modules directory:"* where you can indicate where the annotation modules are installed to avoid re-download. Otherwise you will install 139GB worth of data.

Note: The genome reference file is set to either `/cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh38/genome/Homo_sapiens.GRCh38.fa` or `/cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh37/genome/Homo_sapiens.GRCh37.fa` depending on if you select "38" for GRCh38 or "37" GRCh37.

## Getting Started
### ❗️Important! Before your first time using the tool you must ensure the following
Make sure that before you first run Cohort Chef you have generated all reference data. Navigate to the scripts directory and run: 
```text
bash Generate.sh
``` 
This will pull and QC 1000 Genomes Phase 3 reference data for GRCh38 and GRCh37 genome builds (Source:  A global reference for human genetic variation, The 1000 Genomes Project Consortium, Nature 526, 68-74 (01 October 2015) doi:10.1038/nature15393). This will also pull the ENCODE Blacklists for the GRCh38 and GRCh37 genome builds (Source: Amemiya, H.M., Kundaje, A. & Boyle, A.P. The ENCODE Blacklist: Identification of Problematic Regions of the Genome. Sci Rep 9, 9354 (2019). https://doi.org/10.1038/s41598-019-45839-z).

Ensure that if you will be running OpenCravat that you have activated the tool by running:
```text
bash Activate_OpenCRAVAT.sh
```

Also ensure you have all the necessary modules by running:
```text
bash Check_dependencies.sh
```

## How to run Cohort Chef
After you have run `Check_dependencies.sh` to ensure you have all the required modules and libraries are there, and you have run `Activate_OpenCRAVAT.sh` for the first time, you are ready to run the Cohort Chef pipeline. Simply navigate to the directory where you have downloaded the script and run the `Master.sh` script as follows with your Conf file as input. Chef will take care of it from there.  

```text
bash MasterQC.sh Conf_file.txt
```

A summary of the run will be written to final_report.txt, please check this file to ensure the pipeline ran with no errors.

Your QCd files along with some QC summaries will be found in your indicated output directory along with the **custom_report.html** where you will find a full explanation of your cohort QC.

## Config File
**A config file is necessary to run the pipeline.** 
You will simply need to indicate 6 pieces of information to start cooking:
1. What directory you ran genpipes in
2. Whether your dataset is whole exome (WES) or whole genome sequencing (WGS): Pick either "WES" or "WGS"
3. Where you want your QCd data outputed
4. The clinical recorded sex of your samples (if available). If not available you must indicate "NONE".
5. What OpenCravat protocol you want to run to create an SQLite to visualize the data: Pick one of "Standard" or "Cancer" or "NONE"
6. What genome build you are using. One of two options: if using GRCh38, indicate: 38. If using GRCh37, indicate: 37. 

Take this example config file and modify it with your own details leaving the varibles names unchanged:
```text
genpipes_dir = ~/projects/Miranda/genpipes
WES_or_WGS = WES
output_dir = ~/projects/Miranda/chef_out
clinical_sex_file_with_path = ~/projects/Miranda/clinical_sexes.txt
OpenCRAVAT = Standard
Genome_build = 38
```

Note that you must indicate WES for exome sequencing data or WGS for genome sequencing data. The clinical_sex_file_with_path parameter is optional but highly recommended to include as providing this file means we can do a sex check of your samples. If there is no clinical sex file, please write "NONE" or leave is entry blank. 

The clinical sex file should look as follows:
```text
Sample_1  F
Sample_2  M
Sample_3  F
```

The clinical sex file is tab delimited with each row capturing a sample ID and that sample's recorded sex. Ensure that you denote female samples by "F" and male samples by "M". Also ensure your sample IDs match the sample IDs within your VCF.  

Running the OpenCRAVAT "Standard" protocol will annotate the VCF and generate an SQLite with the following annotations: alphamissense bayesdel cadd clinvar clingen ensembl_regulatory_build esm1b gerp gnomad4 go metarnn ncbigene omim revel spliceai vest ucscgenomebrowser dbsnp 

Running the OpenCRAVAT "Cancer" protocol will annotate the VCF and generate an SQLite with the same annotations as "Standard" but also the following cancer specific annotations: mutationtaster oncokb civic civic_gene.

Running OpenCRAVAT with "NONE" will not run OpenCRAVAT and will skip the generation of an SQLite file.

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

Happy cooking! 🍳 

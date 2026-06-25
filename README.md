# Cohort Chef 👩‍🍳 
This pipeline takes in a joint called vcf from GenPipes v.6.1.0 and provides additional sample level and variant level quality control. A full html report is then written describing the cohort quality control.

```text
  --------------------                     .----.
                                          (      )
    ___      _                _           |`----'|
  / ___|___ | |__   ___  _ __| |_         || | |||         ___________________________
 | |   / _ \|  _ \ / _ \| '__| __|      .-''''''''-.      /         Alright.          \
 | |__| (_) | | | | (_) | |  | |_      /            \   <    Let's get this cohort     |
  \____\___/|_| |_|\___/|_|   \__|    |   o ＾▽＾ o  |    \         cooking!          /
  / ___| |__   ___ / _|                \            /       -------------------------
 | |   |  _ \ / _ \ |_                  '-.______.-'
 | |___| | | |  __/  _|                  /        \
  \____|_| |_|\___|_|                   /____/\____\
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

Note: The genome reference file is set to `/cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh38/genome/Homo_sapiens.GRCh38.fa` if this is not to your liking please find and change the path for the "hg38ref" variable in the Sample_lvl_QC.sh and Variant_lvl_QC.sh scripts to change the reference.  

## Quick Start
### Config File
You will simply need to indicate 4 pieces of information to start cooking:
1. What directory you ran genpipes in
2. Whether your dataset is whole exome (WES) or whole genome sequencing (WGS)
3. Where you want your QCd data outputed
4. The clinical recorded sex of your samples (if available). If not available you must indicate "NONE".

 
This required information must be written to a config file as follows:
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
Simply navigate to the directory where you have downloaded the script and run the Master.sh script as follows with your Conf file as input. Chef will take care of it from there.  

```text
bash MasterQC.sh Conf_file.txt
```

A summary of the run will be written to final_report.txt, please check this file to ensure the pipeline ran with no errors.

Your QCd files along with some QC summaries will be found in your indicated output directory along with the **custom_report.html** where you will find a full explanation of your cohort QC.

Happy cooking! 🍳 

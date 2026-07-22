#!/bin/bash
#SBATCH --time=3:0:0
#SBATCH --ntasks=1
#SBATCH --mem=4G
#SBATCH --account=$RAP_ID
#SBATCH --job-name=final_cleanup



## Assign Outpur Directory:
output_dir=$1

# remove temp files:
rm ${output_dir}/report_header.png 
rm ${output_dir}/Seq_pipeline_diagram.png
rm custom_report.Rmd 

# move files to correct directory:
mv final_report.txt ${output_dir}/pipeline_report.txt

# mkdir to organize outputs:
mkdir ${output_dir}/full_QC_VCFs
mkdir ${output_dir}/support_files

# move files into these directories:
mv ${output_dir}/*vcf.gz ${output_dir}/full_QC_VCFs
mv ${output_dir}/*.txt ${output_dir}/support_files
mv ${output_dir}/support_files/pipeline_report.txt ${output_dir}/pipeline_report.txt
mv ${output_dir}/*png ${output_dir}/support_files
mv ${output_dir}/*eigen* ${output_dir}/support_files
mv ${output_dir}/*.csv ${output_dir}/support_files
mv ${output_dir}/*.list ${output_dir}/support_files
mv ${output_dir}/cleaned_fullQC.vcf.gz.err ${output_dir}/support_files
mv ${output_dir}/cleaned_fullQC.vcf.gz.log ${output_dir}/support_files
rm ${output_dir}/full_QC_VCFs/cleaned_fullQC.vcf.gz

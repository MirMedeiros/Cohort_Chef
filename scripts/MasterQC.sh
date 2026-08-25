#!/bin/bash

###################### HOW TO RUN #########################
#                                                         #
##           bash MasterQC.sh <Config File>              ##
#                                                         #
###########################################################


## This job will start 2 SLURM Jobs:
# The first job is for Sample QC
# The second job is for Variant QC

####################################
#        SET UP CONFIG FILE        #
####################################
# Take the details from the config file to set up scripts:
# 1. Check if a config file argument was passed
if [ -z "$1" ]; then
    echo "ERROR: Please provide the config file as an argument."
    echo "Usage: bash ./MasterQC.sh path/to/config.txt"
    echo "   "
    cat << "EOF"

       .----.
      (      )
      |`----'|
      || | | |         ___________________________________
    .-'-'-'-'- .      /                Uh oh.              \
   /            \   <      Looks like we're missing our     |
  |  . 0   0  .  |    \  ingredients. Plz add config file  /
   \     ^ '    /       ----------------------------------
    '-.______.-'
     /   \/   \
    /    /\    \

EOF
    exit 1
fi


# Print the graphic:
# Print our extra-cute pipeline chef mascot
cat << "EOF"

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

EOF

echo "Initializing pipeline dependencies..."
echo "    "


# SET UP
P_DIR=$(echo "$PWD" | sed 's|/[^/]*$||')
CONFIG_FILE="$1"

# 2. Verify the file actually exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file '$CONFIG_FILE' not found!"
    exit 1
fi

echo "Reading configuration from: $CONFIG_FILE"

# 3. Parse the config file and dynamically create Bash variables
# This loop strips spaces around the '=' and evaluates each line as a Bash variable
while IFS='=' read -r key value; do
    # Skip empty lines or comment lines starting with #
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    
    # Strip leading/trailing whitespace from key and value
    clean_key=$(echo "$key" | xargs)
    clean_value=$(echo "$value" | xargs)
    
    # Set the variable dynamically in the current shell environment
    declare "$clean_key"="$clean_value"
done < "$CONFIG_FILE"


# 3a. Conditional logic for DP threshold based on WES or WGS
if [ "$WES_or_WGS" = "WES" ]; then
    DP=20
    echo "Data type recognized as WES. Setting DP threshold to: $DP"
elif [ "$WES_or_WGS" = "WGS" ]; then
    DP=10
    echo "Data type recognized as WGS. Setting DP threshold to: $DP"
else
    echo "ERROR: WES_or_WGS must be either 'WES' or 'WGS'. Found: '$WES_or_WGS'"
    exit 1
fi

# -------------------------------------------------------------
# The necessary variables are now fully loaded and ready:
# -------------------------------------------------------------
echo "   "
echo "--- Summary of loaded variables ---"
echo "Genpipes Directory:    $genpipes_dir"
echo "Output Directory:      $output_dir"
echo "Clinical Sex File:     $clinical_sex_file_with_path"
echo "Assigned DP:           $DP"
echo "OpenCRAVAT Protocol:   $OpenCRAVAT"
echo "Genome Build:          $Genome_build"
echo "-----------------------------------"
echo "    "



## 3b - if not clinical file supplied run an alternative script:
CLEAN_SEX=$(echo "$clinical_sex_file_with_path" | xargs)

if [[ -z "$CLEAN_SEX" || "$clinical_sex_file_with_path" == "NONE" ]]; then
    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "!! Clinical sex is empty or set to NONE. Sex-check will not be run. If you wish to run sex-check please supply clinical sex file with path in config file."
    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "   "


    ## RUN THIS SCRIPT WITH NO SEX INPUT
    JOB1_OUT=$(sbatch --account=$RAP_ID no_clinical_Sample_lvl_QC.sh  "$genpipes_dir" "$output_dir" "$Genome_build")
    JOB1_ID=$(echo "$JOB1_OUT" | awk '{print $4}')

    echo "    "
    echo "Submitted Sample QC (Job ID: $JOB1_ID)"

else

    # Run job 1 with sex check and  wait for it to finish before running job 2:
    ## START JOB 1: FULL SAMPLE QC
    # (We capture the submission output and use awk or cut to extract just the numeric Job ID)
    JOB1_OUT=$(sbatch --account=$RAP_ID Sample_lvl_QC.sh "$genpipes_dir" "$clinical_sex_file_with_path" "$output_dir" "$Genome_build")
    JOB1_ID=$(echo "$JOB1_OUT" | awk '{print $4}')

    echo "    "
    echo "Submitted Sample QC (Job ID: $JOB1_ID)"

fi


# START JOB 2: VARIANT QC
# (We tell Slurm to hold this job until Job 1 finishes successfully using afterok)
JOB2_OUT=$(sbatch --dependency=afterok:$JOB1_ID --account=$RAP_ID Variant_lvl_QC.sh "$genpipes_dir" "$DP" "$output_dir" "$Genome_build")
JOB2_ID=$(echo "$JOB2_OUT" | awk '{print $4}')

echo "    "
echo "Submitted Variant QC (Job ID: $JOB2_ID) - Waiting for Job $JOB1_ID to finish."


## Prepare for Markdown file:
cp ${P_DIR}/lib/Build_Report.Rmd custom_report.Rmd
cp ${P_DIR}/lib/all_hg37.ref  ${output_dir}/all_hg.ref

cp ${P_DIR}/lib/report_header.png  ${output_dir}
cp ${P_DIR}/lib/Seq_pipeline_diagram.png ${output_dir}
cp ${P_DIR}/lib/OC_annotations.png ${output_dir}

# modify to have the custom path:
sed -i "s,<OUT_PATH>,${output_dir},g" custom_report.Rmd


# knit report:
module load mugqic/R_Bioconductor/4.3.2_3.18
JOB3_OUT=$(sbatch --dependency=afterok:$JOB2_ID --account=$RAP_ID Knit_it.sh "$output_dir")

JOB3_ID=$(echo "$JOB3_OUT" | awk '{print $4}')

echo "    "
echo "Submitted HTML Report Knit (Job ID: $JOB3_ID) - Waiting for Job $JOB2_ID to finish."


# OPENCRAVAT. Conditional logic for if we're going to run OpenCRAVAT
if [ "$OpenCRAVAT" = "Standard" ]; then
    JOB4_OUT=$(sbatch --dependency=afterok:$JOB3_ID --account=$RAP_ID Standard_CRAVAT_run.sh "$output_dir" "$Genome_build")
    JOB4_ID=$(echo "$JOB4_OUT" | awk '{print $4}')

    echo " "
    echo "--------------------------------------------------------------------------------------------------------------------------------------------"
    echo "Will run Standard Protocol for OpenCRAVAT. You will recieve two annotated SQLite files. One will be filtered down to top PRIORITIZED VARIANTS"
    echo "--------------------------------------------------------------------------------------------------------------------------------------------"
    echo " "

    JOB5_OUT=$(sbatch --dependency=afterany:$JOB4_ID --account=$RAP_ID \
       --job-name="pipeline_reporter" \
       --output="${output_dir}/final_report.txt" \
       --time=00:02:00 \
       --mem=1G \
       --wrap="echo \"=========================================\" && \
               echo \"   CHEF'S PIPELINE EXUCUTION REPORT      \" && \
               echo \"   Generated: \$(date)            \" && \
               echo \"=========================================\" && \
               echo \"\" && \
               sacct -j $JOB1_ID,$JOB2_ID,$JOB3_ID,$JOB4_ID --format=JobID,JobName%30,State,ExitCode && \
               echo \"\" && \
               echo \"=========================================\"")

    JOB5_ID=$(echo "$JOB5_OUT" | awk '{print $4}')

    echo " "
    echo "Submitted OpenCRAVAT (Job ID: $JOB4_ID) - Waiting for Job $JOB3_ID to finish."
    echo " "
    echo "Submitted Pipeline Reporter (Job ID: $JOB5_ID) - Waiting for Job $JOB4_ID to finish."
    echo " "

    ## CLEAN UP:
    sbatch --dependency=afterany:$JOB5_ID --account=$RAP_ID clean_up.sh "$output_dir"

elif [ "$OpenCRAVAT" = "Cancer"  ]; then
    JOB4_OUT=$(sbatch --dependency=afterok:$JOB3_ID --account=$RAP_ID Cancer_CRAVAT_run.sh "$output_dir" "$Genome_build")
    JOB4_ID=$(echo "$JOB4_OUT" | awk '{print $4}')
    
    echo " "
    echo "--------------------------------------------------------------------------------------------------------------------------------------------"
    echo "Will run Cancer Protocol for OpenCRAVAT. You will recieve two annotated SQLite files. One will be filtered down to top PRIORITIZED VARIANTS"
    echo "--------------------------------------------------------------------------------------------------------------------------------------------"
    echo " "

    ### Create a report file:
    JOB5_OUT=$(sbatch --dependency=afterany:$JOB4_ID --account=$RAP_ID \
       --job-name="pipeline_reporter" \
       --output="${output_dir}/final_report.txt" \
       --time=00:02:00 \
       --mem=1G \
       --wrap="echo \"=========================================\" && \
               echo \"   CHEF'S PIPELINE EXUCUTION REPORT      \" && \
               echo \"   Generated: \$(date)            \" && \
               echo \"=========================================\" && \
               echo \"\" && \
               sacct -j $JOB1_ID,$JOB2_ID,$JOB3_ID,$JOB4_ID --format=JobID,JobName%30,State,ExitCode && \
               echo \"\" && \
               echo \"=========================================\"")

    JOB5_ID=$(echo "$JOB5_OUT" | awk '{print $4}')

    echo " "
    echo "Submitted OpenCRAVAT (Job ID: $JOB4_ID) - Waiting for Job $JOB3_ID to finish."
    echo " "
    echo "Submitted Pipeline Reporter (Job ID: $JOB5_ID) - Waiting for Job $JOB4_ID to finish."
    echo " "

    ## CLEAN UP:
   sbatch --dependency=afterany:$JOB5_ID --account=$RAP_ID clean_up.sh "$output_dir"


else
    echo " "
    echo "No OpenCRAVAT Protocol Selected. OpenCRAVAT will not run."
    echo " "
   ### Create a report file:
   JOB4_OUT=$(sbatch --dependency=afterany:$JOB3_ID --account=$RAP_ID \
       --job-name="pipeline_reporter" \
       --output="${output_dir}/final_report.txt" \
       --time=00:02:00 \
       --mem=1G \
       --wrap="echo \"=========================================\" && \
               echo \"   CHEF'S PIPELINE EXUCUTION REPORT      \" && \
               echo \"   Generated: \$(date)            \" && \
               echo \"=========================================\" && \
               echo \"\" && \
               sacct -j $JOB1_ID,$JOB2_ID,$JOB3_ID --format=JobID,JobName%30,State,ExitCode && \
               echo \"\" && \
               echo \"=========================================\"")

    JOB4_ID=$(echo "$JOB4_OUT" | awk '{print $4}')
    
    echo " "
    echo "Submitted Pipeline Reporter (Job ID: $JOB4_ID) - Waiting for Job $JOB3_ID to finish."
    echo " "

    ## CLEAN UP:
    sbatch --dependency=afterany:$JOB4_ID --account=$RAP_ID clean_up.sh "$output_dir"
fi


echo "    "
echo "    "
echo "-----------------------------------------------------------------------------------------"
echo "Now we're cooking! Make sure to check the final summary once completed:"
echo "Reporting job queued. The summary will be written to pipeline_report.txt automatically."
echo "-----------------------------------------------------------------------------------------"
echo "  "
echo "-----------------------------------------------------------------------------------------"
echo "You will find your outputs in your specified output directory: "  
echo "$output_dir "
echo "-----------------------------------------------------------------------------------------"
echo "  "

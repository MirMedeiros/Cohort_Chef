#!/bin/bash

# Define the virtual environment directory name
VENV_DIR="oc_env"
P_DIR=$(echo "$PWD" | sed 's|/[^/]*$||')

# 1. First-time Setup: If the environment folder doesn't exist, build it
if [ ! -d "$VENV_DIR" ]; then
    echo "First-time setup detected. Creating Python Virtual Environment..."
    
    # Load Python
    module purge
    module load StdEnv/2023  python/3.11.5


    # Create the venv
    python3 -m venv "$VENV_DIR"
    
    # Activate it immediately to install packages
    source "$VENV_DIR/bin/activate"
    
    echo "Installing OpenCRAVAT and dependencies from requirements.txt..."
    pip install --upgrade pip
    pip install -r ${P_DIR}/lib/requirements.txt
    
    # Make directory for OC modules and set it up for Cravat
    mkdir ${P_DIR}/OC_modules
    oc config md ${P_DIR}/OC_modules

    # Check if OpenCRAVAT modules need initializing
    echo "Downloading baseline OpenCRAVAT modules (hg38)..."
    oc module install-base
    oc module install alphamissense bayesdel cadd clinvar clingen ensembl_regulatory_build esm1b gerp gnomad4 go metarnn ncbigene omim revel spliceai vest ucscgenomebrowser dbsnp excelreporter mutationtaster oncokb civic civic_gene

    echo "Setup complete!"
else
    # 2. Every subsequent run: Just activate the existing environment
    source "$VENV_DIR/bin/activate"
fi

echo "========================================="
echo " OpenCRAVAT Environment Active! "
echo " You can now use the 'oc' command freely."
echo "========================================="

#!/bin/bash
# check_dependencies.sh

PASS=0
FAIL=0

echo "=============================="
echo " Dependency Check"
echo "=============================="

# --- Bash Modules ---
echo ""
echo "Checking modules..."

required_modules=(
    "StdEnv/2023"
    "gcc/12.3"
    "bcftools/1.22"
    "gatk/4.4.0.0"
    "python/3.13.2"
    "plink/2.00-20231024-avx2"
    "r/4.5.0"
    "ngstools/1.0.1"
    "gatk/4.6.1.0"
    "vcftools/0.1.16"
    "picard/3.1.0"
)

for mod in "${required_modules[@]}"; do
    if module is-avail "$mod" 2>/dev/null; then
        echo "  [OK]   $mod"
        ((PASS++))
    else
        echo "  [FAIL] $mod -- not available"
        ((FAIL++))
    fi
done


# --- Module Summary ---
echo ""
echo "=============================="
echo " Modules: $PASS OK, $FAIL missing"
echo "=============================="

if [ $FAIL -gt 0 ]; then
    echo " Some module dependencies are missing. Please install them."
    exit 1
else
    echo " All module dependencies satisfied. Moving on to R package check ..."
fi


# --- R Packages ---
echo ""
echo "Checking R packages..."

module load r/4.5.0

# Define the packages in a Bash array so we can reuse them for installation if needed
R_PKGS=("ggplot2" "dplyr" "tidyr" "knitr" "DT" "plotly")

# Convert Bash array to an R vector string: "ggplot2", "dplyr", ...
R_PKGS_STR=$(printf '"%s",' "${R_PKGS[@]}" | sed 's/,$//')

# Run R script to check packages
Rscript - <<EOF
required <- c($R_PKGS_STR)

pass <- 0
fail <- 0

check <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  [OK]   %s\n", pkg))
    return(1)
  } else {
    cat(sprintf("  [FAIL] %s -- not installed\n", pkg))
    return(0)
  }
}

for (pkg in required) {
  result <- check(pkg)
  if (result == 1) pass <- pass + 1 else fail <- fail + 1
}

cat(sprintf("\nR packages: %d OK, %d missing\n", pass, fail))
if (fail > 0) quit(status = 1)
EOF

# Extract exit status
R_STATUS=$?

# --- Summary & Interactive Prompt ---
echo ""
echo "=============================="

if [ $R_STATUS -ne 0 ]; then
    echo " Warning: Some R dependencies are missing."
    echo "=============================="
    echo ""
    echo "  "
    
    # Text-based popup/prompt asking the user for input
    read -p "Would you like to install the missing R packages now? (y/n): " user_choice
    
    case "$user_choice" in 
        [yY][eE][sS]|[yY]) 
            echo ""
            echo "Starting installation via R..."
            echo "Libraries are cooking up!"
            echo "   "
            echo "    (   ) "
            echo "     |||| "
            echo "   (;'·ω·)       。··°)"
            echo "    /    o―ヽニニフ))"
            echo "   し―-J"
            echo "  "
            # Call R to install only the missing packages automatically
            Rscript -e "required <- c($R_PKGS_STR); missing <- required[!sapply(required, requireNamespace, quietly=TRUE)]; install.packages(missing, repos='https://cloud.r-project.org')"
            
            # Final check to see if installation succeeded
            Rscript -e "required <- c($R_PKGS_STR); if(any(!sapply(required, requireNamespace, quietly=TRUE))) q(status=1)"
            if [ $? -eq 0 ]; then
                echo " All dependencies successfully installed. You're good to go!"
                exit 0
            else
                echo "❌ Some packages failed to install. Please check your internet connection or permissions."
                exit 1
            fi
            ;;
        *)
            echo "Installation cancelled. Please load module r/4.5.0 and install missing libraries manually."
            exit 1
            ;;
    esac
else
    echo " "
    echo "*******************************************************"
    echo " All R dependencies satisfied. You're good to go!"
    echo "=============================="
    exit 0
fi

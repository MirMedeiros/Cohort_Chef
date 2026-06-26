#!/bin/bash
# Check_dependencies.sh

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

# --- R Packages ---
echo ""
echo "Checking R packages..."

module load r/4.5.0

Rscript - <<'EOF'
required <- c("ggplot2", "dplyr", "tidyr", "knitr", "DT", "plotly")

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

for (pkg in c(required)) {
  result <- check(pkg)
  if (result == 1) pass <- pass + 1 else fail <- fail + 1
}

cat(sprintf("\nR packages: %d OK, %d missing\n", pass, fail))
if (fail > 0) quit(status = 1)
EOF

# --- Summary ---
echo ""
echo "=============================="
echo " Modules: $PASS OK, $FAIL missing"
echo "=============================="

if [ $FAIL -gt 0 ]; then
    echo " Some dependencies are missing. Run setup.sh to install them."
    exit 1
else
    echo " All dependencies satisfied. You're good to go!"
    exit 0
fi

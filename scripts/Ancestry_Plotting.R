#!/usr/bin/env Rscript

# Get name of directory:
args <- commandArgs(trailingOnly = TRUE)

dir <- args[1]
genome_build <- args[2]

# plot screeplot:
library(ggplot2)
library(dplyr)
library(tidyr)


### READ in Files:
all_hg <- read.table(paste0(dir,"/all_hg",genome_build,".ref"), header=TRUE)

eigenvals <- read.table(paste0(dir,"/Sample_QC/PCA_ancestry.eigenval"), header = FALSE)
colnames(eigenvals)[1] <- "eigenvalues"
eigenvals$PC <- 1:nrow(eigenvals)

eigenvec <- read.table(paste0(dir,"/Sample_QC/PCA_ancestry.eigenvec"), header = FALSE)
prefix_names <- c("FID", "IID")
num_pcs <- ncol(eigenvec) - length(prefix_names)
colnames(eigenvec) <- c(prefix_names, paste0("PC", seq_len(num_pcs)))

# sample only:
sample_eigenvals <- read.table(paste0(dir,"/Sample_QC/sample.eigenval"), header = FALSE)
colnames(sample_eigenvals)[1] <- "eigenvalues"
sample_eigenvals$PC <- 1:nrow(sample_eigenvals)

sample_eigenvec <- read.table(paste0(dir,"/Sample_QC/sample.eigenvec"), header = FALSE)
num_pcs <- ncol(sample_eigenvec) - length(prefix_names)
colnames(sample_eigenvec) <- c(prefix_names, paste0("PC", seq_len(num_pcs)))

################ Sample Plotting ################

# plot:
ggplot(sample_eigenvals, aes(x = PC, y = eigenvalues)) +
  geom_line(color = "steelblue") +
  geom_point(size = 3, color = "darkblue") +
  # This ensures the X-axis shows whole numbers for each PC
  scale_x_continuous(breaks = 1:nrow(sample_eigenvals)) + 
  labs(title = "Scree Plot",
       subtitle = "Identifying the 'Elbow'",
       x = "Principal Component",
       y = "Eigenvalue") +
  theme_minimal()

ggsave("Cohort_screeplot.png")

## plot just genetic PCs from samples:
# identify outliers:
PC1_mean <- mean(sample_eigenvec$PC1)
PC1_sd <- sd(sample_eigenvec$PC1)
PC1_outlier_thres_up <- PC1_mean + 3*PC1_sd 
PC1_outlier_thres_down <- PC1_mean - 3*PC1_sd 

PC2_mean <- mean(sample_eigenvec$PC2)
PC2_sd <- sd(sample_eigenvec$PC2)
PC2_outlier_thres_up <- PC2_mean + 3*PC2_sd 
PC2_outlier_thres_down <- PC2_mean - 3*PC2_sd

# identify outliers:
sample_outliers <- mutate(sample_eigenvec, Outlier = PC1 > PC1_outlier_thres_up |  PC1 < PC1_outlier_thres_down | PC2 > PC2_outlier_thres_up |  PC2 < PC2_outlier_thres_down)
sample_outliers$Outlier_Status <- ifelse(sample_outliers$Outlier == TRUE, "Outlier", "Good")

# plot:
ggplot(sample_outliers, aes(x = PC1, y = PC2, col = Outlier_Status)) +
     geom_point() +
     scale_colour_manual(values = c("Good" = "blue4", "Outlier" = "red"))

ggsave("Cohort_PCs.png")

########################################################

############## Ancestry Plotting ##################

# Plot Ancestry:
# identify reference ancestries from psam file:
colnames(all_hg)[1] <- "IID"

# select supergroup:
sup <- select(all_hg, IID, SuperPop)

merged <- merge(eigenvec, sup, by="IID", all = TRUE) %>% select(IID, PC1, PC2, SuperPop)

# label samples seperately from the rest in superpop
merged <- merged %>% 
  mutate(SuperPop = replace_na(SuperPop, "Sample"))

# put samples at the end of the dataframe list:
merged <- merged %>%
  arrange(SuperPop == "Sample")


## Plot by layer:
ref = filter(merged, SuperPop != "Sample")
samples = filter(merged, SuperPop == "Sample")

ggplot() +
  # Layer 1: Everything EXCEPT "Sample"
  geom_point(data = ref, mapping = aes(x = PC1, y = PC2, color = SuperPop), 
             alpha = 0.4) + 
  # Layer 2: Only "Sample" (plotted on top)
  geom_point(data = samples, mapping = aes(x = PC1, y = PC2), 
             color = "black", size = 3, shape = 18)
ggsave("Ancestry_PCA_plot.png")

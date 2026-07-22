#!/usr/bin/env Rscript

# Get name of directory:
dir <- commandArgs(trailingOnly = TRUE)

# load library
library("dplyr")

# read in data:
chimer <- read.table(paste0(dir,"/Sample_QC/sample_chimeric.txt"), header = FALSE)
colnames(chimer) <- c("ID", "chimeric")
contam <- read.table(paste0(dir,"/Sample_QC/sample_contamination.txt"), fill = TRUE, header = FALSE)
colnames(contam) <- c("ID", "contamination")
miss <- read.table(paste0(dir,"/variants/allSamples.imiss"), header = TRUE) %>% select(INDV, F_MISS)
colnames(miss) <- c("ID", "MISS")
depth <- read.table(paste0(dir,"/variants/allSamples.idepth"), header = TRUE) %>% select("INDV", "MEAN_DEPTH")
colnames(depth) <- c("ID", "depth")
qual <- read.table(paste0(dir,"/Sample_QC/meanGQ.out"), header = FALSE)
colnames(qual) <- c("ID", "qual")

# merge 'em
sample_QC_metrics <- merge(chimer, contam, by = "ID", all = TRUE) %>% merge(miss, by = "ID", all = TRUE) %>% merge(depth, by = "ID", all = TRUE) %>% merge(qual, by = "ID", all = TRUE) 

# calculate Outliers:
Miss_Out <- mean(sample_QC_metrics$MISS) + 3*sd(sample_QC_metrics$MISS)
Depth_Out <- mean(sample_QC_metrics$depth) - 3*sd(sample_QC_metrics$depth)
Qual_Out <- mean(sample_QC_metrics$qual) - 3*sd(sample_QC_metrics$qual)

# make a dataframe of TRUE FALSE Outlier yes or no at each step:
judgement <- mutate(sample_QC_metrics, chimeric_PASS = chimeric < 0.05) %>% mutate(contamination_PASS = contamination < 0.05) %>% mutate(MISS_PASS = MISS < Miss_Out) %>% mutate(depth_PASS = depth > Depth_Out) %>% mutate(qual_PASS = qual > Qual_Out) %>% select(ID, chimeric_PASS, contamination_PASS, MISS_PASS, depth_PASS, qual_PASS)

# get counts and final list of samples which pass QC:
Chimeric_good <- filter(judgement, chimeric_PASS == TRUE)
Contamination_good <- filter(Chimeric_good, contamination_PASS == TRUE) 
Miss_good <- filter(Contamination_good, MISS_PASS == TRUE) 
Depth_good <- filter(Miss_good, depth_PASS == TRUE) 
final_good <- filter(Depth_good, qual_PASS == TRUE)
good_samples <- select(final_good, ID)

# make file with number of samples passing each step:
passing <- c(
  paste0("Chimeric Pass: ", nrow(Chimeric_good), " samples"),
  paste0("Contamination Pass: ", nrow(Contamination_good), " samples"),
  paste0("Missingness Pass: ", nrow(Miss_good), " samples"),
  paste0("Depth Pass: ", nrow(Depth_good), " samples"),
  paste0("Quality Pass: ", nrow(final_good), " samples")
)

# write to file:
writeLines(passing, "Sample_QC_Passing_by_Step.txt")

# write list of passing samples:
write.table(good_samples, "Samples_passing_QC.list", row.names = FALSE, quote = FALSE)

# write all QC metrics:
write.table(sample_QC_metrics, "Sample_QC_metrics.txt", row.names = FALSE, quote = FALSE)



#########################

# PLOT:
library(ggplot2)
library(tidyr)

# Pivot to long format
sample_QC_long <- sample_QC_metrics %>%
  pivot_longer(
    cols = c(chimeric, contamination, MISS, depth, qual),
    names_to = "metric",
    values_to = "value"
  )

# Plot:
p <- ggplot(sample_QC_long, aes(x = metric, y = value, fill = metric)) +
  geom_violin(trim = FALSE, alpha = 0.7) +
  geom_boxplot(width = 0.1, outlier.shape = NA, fill = "white", alpha = 0.5) +
  facet_wrap(~ metric, scales = "free", nrow = 1) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    strip.text = element_text(face = "bold")
  ) +
  labs(title = "QC Metrics Distribution", x = NULL, y = "Value")

# Save it
ggsave("qc_metrics_plot.png", plot = p, width = 12, height = 6, dpi = 300)

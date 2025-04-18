library(tidyverse)
library(edgebundleR)
library(igraph)
library(ggraph)
library(qqman)
library(patchwork)

# This makes manhattan plots

# Load in sample
depth = "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/VCF/Variants_all.depth.txt"
depth <- read.table(depth, header = FALSE)
head(depth)


# Counting up the depth of samples
class(depth_counts$V3)
depth_counts$V3 <- as.numeric(depth_counts$V3)

depth_counts <- depth %>% count(V3, sort = TRUE)
depth_counts <- subset(depth_counts,(V3!="INDEL"))
depth_counts <- subset(depth_counts,(n>5))

depth_counts_zoomed <- subset(depth_counts,(V3 < 500))


# Graphs for depth
ggplot(data=depth_counts, aes(x=V3)) + 
  geom_histogram(colour="blue", fill="red", bins = 50) + 
  xlab("Depth") + ylab("Count") +
  ggtitle("Depth Counts")  

ggplot(data=depth_counts_zoomed, aes(x=V3)) + 
  geom_histogram(colour="blue", fill="red", bins = 40) + 
  xlab("Depth") + ylab("Count") +
  ggtitle("Depth Counts Zoomed")  

############################################################
## Cross Graphic maker ##
############################################################

# loading in list of predicted parents
pred_parents_loc = "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Lists/usable_predicted_parents_double.csv"
pred_parents <- read.table(pred_parents_loc, header = TRUE, sep = ",")
head(pred_parents)

# counting up unique parents
pred_parents$parent_combo <- 0
for (i in 1:nrow(pred_parents)){
  print(i)
  p1 = pred_parents[i,2]
  p2 = pred_parents[i,3]
  if (p1 > p2){
    pred_parents[i,4] = paste0(p2,"x",p1)
  }
  if (p2 > p1){
    pred_parents[i,4] = paste0(p1,"x",p2)
  }
}

parent_counts <- pred_parents %>% count(parent_combo, sort = TRUE)
parent_counts[c('Parent 1', 'Parent 2')] <- str_split_fixed(parent_counts$parent_combo, 'x', 2)

nodes <- t(cbind(t(pred_parents[,2]), t(pred_parents[,3])))
nodes <- data.frame(nodes) %>% group_by(nodes) %>%
  summarise(count=n())

# Graph
parent_counts2 <- subset(parent_counts, n >= 10)
ggplot(data=parent_counts2, aes(x=reorder(parent_combo, -n), y=n)) +
  geom_bar(colour="grey", fill = "blue", stat = "identity") +
  xlab("Parental Combination") + ylab("Cross Count") +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust=1),
  panel.background = element_rect(fill = 'white', color = 'grey')) 

g <-graph.data.frame(pred_parents[,2:3], directed=F, vertices=nodes)
edgebundle( g )  

plot(g, vertex.size=10, edge.width=edge.betweenness(g))

#########################
# hap map analysis
##########################

#importing data and getting rid of file names
hap_loc = "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/all_maf_5_1960_min.hmp.txt"
hap <- read.table(hap_loc, header = FALSE, sep = '\t', skip = 1)
head(hap)

# Counting up chromosome appearances
variant_locations <- subset(hap, select = c(V1))
variant_locations[c('chrom', 'pos')] <- str_split_fixed(variant_locations$V1, '_', 2)
Chrom_counts <- variant_locations %>% count(chrom, sort = TRUE)


# graphs
Chrom_counts2 <- subset(Chrom_counts, n >= 10)
ggplot(data=Chrom_counts2, aes(x=reorder(chrom, -n), y=n)) +
  geom_bar(colour="grey", fill = "blue", stat = "identity") +
  xlab("Chromosome") + ylab("SNP Count") +
  theme(axis.text.x = element_text(angle = 90, vjust = .5, hjust=1),
  panel.background = element_rect(fill = 'white', color = 'grey'))

############################
# Depth by site and individual
############################


data(mtcars)
dummy_data <- head(mtcars)
dummy_data_num_only <- subset(dummy_data, select = -c(mpg))
individuals <- ncol(dummy_data_num_only)
dummy_data_num_only$sum <- rowSums(dummy_data_num_only, )
dummy_data_num_only$count.0 <- apply(dummy_data_num_only, 1, function(x) length(which(x=="0")))
dummy_data_num_only$diviser <- individuals - dummy_data_num_only$count.0
dummy_data_num_only$Avg.Depth <- (dummy_data_num_only$sum / dummy_data_num_only$diviser)



ggplot(data=dummy_data_num_only, aes(x=Avg.Depth)) + 
  geom_histogram(colour="blue", fill="red", binwidth = 1) + 
  xlab("Depth") + ylab("Count") +
  ggtitle("Depth Counts")  

############################
# Manhattan plot in R
############################

mlm_stats_loc="/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/Linear_Models/MLM_16Pcs_stats.txt"
mlm_stats <- read.table(mlm_stats_loc, header = TRUE, sep = '\t')

mlm_stats$Chr<-gsub("PTG","",as.character(mlm_stats$Chr))
mlm_stats$Chr<-gsub("L","",as.character(mlm_stats$Chr))
mlm_stats$Chr<- as.numeric(mlm_stats$Chr)
mlm_stats <- mlm_stats[-c(1), ]

manhattan(mlm_stats, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", 
          main = "P values of Delta CT", cex = 1, col = c("blue", "red","darkgrey","purple"))
# suggestiveline = F, genomewideline = F (We can take away lines with this) (1e-5, 5e-8)

# Put a line on graph
# geom_hline(yintercept = -log10(sig), color = "grey40", linetype = "dashed")

### The 16 pc GLM with 50 permutations
GLM_16_PCs_loc <- "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/Linear_Models/GLM_16PC_50_Perm_Stats.txt"
GLM_16_PCs <- read.csv(GLM_16_PCs_loc, header = TRUE, strip.white=TRUE, sep = '\t')
GLM_16_PCs$Chr<-gsub("PTG","",as.character(GLM_16_PCs$Chr))
GLM_16_PCs$Chr<-gsub("L","",as.character(GLM_16_PCs$Chr))
GLM_16_PCs$Chr<- as.numeric(GLM_16_PCs$Chr)
GLM_16_PCs <- GLM_16_PCs[-c(1), ]
manhattan(GLM_16_PCs, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", 
          main = "P values of Delta CT", cex = 1, col = c("blue", "red","darkgrey","purple"))

### The 16 pc GLM with 1 permutations residule data
GLM_16_PCs_loc <- "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/Linear_Models/GLM_16PCs_1_perm_residules.txt"
GLM_16_PCs <- read.csv(GLM_16_PCs_loc, header = TRUE, strip.white=TRUE, sep = '\t')
# GLM_16_PCs <- GLM_16_PCs[GLM_16_PCs$Trait == "filtered_CT_model.residuals", ]
GLM_16_PCs <- GLM_16_PCs[GLM_16_PCs$Trait == "alkaloid_model.residuals", ]
GLM_16_PCs$Chr<-gsub("PTG","",as.character(GLM_16_PCs$Chr))
GLM_16_PCs$Chr<-gsub("L","",as.character(GLM_16_PCs$Chr))
GLM_16_PCs$Chr<- as.numeric(GLM_16_PCs$Chr)
GLM_16_PCs <- GLM_16_PCs[-c(1), ]
manhattan(GLM_16_PCs, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", ylim = c(0, 4.2), 
          main = "P values of Alkaloid Data", cex = 1, col = c("blue", "red","darkgrey","purple")) 

# manhattan plot of jsut psudo test cross locations
testcross_stats_loc="/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/Linear_Models/GLM_9_PC_Only_test_cross.txt"
testcross_stats <- read.table(testcross_stats_loc, header = TRUE, sep = '\t')
testcross_stats$Chr<-gsub("PTG","",as.character(testcross_stats$Chr))
testcross_stats$Chr<-gsub("L","",as.character(testcross_stats$Chr))
testcross_stats$Chr<- as.numeric(testcross_stats$Chr)
testcross_stats <- testcross_stats[-c(1), ]
# testcross_stats <- testcross_stats[testcross_stats$Trait == "filtered_CT_model.residuals", ]
testcross_stats <- testcross_stats[testcross_stats$Trait == "alkaloid_model.residuals", ]
manhattan(testcross_stats, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", ylim = c(0, 5),
          main = "P values of alkaloid residual test crosses", cex = 1, col = c("blue", "red","darkgrey","purple"))



### 312x314 analysis
testcross_stats_loc <- "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/Linear_Models/MLM_312x314_65_min_5_maf_stats.txt"
testcross_stats_loc="/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/Linear_Models/GLM_9_PC_Only_test_cross.txt"
testcross_stats <- read.table(testcross_stats_loc, header = TRUE, sep = '\t')
testcross_stats$Chr<-gsub("PTG","",as.character(testcross_stats$Chr))
testcross_stats$Chr<-gsub("L","",as.character(testcross_stats$Chr))
testcross_stats$Chr<- as.numeric(testcross_stats$Chr)
testcross_stats <- testcross_stats[-c(1), ]
# testcross_stats <- testcross_stats[testcross_stats$Trait == "filtered_CT_model.residuals", ]
testcross_stats <- testcross_stats[testcross_stats$Trait == "alkaloid_model.residuals", ]
manhattan(testcross_stats, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", ylim = c(0, 5),
          main = "P values of alkaloid residuals of 314x312", cex = 1, col = c("blue", "red","darkgrey","purple"))




### Manhattan Plot of all 2024 data + outgroup parents
MLM_2024_all_loc <- "/home/darrian/Desktop/UGA/Wallace_Lab/Mapping_and_QTL/Data/Tassel_Outputs/2024_only/MLM_stats_MCR50.txt"
MLM_2024_all <- read.table(MLM_2024_all_loc, header = TRUE, sep = '\t')
MLM_2024_all$Chr<-gsub("SCAFFOLD_","",as.character(MLM_2024_all$Chr))
MLM_2024_all$Chr<- as.numeric(MLM_2024_all$Chr)
MLM_2024_all <- MLM_2024_all[MLM_2024_all$Trait == "ng.g", ]
MLM_2024_all <- MLM_2024_all[-c(1), ]
manhattan(MLM_2024_all, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", ylim = c(0, 5),
          main = "P values of alkaloid 2024 Data", cex = 1, col = c("blue", "red","darkgrey","purple"))




### Manhattan Plot of all 2024 data DRT filtered Delta Alkaloids ****MLM wieghted*****
MLM_DRT_Filters_loc <- "/home/darrian/Desktop/UGA/Wallace_Lab/Mapping_and_QTL/Data/Tassel_Outputs/2024_only/MLM_DRT_FIlters.txt"
MLM_DRT_Filters <- read.table(MLM_DRT_Filters_loc, header = TRUE, sep = '\t')
MLM_DRT_Filters$Chr<-gsub("SCAFFOLD_","",as.character(MLM_DRT_Filters$Chr))
MLM_DRT_Filters$Chr<- as.numeric(MLM_DRT_Filters$Chr)
MLM_DRT_Filters <- MLM_DRT_Filters[MLM_DRT_Filters$Trait == "ng.g", ]
MLM_DRT_Filters <- MLM_DRT_Filters[-c(1), ]
Alkaloid <- manhattan(MLM_DRT_Filters, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", 
                      ylim = c(0, 5), main = "MLM on Alkaloids",
                      col = c("blue", "red", "darkgrey", "purple"))


### Manhattan Plot of all 2024 data DRT filtered Delta CT OG ****MLM wieghted****
MLM_DRT_Filters_loc <- "/home/darrian/Desktop/UGA/Wallace_Lab/Mapping_and_QTL/Data/Tassel_Outputs/2024_only/MLM_DRT_FIlters.txt"
MLM_DRT_Filters <- read.table(MLM_DRT_Filters_loc, header = TRUE, sep = '\t')
MLM_DRT_Filters$Chr<-gsub("SCAFFOLD_","",as.character(MLM_DRT_Filters$Chr))
MLM_DRT_Filters$Chr<- as.numeric(MLM_DRT_Filters$Chr)
MLM_DRT_Filters <- MLM_DRT_Filters[MLM_DRT_Filters$Trait == "Delta_CT_OG", ]
MLM_DRT_Filters <- MLM_DRT_Filters[-c(1), ]
Delta_OG <- manhattan(MLM_DRT_Filters, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", 
                      ylim = c(0, 5), main = "MLM on Delta CT", 
                      col = c("blue", "red", "darkgrey", "purple"))

### Manhattan Plot of all 2024 data DRT filtered Delta CT Adj ****MLM wieghted****
MLM_DRT_Filters_loc <- "/home/darrian/Desktop/UGA/Wallace_Lab/Mapping_and_QTL/Data/Tassel_Outputs/2024_only/MLM_DRT_FIlters.txt"
MLM_DRT_Filters <- read.table(MLM_DRT_Filters_loc, header = TRUE, sep = '\t')
MLM_DRT_Filters$Chr<-gsub("SCAFFOLD_","",as.character(MLM_DRT_Filters$Chr))
MLM_DRT_Filters$Chr<- as.numeric(MLM_DRT_Filters$Chr)
MLM_DRT_Filters <- MLM_DRT_Filters[MLM_DRT_Filters$Trait == "Delta_CT_adj", ]
MLM_DRT_Filters <- MLM_DRT_Filters[-c(1), ]
Delta_Adj <- manhattan(MLM_DRT_Filters, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", 
                       ylim = c(0, 5), main = "MLM on Delta CT Efficiency Adjusted",
                       col = c("blue", "red", "darkgrey", "purple"))


### Manhattan Plot of DRT filtered genotypes with 2024 and 2023 residuals avraged Delta CT adj****
MLM_DRT_Filters_residuals_loc <- "/home/darrian/Desktop/UGA/Wallace_Lab/Mapping_and_QTL/Data/Tassel_Outputs/2024_only/MLM_DRT_filters_Phenotype_residuals_avaraged.txt"
MLM_DRT_Filters_residuals <- read.table(MLM_DRT_Filters_residuals_loc, header = TRUE, sep = '\t')
MLM_DRT_Filters_residuals$Chr<-gsub("SCAFFOLD_","",as.character(MLM_DRT_Filters_residuals$Chr))
MLM_DRT_Filters_residuals$Chr<- as.numeric(MLM_DRT_Filters_residuals$Chr)
MLM_DRT_Filters_residuals <- MLM_DRT_Filters_residuals[MLM_DRT_Filters_residuals$Trait == "DeltaCT_adj_Res_avg", ]
MLM_DRT_Filters_residuals <- MLM_DRT_Filters_residuals[-c(1), ]
# BOnferonii line
alpha <- 0.05
num_tests <- nrow(MLM_DRT_Filters_residuals)  # Number of SNPs or tests
bonferroni_threshold <- alpha / num_tests
# Making FDR threshold
MLM_DRT_Filters_residuals$padj <- p.adjust(MLM_DRT_Filters_residuals$p, method = "BH")
FDR_threshold <- max(MLM_DRT_Filters_residuals$p[MLM_DRT_Filters_residuals$padj <= alpha], na.rm = TRUE)
if (!is.numeric(FDR_threshold) || is.na(FDR_threshold) || FDR_threshold == -Inf) {
  FDR_threshold <- 1e-5
}
print(FDR_threshold)
Delta_Adj <- manhattan(MLM_DRT_Filters_residuals, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", 
                       ylim = c(0, 6), main = "MLM on Delta CT Efficiency Adjusted Residuals Avaraged From 2023 and 2024",
                       genomewideline = -log10(bonferroni_threshold),
                       suggestiveline = -log10(FDR_threshold),
                       col = c("blue", "red", "darkgrey", "purple"))


### Manhattan Plot of DRT filtered genotypes with 2024 and 2023 residuals averaged delta CT OG****
MLM_DRT_Filters_residuals_loc <- "/home/darrian/Desktop/UGA/Wallace_Lab/Mapping_and_QTL/Data/Tassel_Outputs/2024_only/MLM_DRT_filters_Phenotype_residuals_avaraged.txt"
MLM_DRT_Filters_residuals <- read.table(MLM_DRT_Filters_residuals_loc, header = TRUE, sep = '\t')
MLM_DRT_Filters_residuals$Chr<-gsub("SCAFFOLD_","",as.character(MLM_DRT_Filters_residuals$Chr))
MLM_DRT_Filters_residuals$Chr<- as.numeric(MLM_DRT_Filters_residuals$Chr)
MLM_DRT_Filters_residuals <- MLM_DRT_Filters_residuals[MLM_DRT_Filters_residuals$Trait == "DeltaCT_OG_Res_avg", ]
MLM_DRT_Filters_residuals <- MLM_DRT_Filters_residuals[-c(1), ]
# BOnferonii line
alpha <- 0.05
num_tests <- nrow(MLM_DRT_Filters_residuals)  # Number of SNPs or tests
bonferroni_threshold <- alpha / num_tests
# Making FDR threshold
MLM_DRT_Filters_residuals$padj <- p.adjust(MLM_DRT_Filters_residuals$p, method = "BH")
FDR_threshold <- max(MLM_DRT_Filters_residuals$p[MLM_DRT_Filters_residuals$padj <= alpha], na.rm = TRUE)
if (!is.numeric(FDR_threshold) || is.na(FDR_threshold) || FDR_threshold == -Inf) {
  FDR_threshold <- 1e-5
}
print(FDR_threshold)
Delta_OG <- manhattan(MLM_DRT_Filters_residuals, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", 
                       ylim = c(0, 6), main = "MLM on Delta CT Residuals Avaraged From 2023 and 2024",
                       genomewideline = -log10(bonferroni_threshold),
                       suggestiveline = -log10(FDR_threshold),
                       col = c("blue", "red", "darkgrey", "purple"))

### Manhattan Plot of DRT filtered genotypes with 2024 and 2023 residuals averaged Alkaloids****
MLM_DRT_Filters_residuals_loc <- "/home/darrian/Desktop/UGA/Wallace_Lab/Mapping_and_QTL/Data/Tassel_Outputs/2024_only/MLM_DRT_filters_Phenotype_residuals_avaraged.txt"
MLM_DRT_Filters_residuals <- read.table(MLM_DRT_Filters_residuals_loc, header = TRUE, sep = '\t')
MLM_DRT_Filters_residuals$Chr<-gsub("SCAFFOLD_","",as.character(MLM_DRT_Filters_residuals$Chr))
MLM_DRT_Filters_residuals$Chr<- as.numeric(MLM_DRT_Filters_residuals$Chr)
MLM_DRT_Filters_residuals <- MLM_DRT_Filters_residuals[MLM_DRT_Filters_residuals$Trait == "Alkaloids_Res_avg", ]
MLM_DRT_Filters_residuals <- MLM_DRT_Filters_residuals[-c(1), ]
# BOnferonii line
alpha <- 0.05
num_tests <- nrow(MLM_DRT_Filters_residuals)  # Number of SNPs or tests
bonferroni_threshold <- alpha / num_tests
# Making FDR threshold
MLM_DRT_Filters_residuals$padj <- p.adjust(MLM_DRT_Filters_residuals$p, method = "BH")
FDR_threshold <- max(MLM_DRT_Filters_residuals$p[MLM_DRT_Filters_residuals$padj <= alpha], na.rm = TRUE)
if (!is.numeric(FDR_threshold) || is.na(FDR_threshold) || FDR_threshold == -Inf) {
  FDR_threshold <- 1e-5
}
print(FDR_threshold)
Alkaloids <- manhattan(MLM_DRT_Filters_residuals, chr = "Chr", bp = "Pos", p = "p", snp = "Marker", 
                       ylim = c(0, 6), main = "MLM on Alkaloid Level Residuals Avaraged From 2023 and 2024",
                       genomewideline = -log10(bonferroni_threshold),
                       suggestiveline = -log10(FDR_threshold),
                       col = c("blue", "red", "darkgrey", "purple"))




# THis file is created to check heritabilities for the half-sib 2024 data that
# failed to get heritability in tassel.


################################################################################
# heritability function
################################################################################

# Load necessary library
library(rrBLUP)

# Define Data Folder
data_folder = "/home/darrian/Documents/Mapping_and_QTL/Data"

### FUnction to convert hapmap to numerical ###
convert_hapmap_to_rrblup <- function(hapmap_path) {
  # Load hapmap
  hapmap <- read.delim(hapmap_path, header = TRUE, stringsAsFactors = FALSE)
  hapmap <- hapmap[!duplicated(hapmap$`rs.`), ]
  
  # Extract genotype matrix (assumes first 11 columns are metadata)
  geno_data <- hapmap[, -(1:11)]
  rownames(geno_data) <- hapmap$`rs.`  # SNP IDs as rownames
  
  # Define IUPAC heterozygous codes
  iupac_het <- list(
    R = c("A", "G"),
    Y = c("C", "T"),
    S = c("G", "C"),
    W = c("A", "T"),
    K = c("G", "T"),
    M = c("A", "C")
  )
  
  # Function to convert genotype character to numeric rrBLUP code
  convert_genotype <- function(base, major, minor) {
    base <- toupper(base)
    if (base %in% c("N", "./.")) return(NA)
    if (base == major) return(1)
    if (base == minor) return(-1)
    if (base %in% c(paste0(major, "/", minor), paste0(minor, "/", major))) return(0)
    
    for (code in names(iupac_het)) {
      if (base == code && all(c(major, minor) %in% iupac_het[[code]])) return(0)
    }
    return(NA)
  }
  
  # Process each SNP row
  geno_numeric <- t(apply(hapmap, 1, function(row) {
    raw_genos <- as.character(row[12:length(row)])
    alleles <- raw_genos[!raw_genos %in% c("N", "./.")]
    alleles <- unlist(strsplit(alleles, split = "[/|]"))
    alleles <- toupper(alleles[alleles != ""])
    
    # Handle IUPAC codes by expanding them
    for (code in names(iupac_het)) {
      alleles[alleles == code] <- paste(iupac_het[[code]], collapse = "/")
    }
    alleles <- unlist(strsplit(paste(alleles, collapse = "/"), split = "/"))
    
    if (length(alleles) == 0) return(rep(NA, length(raw_genos)))
    
    allele_counts <- sort(table(alleles), decreasing = TRUE)
    major <- names(allele_counts)[1]
    minor <- ifelse(length(allele_counts) > 1, names(allele_counts)[2], NA)
    
    sapply(raw_genos, convert_genotype, major = major, minor = minor)
  }))
  
  # Convert to data frame
  geno_numeric <- as.data.frame(geno_numeric)
  colnames(geno_numeric) <- colnames(geno_data)
  rownames(geno_numeric) <- hapmap$`rs.`
  geno_numeric <- geno_numeric[!duplicated(rownames(geno_numeric)), ]
  
  # Transpose: samples as rows, SNPs as columns
  geno_numeric <- as.data.frame(t(geno_numeric))
  rownames(geno_numeric) <- sub("^X", "", rownames(geno_numeric))
  
  return(geno_numeric)
}


### Define the function to use rrblup ###
calculate_heritability <- function(hapmap_file = NULL, phenotype_file, num_hapmap = NULL) {
  message("hapmap_file: ", is.null(hapmap_file))
  message("num_hapmap: ", is.null(num_hapmap))
  #----------------------------
  # 1. Load your Hapmap file CHange Hapmap to numeric
  #----------------------------
  if (!is.null(hapmap_file)) {
    geno_numeric <- convert_hapmap_to_rrblup(hapmap_file)
  } else if (!is.null(num_hapmap)) {
    geno_numeric <- read.table(num_hapmap, header = TRUE, sep = "\t", stringsAsFactors = FALSE, skip = 1)
    colnames(geno_numeric)[1] <- "ID"
    geno_numeric <- geno_numeric[!duplicated(geno_numeric$ID), ]
    rownames(geno_numeric) <- geno_numeric[[1]]
    geno_numeric <- geno_numeric[, -1]
    geno_numeric <- (geno_numeric*2) -1
  
  } else {
    stop("You must provide either 'hapmap_file' or 'num_hapmap'.")
  }
  #----------------------------
  # 2. Match with phenotype
  #----------------------------
  phenotype  <- read.table(phenotype_file, sep = '\t', header = TRUE)
  phenotype$Alkaloids_Res <- as.numeric(as.character(phenotype$Alkaloids_Res))
  phenotype$Delta_CT_adj_Res <- as.numeric(as.character(phenotype$Delta_CT_adj_Res))
  
  # This actually seems unencessary 
  # # Keep only phenotype rows with matching genotype rows
  # phenotype <- phenotype[phenotype$ID %in% rownames(geno_numeric), ]
  # 
  # # Now reorder genotype rows to match phenotype order(IMPORTANT!)
  # geno_numeric <- geno_numeric[match(phenotype$ID, rownames(geno_numeric)), ]
  
  #----------------------------
  # 3. Run rrBLUP!
  #----------------------------
  kinship = A.mat(geno_numeric)
  
  model_alk_w = kin.blup(data=phenotype, geno="ID", pheno="Alkaloids_Res", K=kinship)
  model_mass_w = kin.blup(data=phenotype, geno="ID", pheno="Delta_CT_adj_Res", K=kinship)
  
  heritability_alk_w <- model_alk_w$Vg / (model_alk_w$Vg + model_alk_w$Ve)
  heritability_mass_w <- model_mass_w$Vg / (model_mass_w$Vg + model_mass_w$Ve)
  
  # Return heritability results
  return(list(
    alkaloid_heritability = heritability_alk_w,
    biomass_heritability = heritability_mass_w,
    n = nrow(geno_numeric)
  ))
}

# Loading hapmat files
# hapmap_file_half_sib <- paste0(data_folder,"/hapmap_files/half_sib_Genos_hapmap.hmp") # Change to your hapmap file path
# hapmap_file_full_pop <- paste0(data_folder,"/hapmap_files/2023_Geno_aligned_to_new_genome.hmp") # Change to your hapmap file path
hapmap_file_half_sib_num <- paste0(data_folder,"/hapmap_files/numeric_snps_half_sibs.txt") # Change to your hapmap file path
hapmap_file_full_pop_num <- paste0(data_folder,"/hapmap_files/numeric_2023_genotypes.txt") # Change to your hapmap file path


phenotype_file_half_sib2024 <- paste0(data_folder,"/Phenotype_Data/3a_data_2024_noOut.txt") # Change to your phenotype file path
phenotype_file_half_sib2023 <- paste0(data_folder,"/Phenotype_Data/3a_data_2023_noOut.txt") # Change to your phenotype file path
phenotype_file_half_sibAVG <- paste0(data_folder,"/Phenotype_Data/3a_half_sib_Residual_data_avg_3d_ready.txt") # Change to your phenotype file path
phenotype_file_full_pop <- paste0(data_folder,"/Phenotype_Data/phenotype_data_heritabilities.txt") # Change to your phenotype file path

# Just using numerical hapmap
result_HSAVG_num <- calculate_heritability(phenotype_file = phenotype_file_half_sibAVG, num_hapmap = hapmap_file_half_sib_num)
result_HSAVG_num

result_HS24_num <- calculate_heritability(phenotype_file = phenotype_file_half_sib2024, num_hapmap = hapmap_file_half_sib_num)
result_HS24_num

result_HS23_num <- calculate_heritability(phenotype_file = phenotype_file_half_sib2023, num_hapmap = hapmap_file_half_sib_num)
result_HS23_num

result_fullPop_num <- calculate_heritability(phenotype_file = phenotype_file_full_pop, num_hapmap = hapmap_file_full_pop_num)
result_fullPop_num





























################################################################################
# proving my method is just is the same as exporting a numerical hapmap file from tassel
################################################################################

############################# Functions needed #################################
compare_rrblup_genotypes <- function(geno1, geno2) {
  # Ensure row and column names are aligned
  common_samples <- intersect(rownames(geno1), rownames(geno2))
  common_snps <- intersect(colnames(geno1), colnames(geno2))
  
  if (length(common_samples) == 0 || length(common_snps) == 0) {
    stop("No overlapping samples or SNPs between the two matrices.")
  }
  
  # Subset and align both matrices
  geno1_sub <- geno1[common_samples, common_snps]
  geno2_sub <- geno2[common_samples, common_snps]
  
  # Flatten matrices to compute overall correlation
  overall_cor <- cor(as.numeric(unlist(geno1_sub)), as.numeric(unlist(geno2_sub)), use = "pairwise.complete.obs")
  return(overall_cor)
}
####################### End FUnctions Needed ###################################

################################ Test ##########################################


num_hapmap <- hapmap_file_half_sib_num
geno_numeric <- read.table(num_hapmap, header = TRUE, sep = "\t", stringsAsFactors = FALSE, skip = 1)
colnames(geno_numeric)[1] <- "ID"
geno_numeric <- geno_numeric[!duplicated(geno_numeric$ID), ]
rownames(geno_numeric) <- geno_numeric[[1]]
geno_numeric <- geno_numeric[, -1]
geno_numeric <- (geno_numeric*2) -1

geno_numeric_me_test <- convert_hapmap_to_rrblup(hapmap_file_half_sib)
scream <- convert_hapmap_to_rrblup(hapmap_file_full_pop)

#making names the same
colnames(geno_numeric_me_test) <- gsub("-", ".", colnames(geno_numeric_me_test), fixed = TRUE)





phenotype  <- read.table(phenotype_file_half_sibAVG, sep = '\t', header = TRUE, skip = 2)
phenotype$Alkaloids_Res <- as.numeric(as.character(phenotype$Alkaloids_Res))
phenotype$Delta_CT_adj_Res <- as.numeric(as.character(phenotype$Delta_CT_adj_Res))

# Keep only phenotype rows with matching genotype rows
phenotype <- phenotype[phenotype$ID %in% rownames(geno_numeric), ]

# Now reorder genotype rows to match phenotype order(IMPORTANT!)
geno_numeric <- geno_numeric[match(phenotype$ID, rownames(geno_numeric)), ]

#----------------------------
# 3. Run rrBLUP!
#----------------------------
kinship = A.mat(geno_numeric)




######################## Wallace Test ##########################################
# Loading hapmat files
hapmap_file_half_sib_num <- paste0(data_folder,"/hapmap_files/numeric_snps_half_sibs.txt") # Change to your hapmap file path

phenotype_file_half_sib2024 <- paste0(data_folder,"/Phenotype_Data/3a_data_2024_noOut.txt") # Change to your phenotype file path
phenotype_file_half_sib2023 <- paste0(data_folder,"/Phenotype_Data/3a_data_2023_noOut.txt") # Change to your phenotype file path
phenotype_file_half_sibAVG <- paste0(data_folder,"/Phenotype_Data/3a_half_sib_Residual_data_avg_3d_ready.txt") # Change to your phenotype file path





library(rrBLUP)
library(tidyverse)


# Check Darrian's rrBLUP calculations

genos = read.delim(hapmap_file_half_sib_num, skip=1, row.names=1)
phenos = list(
  "2023" = read.delim(phenotype_file_half_sib2023),
  "2024" = read.delim(phenotype_file_half_sib2024),
  "resids" = read.delim(phenotype_file_half_sibAVG)
)

# # Log transform
# phenos.log = lapply(phenos, function(p){
#   for(x in names(p)[-1]) {
#     p[,x] = p[,x] - min(p[,x], na.rm=T) + 1
#     p[,x] = log(p[,x])
#   }
#   return(p)
# })
# phenos = phenos.log
# Checking if Phenos are the same 
identical(phenos$resids,phenotype) # CHeck if same (wont be cause of colnames)
setdiff(names(phenos$resids), names(phenotype)) # check col name difference
dim(phenos$resids) # check diminsion 
dim(phenotype)
setdiff(rownames(phenos$resids), rownames(phenotype)) # check rowname differences
all.equal(phenos$resids, phenotype, check.attributes = FALSE) # Check all numeric columns

# run rrBLUP
genos.fixed = genos * 2 -1 
compare_rrblup_genotypes(geno_numeric, genos.fixed) # My genos and Wallaces are same
kinship = A.mat(genos.fixed)
kinship_DRT = A.mat(geno_numeric)
identical(kinship, kinship_DRT)

##### DIfference has to be here!!!! Must be a rounding differences 
# from using a list to get results?????????
results = list()
for(set in names(phenos)){
  myphenos = phenos[[set]]
  for(trait in names(myphenos)[-1]){
    label = paste(set, "-", trait)
    cat(label, "\n")
    myresult = kin.blup(data=myphenos, geno="ID", pheno=trait, K=kinship)
    results[[label]] = myresult
  }
}

herits = lapply(results, function(r){
  r$Vg / (r$Vg + r$Ve)
})


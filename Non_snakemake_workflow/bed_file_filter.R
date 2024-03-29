library(tidyverse)

# Load in sample
# This sample is based off a bam file.
sample_loc = "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Mapped_Reads/320-5-9_depth.txt"
sample <- read.table(sample_loc, header = TRUE)

#Get counts for sample
counts <- sample %>%
  count(X1)

# Remove lower depths
counts <- counts[-c(1,2,3),]


#Display on histogram 
ggplot(data=counts, aes(x=X1, y=n)) + 
  geom_bar(stat = "identity") +
  xlim(0,100) +
  ylim(0,20000) +
  ggtitle("320-5-9 Depth") +
  xlab("regions") + ylab("count")

## Making a .bed file
# This bed file is used to create the parameters in which the bam files of the parents is filtered.
prereg_loc = "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/hap_map_regions.txt"
prereg <- read.table(prereg_loc, header = FALSE)
prereg <- prereg[-1, ]
prereg$V2 <- as.numeric(prereg$V2)
prereg$V3 <- prereg$V2 - 1
prereg$V4 <- prereg$V2 + 1
prereg <- subset(prereg, select = -c(V2))
write.table(prereg,file = "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/VCF/regions_file.bed", sep ="\t", row.names = FALSE, col.names = FALSE)

#### Msking bed file for hap map at 5% maf and 65% occurance
frrr = "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Data/Real_Data/Hap_Map/hap_map_regions.txt"
frrr_pfft <- read.table(frrr, header = TRUE)
head(frrr_pfft)
frrr_pfft$minOne <- frrr_pfft$pos - 1
frrr_pfft$PlusOne <- frrr_pfft$pos + 1
frrr_pfft <- subset(frrr_pfft, select = -c(pos))

write.table(frrr_pfft, file = "/home/drt06/Documents/Tall_fescue/Mapping_and_QTL/Mapping_and_QTL/Non_snakemake_workflow/hap_map_regions2.txt", col.names = NA,
            qmethod = "double")



  







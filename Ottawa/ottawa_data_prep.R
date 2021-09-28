# Script to convert raw Ottawa wastewater data into ODM format

library(tidyverse)
library(readxl)
library(tidyr)

ottawa.df <- readxl::read_excel(file.path(getwd(),
                                          "Ottawa/Data/ottawa_data.xlsx")) 

siteID <- "Ottawa-1"
siteName <- "Ottawa-ROPEC"

if(is.character(ottawa.df$sample_date)){
  if(startsWith(first(ottawa.df$sample_date), "4") == TRUE){
    ottawa.df$sample_date <- as.Date(as.numeric(ottawa.df$sample_date),
                                     origin = "1899-12-30")
  }
}

ottawa.df$outlier <- ifelse(!is.logical(ottawa.df$outlier),
                            as.logical(ottawa.df$outlier),
                            ottawa.df$outlier)

# Create wide table
ottawa_data <- ottawa.df %>%
  select(sample_date, n1_copies_per_copies_pep_avg,
         n1_copies_per_copies_pep_stdev, n2_copies_per_copies_pep_avg,
         n2_copies_per_copies_pep_stdev, ct_pep_avg, outlier, testB117,
         detectB117, fractionB117, fractionB117_stdev) %>%
  rename(sampleDate = "sample_date",
         covN1_nPMMoV_meanMnNr = "n1_copies_per_copies_pep_avg",
         covN1_nPMMoV_sdNr = "n1_copies_per_copies_pep_stdev",
         covN2_nPMMoV_meanMnNr = "n2_copies_per_copies_pep_avg",
         covN2_nPMMoV_sdNr = "n2_copies_per_copies_pep_stdev",
         nPPMoV_Ct_mean = "ct_pep_avg",
         qualityFlag = "outlier") %>%
  mutate(siteID = siteID,
         siteName = siteName) %>%
  relocate(sampleDate, siteID, siteName)
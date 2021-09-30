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
ottawa_wide <- ottawa.df %>%
  select(sample_date, n1_copies_per_copies_pep_avg,
         n1_copies_per_copies_pep_stdev, n2_copies_per_copies_pep_avg,
         n2_copies_per_copies_pep_stdev, ct_pep_avg, outlier, testB117,
         detectB117, fractionB117, fractionB117_stdev) %>%
  rename(sampleDate = "sample_date",
         covN1_nPMMoV_meanNr = "n1_copies_per_copies_pep_avg",
         covN1_nPMMoV_sdNr = "n1_copies_per_copies_pep_stdev",
         covN2_nPMMoV_meanNr = "n2_copies_per_copies_pep_avg",
         covN2_nPMMoV_sdNr = "n2_copies_per_copies_pep_stdev",
         nPPMoV_Ct_mean = "ct_pep_avg",
         qualityFlag = "outlier") %>%
  mutate(siteID = siteID,
         siteName = siteName,
         covN1_nPMMoV_meanNr = round(covN1_nPMMoV_meanNr, digits = 5),
         covN1_nPMMoV_sdNr = round(covN1_nPMMoV_sdNr, digits = 5),
         covN2_nPMMoV_meanNr = round(covN2_nPMMoV_meanNr, digits = 5),
         covN2_nPMMoV_sdNr = round(covN2_nPMMoV_sdNr, digits = 5),
         ) %>%
  relocate(sampleDate, siteID, siteName)

# Save wide table
write.csv(ottawa_wide, file = "Ottawa/Data/wastewater_virus_test.csv",
          row.names = FALSE)

# Create long table
quality_flag <- ottawa_wide %>%
  select(sampleDate, qualityFlag) %>%
  rename(analysisDate = "sampleDate")

ottawa_long <- ottawa_wide %>%
  select(-c("siteID", "siteName", "qualityFlag", "testB117", "detectB117")) %>%
  pivot_longer(!sampleDate, names_to = "type", values_to = "value",
               values_drop_na = TRUE) %>%
  rename(analysisDate = "sampleDate") %>%
  mutate(
    labID = siteID,
    fractionAnalyzed = "solid",
    unit = case_when(
      str_detect(type, "covN1_nPMMoV") ~ "gcPMMoV",
      str_detect(type, "covN2_nPMMoV") ~ "gcPMMoV",
      str_detect(type, "nPPMoV_Ct_mean") ~ "Ct",
      str_detect(type, "fractionB117") ~ "propVar",
      
    ),
    aggregation = case_when(
      str_detect(type, "meanNr") ~ "meanNr",
      str_detect(type, "sdNr") ~ "sdNr",
      str_detect(type, "Ct_mean") ~ "mean",
      str_detect(type, "fractionB117_stdev") ~ "sd",
      str_detect(type, "fractionB117") ~ "single",
    ),
    type = case_when(
      str_detect(type, "covN1") ~ "covN1",
      str_detect(type, "covN2") ~ "covN2",
      str_detect(type, "nPPMoV_Ct_mean") ~ "nPPMoV",
      str_detect(type, "fractionB117") ~ "varB117"
    )) %>%
  full_join(quality_flag, by = "analysisDate") %>%
  mutate(
    accessToPublic = TRUE,
    accessToAllOrg = TRUE,
    accessToSelf = TRUE,
    accessToPHAC = TRUE,
    accessToLocalHA = TRUE,
    accessToProvHA = TRUE,
    accessToOtherProv = TRUE,
    accessToDetails = TRUE) %>%
  relocate(labID, analysisDate, fractionAnalyzed, type)

# Save long table
write.csv(ottawa_long, file = "Ottawa/Data/wwMeasure.csv", row.names = FALSE)
  
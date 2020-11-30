library(SpaDES.core)
library(reproducible)
AM <- TRUE
runName <- '5TSAs'
writeOutputs <- FALSE
readInputs <- TRUE
model <- 'CNRM CM5'
scenario <- 'RCP4.5'
rep <- 1
if (AM) {
  repName <- paste0('AM90yr', rep)
} else {
  repName <- paste0("noAM90yr", rep)
}
outputDir <- file.path('outputs', runName, paste0(model, '-', scenario), repName)
source('global_for_RIA.R')


source('global_dynamic.R')


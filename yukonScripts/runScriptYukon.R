runName <- 'Yukon'
#writeOutputs will write objects from parameterization to disk
writeOutputs <- FALSE
#readInputs will read parameterization objects from disk
readInputs <- FALSE
model <- 'CCSM4'
scenario <- 'RCP4.5'
rep <- 1
outputDir <- file.path('outputs', runName, paste0(model, '-', scenario), paste0(model,"_", rep))
source('yukonScripts/global_Yukon.R')

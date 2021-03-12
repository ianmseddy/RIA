runName <- 'BC' #BC

#writeOutputs will write objects from parameterization to disk
writeOutputs <- FALSE
#readInputs will read parameterization objects from disk
readInputs <- FALSE
model <- 'Access1'
scenario <- 'RCP4.5'
gmcsDriver <- "LandR.CS"

rep <- 'noBEC'
if (gmcsDriver == "LandR.CS"){
outputDir <- file.path('outputs', runName, paste0(model, '-', scenario), paste0(model,"_", rep))
} else {
  outputDir <- file.path("outputs", runName, paste0("noLandRCS_", rep))
}
source('yukonScripts/global_Yukon.R')

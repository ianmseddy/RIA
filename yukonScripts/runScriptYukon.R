runName <- 'Yukon' #BC

#writeOutputs will write objects from parameterization to disk
writeOutputs <- FALSE
#readInputs will read parameterization objects from disk
readInputs <- TRUE
model <- 'CNRM-CM5'
# "Access1"
# "CanESM2"
# "CCSM4"
# "CNRM-CM5"
# "CSIRO-Mk3"
# "INM-CM4"

scenario <- 'RCP4.5'
gmcsDriver <- "LandR.CS"

rep <- 2
if (gmcsDriver == "LandR.CS"){
  outputDir <- file.path('outputs', runName, paste0(model, '-', scenario), paste0(model,"_", rep))
} else {
  outputDir <- file.path("outputs", runName, paste0("noLandRCS/noLandRCS_", rep))
}

source('yukonScripts/global_Yukon.R')


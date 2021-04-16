runName <- 'Yukon' #BC

#writeOutputs will write objects from parameterization to disk
writeOutputs <- FALSE
#readInputs will read parameterization objects from disk
readInputs <- TRUE
model <- 'INM-CM4'
scenario <- 'RCP4.5'
gmcsDriver <- "LandR.CS"

rep <- "noFire"
if (gmcsDriver == "LandR.CS"){
  outputDir <- file.path('outputs', runName, paste0(model, '-', scenario), paste0(model,"_", rep))
} else {
  outputDir <- file.path("outputs", runName, paste0("noLandRCS/noLandRCS_", rep))
}


# outputDir <- file.path("outputs", runName, paste0(model, "-", scenario, "-", "test"), paste0(model, "_", rep))
source('yukonScripts/global_Yukon.R')

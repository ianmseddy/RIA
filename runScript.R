library(SpaDES.core)
library(reproducible)


AM <- FALSE
runName <- '5TSAs'
#writeOutputs will write objects from parameterization to disk
writeOutputs <- FALSE
#readInputs will read parameterization objects from disk
readInputs <- TRUE
model <- 'Access1'
scenario <- 'RCP4.5'
rep <- 1
if (AM) {
  repName <- paste0('AM90yr', rep)
} else {
  repName <- paste0("noAM90yr", rep)
}
outputDir <- file.path('outputs', runName, paste0(model, '-', scenario), paste0(model, repName))

#Try this next run
# drive_auth(email = config::get("cloud")[["googleuser"]], use_oob = quickPlot::isRstudioServer())
# message(crayon::silver("Authenticating as: "), crayon::green(drive_user()$emailAddress))

source('global_for_RIA.R')
source('global_dynamic.R')


library(reticulate)
library(SpaDES)
library(raster)
library(sf)
library(LandR)
library(data.table)

# py_install('ws3', pip=TRUE, pip_options=c('--upgrade', '-e git+https://github.com/gparadis/ws3.git@dev#egg=ws3')) #To upgrade WS3
googledrive::drive_auth(email = "ianmseddy@gmail.com")

basenames <- list("tsa40") #THis must absolutely match whatever studyArea you are going to use for harvest
source("generateHarvestInit.R")

rasterToMatch <- harvestFiles$landscape$age

#Change the TSA to either Ft St John or Ft Nelson
studyArea <- prepInputs(url = 'https://drive.google.com/open?id=16dHisi-dM3ryJTazFHSQlqljVc0McThk',
                        destinationPath = 'inputs',
                        overwrite = TRUE,
                        useCache = TRUE,
                        rasterToMatch = rasterToMatch)
#
# studyAreaLarge <- prepInputs(url = 'https://drive.google.com/open?id=18XPcOKeQdty102dYHizKH3ZPE187BiYi',
#                              destinationPath = 'inputs',
#                              overwrite = TRUE) %>%
#   spTransform(., CRSobj = crs(studyArea))
studyAreaLarge <- studyArea
# rasterToMatchLarge <- prepInputsLCC(studyArea = studyAreaLarge,
#                       destinationPath = 'inputs',
#                       useCache = TRUE,
#                       overwrite = TRUE,
#                       useSAcrs = TRUE,
#                       res = c(250, 250))
rasterToMatchLarge <- rasterToMatch

#For climate scenarios
studyAreaPSP <- prepInputs(url = 'https://drive.google.com/open?id=10yhleaumhwa3hAv_8o7TE15lyesgkDV_',
                          destinationPath = 'inputs',
                          overwrite = TRUE,
                          useCache = TRUE) %>%
  spTransform(., CRSobj = crs(studyArea))

ecoregionRst <- prepInputs(url = 'https://drive.google.com/open?id=1SJf9zQqBcznw5uByfRZ5ulk2ktfHia26',
                          destinationPath = 'inputs',
                          targetFile = 'reclassifiedBECs.grd',
                          alsoExtract = 'reclassifiedBECs.gri',
                          fun = 'raster::stack',
                          rasterToMatch = rasterToMatchLarge,
                          overwrite = TRUE,
                          useCache = TRUE)
ecoregionRst <- ecoregionRst$BECref
standAgeMap <- harvestFiles$landscape$age

times <- list(start = 2011, end = 2050)
source('generateSppEquiv.R')
source('generateSpeciesLayers.R')

spadesModulesDirectory <- file.path("modules") # where modules are
modules <- list('spades_ws3_dataInit', 'spades_ws3','spades_ws3_landrAge',
                "PSP_Clean", 'gmcsDataPrep', 'Biomass_core',
                'LandR_reforestation', 'assistedMigrationBC',
                "scfmIgnition", "scfmEscape", "scfmSpread")
times <- list(start = 2017, end = 2025)


parameters <- list(
  Biomass_speciesData = list(
    sppEquivCol = "RIA",
    type = c("KNN", "CASFRI")),
  Biomass_core = list(
    .plotInitialTime = NA
    , .plotInterval = NA
    , successionTimestep = 2
    , initialBiomassSource = "cohortData"
    , sppEquivCol = "RIA"
    , plotOverstory = TRUE
    , growthAndMortalityDrivers = "LandR.CS"
    , vegLeadingProportion = 0
    , .saveInitialTime = times$start + 10
    , keepClimateCols = FALSE
    , minCohortBiomass = 5
    , cdColsForAgeBins = c('pixelGroup', 'speciesCode')),
  # Biomass_regeneration = list(
  #   fireInitialTime = times$start + 1,
  #   fireTimestep = 1,
  #   successionTimestep = 10),
  assistedMigrationBC = list(
    sppEquivCol = 'RIA'),
  gmcsDataPrep = list(
    useHeight = TRUE,
    GCM = 'CCSM4_RCP4.5'),
  spades_ws3 = list(
    basenames = basenames,
    tifPath = 'tif',
    base.year = 2015,
    scheduler.mode = 'areacontrol',
    horizon = 1,
    target.masks = as.list(paste(basenames, "1 ? ?")), # TSA-wise THLB
    target.scalefactors = as.list(rep(0.80, length(basenames)))),
  spades_ws3_dataInit = list(
    basenames = basenames,
    tifPath = 'tif',
    base.year = 2015,
    hdtPath = 'hdt',
    hdtPrefix = 'hdt_'),
  spades_ws3_landrAge = list(
    basenames = basenames,
    tifPath = 'tif',
    base.year = 2015
  )
)

## Paths are not workign with multiple module paths yet
setPaths(cachePath =  file.path(getwd(), "cache"),
         modulePath = c(file.path(getwd(), "modules"), file.path("modules/scfm/modules")),
         inputPath = file.path(getwd(), "inputs"),
         outputPath = file.path(getwd(),"outputs"))

paths <- SpaDES.core::getPaths()

objects <- list(
  "studyArea" = studyArea #always provide a SA
  , 'studyAreaPSP' = studyAreaPSP
  ,"rasterToMatch" = rasterToMatch
  ,"sppEquiv" = sppEquivalencies_CA
  ,"sppColorVect" = sppColors
  ,"studyAreaLarge" = studyAreaLarge
  ,"rasterToMatchLarge" = rasterToMatchLarge   #always provide a RTM
  ,"biomassMap" = simOutSpp$biomassMap
  ,"cohortData" = simOutSpp$cohortData
  #for climate
  , 'cceArgs' = list(quote(CMI),
                     quote(ATA),
                     quote(CMInormal),
                     quote(mcsModel),
                     quote(gcsModel),
                     quote(transferTable),
                     quote(ecoregionMap),
                     quote(currentBEC),
                     quote(BECkey))
  ,"ecoDistrict" = simOutSpp$ecodistrict
  ,"ecoregion" = simOutSpp$ecoregion
  ,"ecoregionMap" = simOutSpp$ecoregionMap
  ,"pixelGroupMap" = simOutSpp$pixelGroupMap
  ,"minRelativeB" = simOutSpp$minRelativeB
  ,"species" = simOutSpp$species
  ,"speciesLayers" = simOutSpp$speciesLayers
  ,"speciesEcoregion" = simOutSpp$speciesEcoregion
  ,"sufficientLight" =simOutSpp$sufficientLight
  ,"rawBiomassMap" = simOutSpp$rawBiomassMap
  #new Harvest objects
  # ,"landscape" = harvestFiles$landscape
)



opts <- options(
  "future.globals.maxSize" = 1000*1024^2,
  "LandR.assertions" = TRUE,
  "LandR.verbose" = 1,
  "reproducible.futurePlan" = FALSE,
  "reproducible.inputPaths" = NULL,
  "reproducible.quick" = FALSE,
  "reproducible.overwrite" = TRUE,
  "reproducible.useMemoise" = FALSE, # Brings cached stuff to memory during the second run
  "reproducible.useCache" = TRUE,
  "reproducible.cachePath" = paths$cachePath,
  "reproducible.showSimilar" = TRUE, #Always keep this on or scfm will miss cached driver params
  "reproducible.useCloud" = FALSE,
  "spades.moduleCodeChecks" = FALSE, # Turn off all module's code checking
  'spades.recoveryMode' = 1
)


devtools::load_all("LandR")
devtools::load_all("LandR.CS")
set.seed(1110)
thisRunTime <- Sys.time()
mySim <- simInit(times = times, params = parameters, modules = modules, objects = objects,
                 paths = paths, loadOrder = unlist(modules))
rm(harvestFiles, standAgeMap, ecoregionRst, simOutSpp)
amc::.gc()
if (!is.null(py$sys & is.null(py$sys$path))) {
  dev.off()
  dev()
  mySimOut <- spades(mySim, debug = TRUE)
}

library(SpaDES.core)
library(reproducible)
library(raster)
library(sf)
library(data.table)
library(LandR)

runName <- 'Yukon'
#writeOutputs will write objects from parameterization to disk
writeOutputs <- FALSE
#readInputs will read parameterization objects from disk
readInputs <- TRUE
model <- 'CCSM4'
scenario <- 'RCP8.5'
rep <- 1
outputDir <- file.path('outputs', runName, paste0(model, '-', scenario), paste0(model, repName))

# devtools::install_github("PredictiveEcology/LandR@development")
data.table::setDTthreads(2)
#need LandR.CS
googledrive::drive_deauth()

setPaths(inputPath = "inputs/Yukon",
         modulePath = "modules",
         outputPath = 'outputs/Yukon/',
         cachePath = "cache/Yukon")
paths <- getPaths()

#What is the study area in the Yukon?
studyArea <- shapefile("inputs/Yukon/studyAreaYukon.shp")
studyAreaLarge <- studyArea
#We will use BC Albers for the study area because it should result in seamless borders..
rasterToMatch = prepInputsLCC(studyArea = studyArea,
                              destinationPath = 'inputs/Yukon')
rasterToMatch <- Cache(projectRaster,
                       from = rasterToMatch,
                       res = c(250, 250),
                       crs = crs(studyArea),
                       userTags = c("projectraster", "rasterToMatch"))
rasterToMatchLarge <- rasterToMatch

#For climate scenarios - use BC PSP data
studyAreaPSP <- prepInputs(url = 'https://drive.google.com/open?id=10yhleaumhwa3hAv_8o7TE15lyesgkDV_',
                           destinationPath = 'inputs',
                           overwrite = TRUE,
                           useCache = TRUE) %>%
  spTransform(., CRSobj = crs(studyArea))

times <- list(start = 2011, end = 2101)


if (writeOutputs) {
  #dont' worry that gmcs is run without climate data, we will supply it later
  source('yukonScripts/generateSpeciesLayersYukon.R')
  saveRDS(simOutSpp$biomassMap, file.path(paths$outputPath, 'paramData','biomassMap.rds'))
  saveRDS(simOutSpp$cohortData, file.path(paths$outputPath, 'paramData','cohortData.rds'))
  saveRDS(simOutSpp$ecodistrict, file.path(paths$outputPath, 'paramData','ecodistrict.rds'))
  saveRDS(simOutSpp$ecoregion, file.path(paths$outputPath, 'paramData','ecoregion.rds'))
  saveRDS(simOutSpp$ecoregionMap, file.path(paths$outputPath, 'paramData','ecoregionMap.rds'))
  saveRDS(simOutSpp$pixelGroupMap, file.path(paths$outputPath, 'paramData','pixelGroupMap.rds'))
  saveRDS(simOutSpp$minRelativeB, file.path(paths$outputPath, 'paramData','minRelativeB.rds'))
  saveRDS(simOutSpp$species, file.path(paths$outputPath, 'paramData','species.rds'))
  saveRDS(simOutSpp$speciesLayers, file.path(paths$outputPath, 'paramData','speciesLayers.rds'))
  saveRDS(simOutSpp$speciesEcoregion, file.path(paths$outputPath, 'paramData','speciesEcoregion.rds'))
  saveRDS(simOutSpp$sufficientLight, file.path(paths$outputPath, 'paramData','sufficientLight.rds'))
  saveRDS(simOutSpp$rawBiomassMap, file.path(paths$outputPath, 'paramData','rawBiomassMap.rds'))
  saveRDS(simOutSpp$vegMap, file.path(paths$outputPath, 'paramData','vegMap.rds'))
  saveRDS(simOutSpp$landscapeAttr, file.path(paths$outputPath, 'paramData','landscapeAttr.rds'))
  saveRDS(simOutSpp$flammableMap, file.path(paths$outputPath, 'paramData','flammableMap.rds'))
  saveRDS(simOutSpp$cellsByZone, file.path(paths$outputPath, 'paramData','cellsByZone.rds'))
  saveRDS(simOutSpp$fireRegimePolys, file.path(paths$outputPath, 'paramData','fireRegimePolys.rds'))
  saveRDS(simOutSpp$scfmRegimePars, file.path(paths$outputPath, 'paramData','scfmRegimePars.rds'))
  saveRDS(simOutSpp$firePoints, file.path(paths$outputPath, 'paramData','firePoints.rds'))
  saveRDS(simScfmDriver$scfmDriverPars, file.path(paths$outputPath, 'paramData','scfmDriverPars.rds'))
  saveRDS(simOutSpp$fireRegimeRas, file.path(paths$outputPath, 'paramData','fireRegimeRas.rds'))
}
#the dynamic prt

source('sourceClimateData.R')
# test <- sourceClimData(scenario = scenario, model = model)
times <- list(start = 2011, end = 2101) #this is so the cached genSpeciesLayers.R is returned
climObjs <- sourceClimDataYukon(scenario = scenario, model = model)

# times <- list(start = 2011, end = 2021)
spadesModulesDirectory <- c(file.path("modules"), 'modules/scfm') # where modules are
modules <- list('spades_ws3_dataInit', 'spades_ws3','spades_ws3_landrAge',
                "PSP_Clean", 'gmcsDataPrep', 'Biomass_core', 'Biomass_regeneration',
                'LandR_reforestation', 'assistedMigrationBC',
                "scfmIgnition", "scfmEscape", "scfmSpread")

parameters <- list(
  Biomass_speciesData = list(
    sppEquivCol = "RIA",
    type = c("KNN", "CASFRI")),
  Biomass_core = list(
    .plotInitialTime = NA
    , .plotInterval = 10
    , .saveInterval = 10
    , .saveInitialTime = times$start + 10
    , successionTimestep = 10
    , initialBiomassSource = "cohortData"
    , sppEquivCol = "RIA"
    , gmcsGrowthLimits = c(33, 150)
    , gmcsMortLimits = c(33, 300)
    , plotOverstory = TRUE
    , growthAndMortalityDrivers = "LandR.CS"
    , vegLeadingProportion = 0
    , keepClimateCols = TRUE #Try this
    , minCohortBiomass = 5
    , cohortDefinitionCols = c('pixelGroup', 'speciesCode', 'age', 'Provenance', 'planted')),
  Biomass_regeneration = list(
    fireInitialTime = times$start + 1,
    fireTimestep = 1,
    successionTimestep = 10,
    cohortDefinitionCols = c('pixelGroup', 'speciesCode', 'age', 'Provenance', 'planted')),
  assistedMigrationBC = list(
    doAssistedMigration = TRUE
    , sppEquivCol = 'RIA'
    , trackPlanting = TRUE),
  LandR_reforestation = list(
    cohortDefinitionCols = c('pixelGroup', 'speciesCode', 'age', 'Provenance', 'planted'),
    trackPlanting = TRUE),
  gmcsDataPrep = list(
    useHeight = TRUE
    # , GCM = 'CCSM4_RCP4.5'
  ),
  spades_ws3 = list(
    basenames = basenames,
    tifPath = 'tif',
    base.year = 2015,
    scheduler.mode = 'areacontrol',
    horizon = 1,
    target.masks = as.list(paste(basenames, "1 ? ?")), # TSA-wise THLB
    target.scalefactors = as.list(rep(1, length(basenames)))), #originally 0.8
  spades_ws3_dataInit = list(
    basenames = basenames,
    tifPath = 'tif',
    base.year = 2015,
    hdtPath = 'hdt',
    hdtPrefix = 'hdt_'),
  spades_ws3_landrAge = list(
    basenames = basenames,
    tifPath = 'tif',
    base.year = 2015),
  scfmSpread = list(
    .plotInitialTime = NA,
    .plotInterval = NA
  )
)

## Paths are not workign with multiple module paths yet

setPaths(cachePath =  file.path(getwd(), "cache"),
         modulePath = c(file.path(getwd(), "modules"), file.path("modules/scfm/modules")),
         inputPath = file.path(getwd(), "inputs"),
         outputPath = file.path(getwd(), outputDir))
paths <- SpaDES.core::getPaths()

if (readInputs) {
  objects <- list(
    "studyArea" = studyArea #always provide a SA
    , 'studyAreaPSP' = studyAreaPSP
    ,"rasterToMatch" = rasterToMatch
    ,"sppEquiv" = sppEquivalencies_CA
    ,"sppColorVect" = sppColors
    ,"studyAreaLarge" = studyAreaLarge
    ,"rasterToMatchLarge" = rasterToMatchLarge   #always provide a RTM
    , 'biomassMap' = readRDS(file.path('outputs/paramData/', runName, 'biomassMap.rds'))
    , 'cohortData' = readRDS(file.path('outputs/paramData/', runName, 'cohortData.rds'))
    , 'cceArgs' = list(quote(CMI),
                       quote(ATA),
                       quote(CMInormal),
                       quote(mcsModel),
                       quote(gcsModel),
                       quote(transferTable),
                       quote(ecoregionMap),
                       quote(currentBEC),
                       quote(BECkey))
    , 'ecodistrict' = readRDS(file.path('outputs/paramData/', runName, 'ecodistrict.rds'))
    , 'ecoregion' = readRDS(file.path('outputs/paramData/', runName, 'ecoregion.rds'))
    , 'ecoregionMap' = readRDS(file.path('outputs/paramData/', runName, 'ecoregionMap.rds'))
    , 'pixelGroupMap' = readRDS(file.path('outputs/paramData/', runName, 'pixelGroupMap.rds'))
    , 'minRelativeB' = readRDS(file.path('outputs/paramData', runName, '/minRelativeB.rds'))
    , 'species' = readRDS(file.path('outputs/paramData/', runName, 'species.rds'))
    , 'speciesLayers' = readRDS(file.path('outputs/paramData/', runName, 'speciesLayers.rds'))
    , 'speciesEcoregion' = readRDS(file.path('outputs/paramData/', runName, 'speciesEcoregion.rds'))
    , 'sufficientLight' = readRDS(file.path('outputs/paramData/', runName, 'sufficientLight.rds'))
    , 'rawBiomassMap' = readRDS(file.path('outputs/paramData/', runName, 'rawBiomassMap.rds'))
    , 'vegMap' = readRDS(file.path('outputs/paramData/', runName, 'vegMap.rds'))
    , 'landscapeAttr' = readRDS(file.path('outputs/paramData/', runName, 'landscapeAttr.rds'))
    , 'flammableMap' = readRDS(file.path('outputs/paramData/', runName, 'flammableMap.rds'))
    , 'cellsByZone'  = readRDS(file.path('outputs/paramData/', runName, 'cellsByZone.rds'))
    , 'fireRegimePolys' = readRDS(file.path('outputs/paramData/', runName, 'fireRegimePolys.rds'))
    , 'scfmRegimePars' = readRDS(file.path('outputs/paramData/', runName, 'scfmRegimePars.rds'))
    , 'firePoints' = readRDS(file.path('outputs/paramData/', runName, 'firePoints.rds'))
    , 'scfmDriverPars' = readRDS(file.path('outputs/paramData/', runName, 'scfmDriverPars.rds'))
    , 'fireRegimeRas' = readRDS(file.path('outputs/paramData/', runName, 'fireRegimeRas.rds'))
    , 'ATAstack' = climObjs$ATAstack
    , 'CMIstack' = climObjs$CMIstack
    , 'CMInormal' = climObjs$CMInormal
  )
  rm(harvestFiles)
  amc::.gc()
} else {
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
    , 'cceArgs' = list(quote(CMI),
                       quote(ATA),
                       quote(CMInormal),
                       quote(mcsModel),
                       quote(gcsModel),
                       quote(transferTable),
                       quote(ecoregionMap),
                       quote(currentBEC),
                       quote(BECkey))
    ,"ecoregion" = simOutSpp$ecoregion
    ,"ecoregionMap" = simOutSpp$ecoregionMap
    ,"pixelGroupMap" = simOutSpp$pixelGroupMap
    ,"minRelativeB" = simOutSpp$minRelativeB
    ,"species" = simOutSpp$species
    ,"speciesLayers" = simOutSpp$speciesLayers
    ,"speciesEcoregion" = simOutSpp$speciesEcoregion
    ,"sufficientLight" =simOutSpp$sufficientLight
    ,"rawBiomassMap" = simOutSpp$rawBiomassMap
    , 'vegMap' = simOutSpp$vegMap
    , 'landscapeAttr' = simOutSpp$landscapeAttr
    , 'flammableMap' = simOutSpp$flammableMap
    , 'cellsByZone' = simOutSpp$cellsByZone
    , 'fireRegimePolys' = fireRegimePolys
    , 'scfmRegimePars' = simOutSpp$scfmRegimePars
    , 'firePoints' = simOutSpp$firePoints
    , 'scfmDriverPars' = simOutSpp$scfmDriverPars
    , 'fireRegimeRas' = simOutSpp$fireRegimeRas
    , 'ATAstack' = climObjs$ATAstack
    , 'CMIstack' = climObjs$CMIstack
    , 'CMInormal' = climObjs$CMInormal
  )
}


opts <- options(
  "future.globals.maxSize" = 1000*1024^2,
  "LandR.assertions" = FALSE, #This will slow things down and stops due to sumB algos
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
  'reproducible.useGDAL' = FALSE,
  "spades.moduleCodeChecks" = FALSE, # Turn off all module's code checking
  'spades.recoveryMode' = 0 #don't use recovery mode in production
)

outputObjs = c('cohortData',
               'pixelGroupMap',
               'burnMap',
               'harvestPixelHistory')
saveTimes <- rep(seq(times$start, times$end, 30))

outputs = data.frame(objectName = rep(outputObjs, times = length(saveTimes)),
                     saveTime = rep(saveTimes, each = length(outputObjs)),
                     eventPriority = 10)
outputs <- rbind(outputs, data.frame(objectName = c('summarySubCohortData', 'summaryBySpecies'), saveTime = times$end, eventPriority = 10))
outputs <- rbind(outputs, data.frame(objectName = 'simulationOutput', saveTime = times$end, eventPriority = 10))


#run
thisRunTime <- Sys.time()
amc::.gc()
#figure out

if(!AM){
  parameters$assistedMigrationBC$doAssistedMigration <- FALSE
}

data.table::setDTthreads(2)
mySim <- simInit(times = times, params = parameters, modules = modules, objects = objects,
                 paths = paths, loadOrder = unlist(modules), outputs = outputs)
amc::.gc()
mySimOut <- spades(mySim, debug = TRUE)


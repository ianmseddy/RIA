source('sourceClimateData.R')

times <- list(start = 2011, end = 2101) #this is so the cached genSpeciesLayers.R is returned
climObjs <- sourceClimData(scenario = scenario, model = model)

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
         outputPath = file.path(getwd(),"outputs", outputDir))

paths <- SpaDES.core::getPaths()
if (readInputs){
  objects <- list(
    "studyArea" = studyArea #always provide a SA
    , 'studyAreaPSP' = studyAreaPSP
    ,"rasterToMatch" = rasterToMatch
    ,"sppEquiv" = sppEquivalencies_CA
    ,"sppColorVect" = sppColors
    ,"studyAreaLarge" = studyAreaLarge
    ,"rasterToMatchLarge" = rasterToMatchLarge   #always provide a RTM
    , 'biomassMap' = readRDS('outputs/paramData/biomassMap.rds')
    , 'cohortData' = readRDS('outputs/paramData/cohortData.rds')
    , 'cceArgs' = list(quote(CMI),
                       quote(ATA),
                       quote(CMInormal),
                       quote(mcsModel),
                       quote(gcsModel),
                       quote(transferTable),
                       quote(ecoregionMap),
                       quote(currentBEC),
                       quote(BECkey))
    , 'ecodistrict' = readRDS('outputs/paramData/ecodistrict.rds')
    , 'ecoregion' = readRDS('outputs/paramData/ecoregion.rds')
    , 'ecoregionMap' = readRDS('outputs/paramData/ecoregionMap.rds')
    , 'pixelGroupMap' = readRDS('outputs/paramData/pixelGroupMap.rds')
    , 'minRelativeB' = readRDS('outputs/paramData/minRelativeB.rds')
    , 'species' = readRDS('outputs/paramData/species.rds')
    , 'speciesLayers' = readRDS('outputs/paramData/speciesLayers.rds')
    , 'speciesEcoregion' = readRDS('outputs/paramData/speciesEcoregion.rds')
    , 'sufficientLight' = readRDS('outputs/paramData/sufficientLight.rds')
    , 'rawBiomassMap' = readRDS('outputs/paramData/rawBiomassMap.rds')
    , 'vegMap' = readRDS('outputs/paramData/vegMap.rds')
    , 'landscapeAttr' = readRDS('outputs/paramData/landscapeAttr.rds')
    , 'flammableMap' = readRDS('outputs/paramData/flammableMap.rds')
    , 'cellsByZone'  = readRDS('outputs/paramData/cellsByZone.rds')
    , 'fireRegimePolys' = readRDS('outputs/paramData/fireRegimePolys.rds')
    , 'scfmRegimePars' = readRDS('outputs/paramData/scfmRegimePars.rds')
    , 'firePoints' = readRDS('outputs/paramData/firePoints.rds')
    , 'scfmDriverPars' = readRDS('outputs/paramData/scfmDriverPars.rds')
    , 'fireRegimeRas' = readRDS('outputs/paramData/fireRegimeRas.rds')
    , 'ATAstack' = climObjs$ATAstack
    , 'CMIstack' = climObjs$CMIstack
    , 'CMInormal' = climObjs$CMInormal
  )
  rm(simOutSpp)
  .gc()
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

thisRunTime <- Sys.time()
amc::.gc()
#figure out
paramsToUse <- parameters
noAMparameters <- parameters
noAMparameters$assistedMigrationBC$doAssistedMigration <- FALSE
if(!AM){
  paramsToUse <- noAMparameters
}

mySim <- simInit(times = times, params = paramsToUse, modules = modules, objects = objects,
                 paths = paths, loadOrder = unlist(modules), outputs = outputs)
amc::.gc()
mySimOut <- spades(mySim, debug = TRUE)
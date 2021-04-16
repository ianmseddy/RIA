library(SpaDES.core)
library(reproducible)
library(raster)
library(sf)
library(data.table)
library(LandR)
library(rgeos)
#with AM project, include repName (AMstatus  + repName)

options("reproducible.useNewDigestAlgorithm" = 2)
options("reproducible.useGDAL" = FALSE) #this machine doesnt' have it, so don't look

times <- list(start = 2011, end = 2021)
# devtools::install_github("PredictiveEcology/LandR@development")
data.table::setDTthreads(2)
#need LandR.CS
googledrive::drive_deauth()

setPaths(inputPath = file.path('inputs', runName),
         modulePath = "modules",
         outputPath = file.path('outputs', runName),
         cachePath = file.path('cache', runName))
paths <- getPaths()


#there is a script showing how Yukon study area was made - involves GIS cleaning, v. slow

#eventually, revert to prepInputsLCC - but this is much faster for now
if (runName == "Yukon"){
 studyArea <- shapefile("inputs/Yukon/studyAreaYukon.shp")
 ecoregionRst <- Cache(prepInputs,
                       url = 'https://drive.google.com/file/d/1Dce0_rSBkxKjNM9q7-Zsg0JFidYu6cKP/view?usp=sharing',
                       studyArea = studyArea,
                       destinationPath = paths$inputPath)
 #this is the rasterized and reprojected Yukon BECZones from
 # https://map-data.service.yukon.ca/GeoYukon/Biophysical/Bioclimate_Zones_and_Subzones/Bioclimate_zones_and_subzones.zip
} else {
  studyArea <- shapefile("inputs/BC/studyAreaBC.shp")
  ecoregionRst <- Cache(prepInputs,
                        url = 'https://drive.google.com/file/d/1R38CXviHP72pbMq7hqV5CfT-jdJFZuWL/view?usp=sharing',
                        studyArea = studyArea,
                        destinationPath = paths$inputPath)
  #this is the rasterized and reprojected BECZones
}

rstLCC2010 <- Cache(prepInputs,
                    targetFile = 'CAN_LC_2010_CAL.tif',
                    destinationPath = 'inputs',
                    filename2 = paste0(runName, "_LCC2010.tif"),
                    quick = 'filename2',
                    archive = 'CanadaLandcover2010.zip',
                    rasterToMatch = ecoregionRst,
                    studyArea = studyArea)

studyAreaLarge <- studyArea
rasterToMatch <- rstLCC2010
rasterToMatchLarge <- rasterToMatch

#For climate scenarios - use BC PSP data
studyAreaPSP <- prepInputs(url = 'https://drive.google.com/open?id=10yhleaumhwa3hAv_8o7TE15lyesgkDV_',
                           destinationPath = 'inputs',
                           overwrite = TRUE,
                           useCache = TRUE) %>%
  spTransform(., CRSobj = crs(studyArea))

fireRegimePolys <- prepInputs(url = 'http://sis.agr.gc.ca/cansis/nsdb/ecostrat/region/ecoregion_shp.zip',
                              destinationPath = paths$inputPath,
                              studyArea = studyArea,
                              # rasterToMatch = rasterToMatch,
                              # filename2 = NULL,
                              userTags = c("fireRegimePolys"))
fireRegimePolys <- spTransform(fireRegimePolys, CRSobj = crs(rasterToMatch))

if (runName == "Yukon"){
  #Yukon will use a custom fireRegimePolys due to large areas with no fire
  #ecoregions 9 and 10 are combined, along with 5, 6, and 11. The latter have
  #almost no fires, the former have a combined 150 (with few large ones)
  #after accounting for slivers < 100 km2, we are left with 8 areas
  fireRegimePolys$newID <- fireRegimePolys$REGION_ID
  fireRegimePolys <- sf::st_as_sf(fireRegimePolys)
  fireRegimePolys[fireRegimePolys$REGION_ID %in% c(54, 60),]$newID <- 20
  fireRegimePolys[fireRegimePolys$REGION_ID %in% c(46, 47, 63),]$newID <- 19
  fireRegimePolys <- sf::as_Spatial(fireRegimePolys)
  fireRegimePolys <- rgeos::gUnaryUnion(spgeom = fireRegimePolys, id = fireRegimePolys$newID)
  fireRegimePolys$fireRegime <- row.names(fireRegimePolys)
} else {
  fireRegimePolys <- rgeos::gUnaryUnion(spgeom = fireRegimePolys, id = fireRegimePolys$REGION_ID)
  fireRegimePolys$fireRegime <- as.numeric(row.names(fireRegimePolys)) #dropping the factor, seems simple
}

#in case we ever need it
# rgdal::writeOGR(fireRegimePolys, dsn = paths$inputPath, layer = 'modifiedFireRegimePolys', driver = "ESRI Shapefile")
#for now due to postProcess bug
#fireRegimePolys <- shapefile(file.path(paths$inputPath, "modifiedFireRegimePolys.shp"))
source('generateSppEquiv.R')

if (runName == "Yukon"){
  sppEquivalencies_CA <- sppEquivalencies_CA[!RIA %in% c('Pice_eng', 'Betu_pap')] #drop engelmann in Yukon
}

if (writeOutputs) {
  source('yukonScripts/generateSpeciesLayersYukon.R')
  # saveSimList(simOutSpp, filename = file.path(paths$inputPath, "simOutSpp.rds"), fileBackend = 2)
  saveSimList(sim = simOutSpp, filename = file.path(outputDir, "../paramData","simOutSpp.rds"), fileBackend = 2)
} else if (!readInputs){
  source("yukonScripts/generateSpeciesLayersYukon.R")
}
#the dynamic prt

source('sourceClimateData.R')
# test <- sourceClimData(scenario = scenario, model = model)

times <- list(start = 2011, end = 2061)

if (gmcsDriver == "LandR.CS"){
  climObjs <- sourceClimDataYukon(scenario = scenario, model = model)
}


spadesModulesDirectory <- c(file.path("modules"), 'modules/scfm') # where modules are

modules <- list('Biomass_core', 'Biomass_regeneration'
                #, "scfmIgnition", "scfmEscape", "scfmSpread"
                )
if (gmcsDriver == "LandR.CS") {
  modules <- c(list("PSP_Clean", "gmcsDataPrep"), modules)
} else {
  climObjs <- NULL #so objects runs
}

parameters <- list(
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
    , plotOverstory = FALSE
    , growthAndMortalityDrivers = gmcsDriver
    , vegLeadingProportion = 0
    , keepClimateCols = TRUE #
    , minCohortBiomass = 5
    ),
  Biomass_regeneration = list(
    fireInitialTime = times$start + 1,
    fireTimestep = 1,
    successionTimestep = 10
    ),
  gmcsDataPrep = list(
    useHeight = TRUE #guarantee the same climate model as BC
  ),
  scfmSpread = list(
    .plotInitialTime = NA,
    .plotInterval = NA
  )
)

if (readInputs) {
  simOutSpp <- readRDS(file.path(paths$inputPath, "simOutSpp.rds"))
}

objects <- list(
  'studyArea' = studyArea #always provide a SA
  , 'studyAreaPSP' = studyAreaPSP
  , 'rasterToMatch' = rasterToMatch
  , 'sppEquiv' = sppEquivalencies_CA
  , 'sppColorVect' = sppColors
  , 'studyAreaLarge' = studyAreaLarge
  , 'rasterToMatchLarge' = rasterToMatchLarge   #always provide a RTM
  , 'biomassMap' = simOutSpp$biomassMap
  , 'cohortData' = simOutSpp$cohortData
  , 'ecoregion' = simOutSpp$ecoregion
  , 'ecoregionMap' = simOutSpp$ecoregionMap
  , 'pixelGroupMap' = simOutSpp$pixelGroupMap
  , 'minRelativeB' = simOutSpp$minRelativeB
  , 'species' = simOutSpp$species
  , 'speciesLayers' = simOutSpp$speciesLayers
  , 'speciesEcoregion' = simOutSpp$speciesEcoregion
  , 'sufficientLight' =simOutSpp$sufficientLight
  , 'rawBiomassMap' = simOutSpp$rawBiomassMap
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


#change the paths for simulation. outputPath specifies climateModel + rep
setPaths(cachePath =  file.path(getwd(), "cache"),
         modulePath = c(file.path(getwd(), "modules"), file.path("modules/scfm/modules")),
         inputPath = file.path(getwd(), "inputs"),
         outputPath = file.path(getwd(), outputDir))
paths <- SpaDES.core::getPaths()


opts <- options(
  "future.globals.maxSize" = 1000*1024^2,
  "LandR.assertions" = FALSE, #This will slow things down and stops due to sumB algos
  # "LandR.verbose" = 1,
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
               'burnMap')
saveTimes <- rep(seq(times$start, times$end, 10))

outputs = data.frame(objectName = rep(outputObjs, times = length(saveTimes)),
                     saveTime = rep(saveTimes, each = length(outputObjs)),
                     eventPriority = 10)
#contains info on leading spp, only need once
outputs <- rbind(outputs, data.frame(objectName = c('summaryBySpecies'), saveTime = times$end, eventPriority = 10))
#contains results by ecoregion (not that important with no BECs..)
outputs <- rbind(outputs, data.frame(objectName = 'simulationOutput', saveTime = times$end, eventPriority = 10))


#run
thisRunTime <- Sys.time()
amc::.gc()
#figure out

data.table::setDTthreads(2)
# rm(simOutSpp)
mySim <- simInit(times = times, params = parameters, modules = modules, objects = objects,
                 paths = paths, loadOrder = unlist(modules), outputs = outputs)
amc::.gc()
mySimOut <- spades(mySim, debug = TRUE)


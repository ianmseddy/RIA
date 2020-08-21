library(reticulate)
library(SpaDES)
library(raster)
library(sf)
library(LandR)
library(data.table)

#need LandR.CS
# py_install('ws3', pip=TRUE, pip_options=c('--upgrade', '-e git+https://github.com/gparadis/ws3.git@dev#egg=ws3')) #To upgrade WS3
googledrive::drive_deauth()

basenames <- list("tsa40", 'tsa41', 'tsa16', 'tsa24', 'tsa08') #This must absolutely match whatever studyArea you are going to use for harvest
source("generateHarvestInit.R")

rasterToMatch <- harvestFiles$landscape$age
#Change the TSA to either Ft St John or Ft Nelson
studyAreaLarge <- prepInputs(url = 'https://drive.google.com/file/d/1YwkdFDuy00Zl__40XaDOMRn-cDePD-nI/view?usp=sharing',
                             targetFile = 'BC_TSA_corrected.shp',
                             alsoExtract = c("BC_TSA_corrected.dbf",
                                             "BC_TSA_corrected.sbx",
                                             "BC_TSA_corrected.shx",
                                             "BC_TSA_corrected.prj",
                                             "BC_TSA_corrected.cpg"),
                             destinationPath = paths$inputPath,
                             overwrite = TRUE,
                             useCache = TRUE,
                             FUN = 'sf::st_read') %>%
  sf::st_as_sf(.)
studyAreaLarge <- studyAreaLarge[studyAreaLarge$TSA_NUMBER %in% c('08', '16', '24', '40', '41'),]
if (length(unique(sf::st_geometry_type(studyAreaLarge))) > 1)  ## convert sfc to sf if needed
  sf::st_geometry(studyAreaLarge) <- sf::st_collection_extract(x = sf::st_geometry(studyAreaLarge), type = "POLYGON")

studyAreaLarge <- sf::st_buffer(studyAreaLarge, 0) %>%
  sf::as_Spatial(.) %>%
  raster::aggregate(.) %>%
  sf::st_as_sf(.)
studyAreaLarge$studyArea <- "5TSA"
studyAreaLarge <- sf::as_Spatial(studyAreaLarge)
#
# studyAreaLarge <- prepInputs(url = 'https://drive.google.com/open?id=18XPcOKeQdty102dYHizKH3ZPE187BiYi',
#                              destinationPath = 'inputs',
#                              overwrite = TRUE) %>%
#   spTransform(., CRSobj = crs(studyArea))
studyArea <- studyAreaLarge
studyArea <- buffer(studyArea, 0)
# rasterToMatchLarge <- prepInputsLCC(studyArea = studyAreaLarge,
#                       destinationPath = 'inputs',
#                       useCache = TRUE,
#                       overwrite = TRUE,
#                       useSAcrs = TRUE,
#                       res = c(250, 250))
rasterToMatchLarge <- rasterToMatch
studyArea <- spTransform(studyArea, CRS = crs(rasterToMatch))
studyAreaLarge <- spTransform(studyAreaLarge, CRS = crs(rasterToMatchLarge))
studyAreaName <- 'FiveTSA'


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
                          useCache = TRUE) #to preserve original filenames, workaround for now
ecoregionRst <- ecoregionRst[[1]] #fix reproducible

standAgeMap <- harvestFiles$landscape$age
fireRegimePolys <- prepInputs(url = 'https://drive.google.com/file/d/1Fj6pNKC48qDndPE3d6IxR1dvLF2vLeWc/view?usp=sharing',
                              destinationPath = 'inputs',
                              # rasterToMatch = rasterToMatch,
                              # studyArea = studyArea,
                              useCache = TRUE,
                              userTags = c("fireRegimePolys")
                              )
fireRegimePolys <- buffer(fireRegimePolys, 0)
fireRegimePoylys <- postProcess(fireRegimePolys, studyArea = studyArea, rasterToMatch = rasterToMatch) #self-intersection in googledrive file

times <- list(start = 2011, end = 2101)
source('generateSppEquiv.R')
source('generateSpeciesLayers.R')
source('sourceClimateData.R')
climObjs <- sourceClimData(scenario = 'RCP4.5')

times <- list(start = 2011, end = 2021)
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
    , .plotInterval = NA
    , .saveInterval = 10
    , .saveInitialTime = times$start + 10
    , successionTimestep = 10
    , initialBiomassSource = "cohortData"
    , sppEquivCol = "RIA"
    , plotOverstory = TRUE
    , growthAndMortalityDrivers = "LandR.CS"
    , vegLeadingProportion = 0
    , keepClimateCols = FALSE
    , minCohortBiomass = 5
    , cdColsForAgeBins = c('pixelGroup', 'speciesCode')),
  Biomass_regeneration = list(
    fireInitialTime = times$start + 1,
    fireTimestep = 1,
    successionTimestep = 10),
  assistedMigrationBC = list(
    doAssistedMigration = TRUE
    , sppEquivCol = 'RIA'),
  gmcsDataPrep = list(
    useHeight = TRUE
    , GCM = 'CCSM4_RCP4.5'),
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
         outputPath = file.path(getwd(),"outputs/AM90yr"))

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



opts <- options(
  "future.globals.maxSize" = 1000*1024^2,
  "LandR.assertions" = FALSE, #This will slow things down
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
  'spades.recoveryMode' = 1
)

outputObjs = list('cohortData',
                  'pixelGroupMap',
                  'burnMap')
outputs = data.frame(objectName = outputObjs,
                     saveTime = rep(seq(times$start, times$end, 20), each = length(outputObjs)),
                     eventPriority = 10)

thisRunTime <- Sys.time()
amc::.gc()
set.seed(1110)
#figure out
mySim <- simInit(times = times, params = parameters, modules = modules, objects = objects,
                 paths = paths, loadOrder = unlist(modules))

amc::.gc()
mySimOut <- spades(mySim, debug = TRUE)

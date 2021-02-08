library(magrittr)
## -----------------------------------
## LOAD/MAKE SPECIES LAYERS
## -----------------------------------

## this script makes a pre-simulation object that makes species layers
## by running Biomass_speciesData. This is the longest module to run and,
## unless the study area or the species needed change, it whould only
## be run once (even if other things change, like the simulation rep,
## or other modules). That's why caching is kept separate from the rest
## of the simulation

speciesPaths <-list(cachePath = file.path("cache", runName, 'speciesCache'),
                    modulePath = c(file.path("modules"), file.path('modules/scfm/modules')),
                    inputPath = file.path("inputs", runName),
                    outputPath = file.path("outputs", runName))

rstLCC2010 <- prepInputs(url = 'https://drive.google.com/file/d/1WcCEkwjnDq74fx3ZBizlIKzLkjW6Nfdf/view?usp=sharing',
                     rasterToMatch = rasterToMatchLarge,
                     studyArea = studyAreaLarge,
                     destinationPath = speciesPaths$inputPath,
                     filename2 = paste0("rstLCC_", runName, '.tif'),
                     useCache = TRUE,
                     userTags = c("rstLCC2010"))
flammableMap <- LandR::defineFlammable(LandCoverClassifiedMap = rstLCC2010,
                                       nonFlammClasses = c(13, 16, 17, 18, 19),
                                       mask = rasterToMatchLarge)
#get objects
#This should use whatever is loaded in R instead of replacing it
# studyArea <- shapefile("inputs/ftStJohn_studyArea.shp")
#
# rasterToMatch <- raster("inputs/ftStJohn_RTM.tif")
# studyAreaLarge <- shapefile("inputs/RIA_fiveTSA.shp") %>%
#   spTransform(., crs(rasterToMatch))

#get sppEquivalencies
#Create function for updating sub-alpine fir longevity and reverting Betu_pap to 150 - this lowers it's maxB inflation
firAgeUpdate <- function(sT) {
  sT[species == "Abie_las", longevity := 300]
  # sT[species == "Betu_pap", longevity := 150]
  sT[, shadetolerance := as.numeric(shadetolerance)]
  sT[species == 'Pice_eng', shadetolerance := 2.5]
  sT[species == 'Pice_mar', shadetolerance := 2.5]
  return(sT)
}

minRelativeB_RIA <- function(pixelCohortData){
  pixelData <- unique(pixelCohortData, by = "pixelIndex")
  pixelData[, `:=`(ecoregionGroup, factor(as.character(ecoregionGroup)))]
  minRelativeB <- data.frame(ecoregionGroup = as.factor(levels(pixelData$ecoregionGroup)),
                             X1 = 0.13, X2 = 0.21, X3 = 0.29, X4 = 0.42, X5 = 0.65)
  return(minRelativeB)
}

speciesParameters <- list(
  Biomass_speciesData = list(
    sppEquivCol = "RIA"
    , .studyAreaName = runName
    , type = c("KNN", "CASFRI")
  )
  , Biomass_borealDataPrep = list(
    successionTimestep = 10
    , .studyAreaName = runName
    , minRelativeBFunction = quote(minRelativeB_RIA(pixelCohortData))
    , subsetDataBiomassModel = 100
    , forestedLCCClasses = c(1:6, 14, 99)
    , LCCClassesToReplaceNN =  c(99)
    , pixelGroupAgeClass = 10
    , pixelGroupBiomassClass = 500
    , sppEquivCol = 'RIA'
    , speciesUpdateFunction = list(
      quote(LandR::speciesTableUpdate(sim$species, sim$speciesTable, sim$sppEquiv, P(sim)$sppEquivCol)),
      quote(firAgeUpdate(sT = sim$species)))
    ),
    gmcsDataPrep = list(
    GCM = 'CCSM4_RCP4.5'
    , useHeight = TRUE),
   Biomass_speciesParameters = list(
    sppEquivCol = 'RIA'
    , useHeight = FALSE
    , GAMMknots = list(
      "Abie_las" = 3,
      # "Betu_pap" = 3,
      # "Pice_eng" = 4,
      "Pice_gla" = 3,
      "Pice_mar" = 4,
      "Pinu_con" = 4,
      "Popu_tre" = 4
    )
    , constrainGrowthCurve = list(
      "Abie_las" = c(0.3, .7),
      # "Betu_pap" = c(0, 0.3),
      # "Pice_eng" = c(0.3, .7),
      "Pice_gla" = c(0.3, .7),
      "Pice_mar" = c(0.4, 1),
      "Pinu_con" = c(0.3, .7),
      "Popu_tre" = c(0.4, 1)
    )
    , constrainMortalityShape = list(
      "Abie_las" = c(15, 25),
      # "Betu_pap" = c(15, 20),
      # "Pice_eng" = c(15, 25),
      "Pice_gla" = c(15, 25),
      "Pice_mar" = c(15, 25),
      "Pinu_con" = c(15, 25),
      "Popu_tre" = c(20, 25)
    )
    , quantileAgeSubset = list(
      "Abie_las" = 95, #N = 250 ''
      # "Betu_pap" = 95, #N = 96
      # "Pice_eng" = 95, #N = 130
      "Pice_gla" = 95, #N = 1849
      "Pice_mar" = 95, #N = 785
      "Pinu_con" = 97, # N = 3172, 99 not an improvement. Maybe 97
      "Popu_tre" = 99 # N = 1997, trying 99
      )),
  scfmLandcoverInit = list(
    sliverThreshold = 1e9 #1000 km2
  )
)

speciesObjects <- list(
  "sppEquiv" = sppEquivalencies_CA
  , "sppColorVect" = sppColors
  , "studyAreaLarge" = studyAreaLarge
  , 'studyArea' = studyArea
  , 'rasterToMatch' = rasterToMatch
  , 'rasterToMatchLarge' = rasterToMatchLarge
  , 'rstLCC' = rstLCC2010
  , 'vegMap' = rstLCC2010
  , 'flammableMap' = flammableMap
  , 'fireRegimePolys' = fireRegimePolys
)


speciesModules <- c('PSP_Clean', "Biomass_speciesData", 'Biomass_borealDataPrep', 'Biomass_speciesParameters',
                    'scfmLandcoverInit', 'scfmRegime')

simOutSpp <- Cache(simInitAndSpades, times = list(start = times$start, end = times$start + 1)
                   , params = speciesParameters
                   , modules = speciesModules
                   , objects = speciesObjects
                   , paths = speciesPaths
                   , debug = TRUE
                   , .plotInitialTime = NA
                   , loadOrder = unlist(speciesModules)
                   , userTags = "simOutSpp",
                   cacheRepo = speciesPaths$cachePath)

#SCFM Driver - moved this out because the driver is such a pain #

scfmDriverObjs <- list(
  'vegMap' = rstLCC2010,
  'studyArea' = studyArea,
  'fireRegimeRas' = simOutSpp$fireRegimeRas,
  'fireRegimePolys' = simOutSpp$fireRegimePolys,
  'scfmRegimePars' = simOutSpp$scfmRegimePars,
  'landscapeAttr' = simOutSpp$landscapeAttr,
  'flammableMap' = simOutSpp$flammableMap
)

scfmParams <- list(
  scfmDriver = list(
    targetN = 5000
  )
)
scfmPaths <- speciesPaths
scfmPaths$cachePath <- "scfmCache"
simScfmDriver <- Cache(simInitAndSpades
                       , times = list(start = times$start, end = times$start + 1)
                       , params = scfmParams
                       , modules = 'scfmDriver'
                       , objects = scfmDriverObjs
                       , paths = scfmPaths
                       , debug = TRUE
                       , .plotInitialTime = NA
                       , loadOrder = unlist(speciesModules)
                       , userTags = c("scfmDriver", "runName"),
                       cacheRepo = scfmPaths$cachePath)

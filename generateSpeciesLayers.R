library(SpaDES)
library(raster)
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

speciesPaths <-list(cachePath = tempdir(),#"speciesCache",
                    modulePath = file.path("modules"),
                    inputPath = file.path("inputs"),
                    outputPath = file.path("outputs"))

#get objects
#This should use whatever is loaded in R instead of replacing it
# studyArea <- shapefile("inputs/ftStJohn_studyArea.shp")
#
# rasterToMatch <- raster("inputs/ftStJohn_RTM.tif")
# studyAreaLarge <- shapefile("inputs/RIA_fiveTSA.shp") %>%
#   spTransform(., crs(rasterToMatch))

#get sppEquivalencies
source('generateSppEquiv.R')

#Create function for updating sub-alpine fir longevity
firAgeUpdate <- function(sT) {
  sT[species == "Abie_las", longevity := 300]
  return(sT)
}

speciesParameters <- list(
  Biomass_speciesData = list(
    sppEquivCol = "RIA",
    type = c("KNN", "CASFRI")
  )
  , Biomass_borealDataPrep = list(
    successionTimestep = 10
    , subsetDataBiomassModel = 50
    , pixelGroupAgeClass = 10
    , sppEquivCol = 'RIA'
    , speciesUpdateFunction = list(
      quote(LandR::speciesTableUpdate(sim$species, sim$speciesTable, sim$sppEquiv, P(sim)$sppEquivCol)),
      quote(firAgeUpdate(sT = sim$species))
    ),
    gmcsDataPrep = list(
    GCM = 'CCSM4_RCP4.5'
    , useHeight = TRUE),
   LandR_speciesParameters = list(
    sppEquivCol = 'RIA'
    , useHeight = FALSE
    , GAMMknots = list(
      "Abie_las" = 3,
      "Betu_pap" = 3,
      "Pice_eng" = 4,
      "Pice_gla" = 3,
      "Pice_mar" = 4,
      "Pinu_con" = 4,
      "Popu_tre" = 4
    )
    , constrainGrowthCurve = list(
      "Abie_las" = c(0.3, .7),
      "Betu_pap" = c(0.3, .7),
      "Pice_eng" = c(0.3, .7),
      "Pice_gla" = c(0.3, .7),
      "Pice_mar" = c(0.3, .7),
      "Pinu_con" = c(0.3, .7),
      "Popu_tre" = c(0.3, .7)
    )
    , quantileAgeSubset = list(
      "Abie_las" = 95, #N = 250 ''
      "Betu_pap" = 95, #N = 96
      "Pice_eng" = 95, #N = 130
      "Pice_gla" = 95, #N = 1849
      "Pice_mar" = 95, #N = 785
      "Pinu_con" = 97, # N = 3172, 99 not an improvement. Maybe 97
      "Popu_tre" = 98 # N = 1997, trying 99
    ))
  )
)

speciesObjects <- list(
  "sppEquiv" = sppEquivalencies_CA
  , "sppColorVect" = sppColors
  , "studyAreaLarge" = studyAreaLarge
  , 'studyArea' = studyArea
  , 'rasterToMatch' = rasterToMatch
  , 'rasterToMatchLarge' = rasterToMatchLarge
  , 'ecoregionRst' = ecoregionRst
)

speciesModules <- c('PSP_Clean', "Biomass_speciesData", 'Biomass_borealDataPrep', 'LandR_speciesParameters')

simOutSpp <- Cache(simInitAndSpades
                   , times = list(start = times$start, end = times$start + 1)
                   , params = speciesParameters
                   , modules = speciesModules
                   , objects = speciesObjects
                   , paths = speciesPaths
                   , debug = TRUE
                   , .plotInitialTime = NA
                   , loadOrder = unlist(speciesModules)
                   , userTags = "simOutSpp",
                   cacheRepo = speciesPaths$cachePath)

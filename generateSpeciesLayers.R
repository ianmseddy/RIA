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

speciesPaths <-list(cachePath = "speciesCache",
                    modulePath = file.path("modules"),
                    inputPath = file.path("inputs"),
                    outputPath = file.path("outputs"))

#get objects
studyArea <- shapefile("inputs/ftStJohn_studyArea.shp")

rasterToMatch <- raster("inputs/ftStJohn_RTM.tif")
studyAreaLarge <- shapefile("inputs/RIA_fiveTSA.shp") %>%
  spTransform(., crs(rasterToMatch))

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
    )
  )
)

speciesObjects <- list(
  "sppEquiv" = sppEquivalencies_CA
  , "sppColorVect" = sppColors
  , "studyAreaLarge" = studyAreaLarge
  , 'studyArea' = studyArea
  , 'rasterToMatch' = rasterToMatch
)

simOutSpp <- Cache(simInitAndSpades
                   , times = list(start = times$start, end = times$start + 1)
                   , params = speciesParameters
                   , modules = c("Biomass_speciesData", 'Biomass_borealDataPrep')
                   , objects = speciesObjects
                   , paths = speciesPaths
                   , debug = TRUE
                   , .plotInitialTime = NA,
                   userTags = "simOutSpp",
                   cachePath = speciesPaths$cachePath)

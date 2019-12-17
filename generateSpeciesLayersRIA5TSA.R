## -----------------------------------
## LOAD/MAKE SPECIES LAYERS
## -----------------------------------

## this script makes a pre-simulation object that makes species layers
## by running Biomass_speciesData. This is the longest module to run and,
## unless the study area or the species needed change, it whould only
## be run once (even if other things change, like the simulation rep,
## or other modules). That's why caching is kept separate from the rest
## of the simulation
googledrive::drive_auth(email = "ianmseddy@gmail.com")
speciesPaths <-list(cachePath = file.path("/mnt/data/RIA/speciesCache"),
                    modulePath = file.path("modules"),
                    inputPath = file.path("inputs"),
                    outputPath = file.path("outputs"))

#get objects
studyArea <- shapefile("inputs/RIA_fiveTSA.shp")
rasterToMatch <- raster("inputs/RIA5tsaRTM.tif")
#studyAreaLarge IS studyArea

#get sppEquivalencies
source('generateSppEquiv.R')

#Create function for updating sub-alpine fir longevity

speciesParameters <- list(
  Biomass_speciesData = list(
    sppEquivCol = "RIA",
    type = c("KNN", "CASFRI")
  )
  , Biomass_borealDataPrep = list(
    successionTimestep = 10
    , pixelGroupAgeClass = 10
    , sppEquivCol = 'RIA'
    , speciesUpdateFunction = list(
      quote(LandR::speciesTableUpdate(sim$species, sim$speciesTable, sim$sppEquiv, P(sim)$sppEquivCol)),
      quote(firAgeUpdate(sT = sim$species))
    )
  )
)

#MAKE SURE MEMOISE IS FALSE
opts <- options(
  "LandR.assertions" = FALSE,
  "reproducible.futurePlan" = FALSE,
  "reproducible.inputPaths" = NULL,
  "reproducible.quick" = FALSE,
  "reproducible.overwrite" = TRUE,
  "reproducible.useMemoise" = FALSE, # Brings cached stuff to memory during the second run
  "reproducible.useNewDigestAlgorithm" = TRUE,  # use the new less strict hashing algo
  "reproducible.useCache" = TRUE,
  "reproducible.cachePath" = paths$cachePath,
  "spades.moduleCodeChecks" = FALSE, # Turn off all module's code checking
  "spades.useRequire" = FALSE # assuming all pkgs installed correctly
)

speciesObjects <- list(
  "sppEquiv" = sppEquivalencies_CA
  , "sppColorVect" = sppColors
  , 'studyArea' = studyArea
  , 'rasterToMatch' = rasterToMatch
  , 'studyAreaLarge' = studyArea
)
speciesModules = c("Biomass_speciesData", 'Biomass_borealDataPrep')

simOutSpp <- Cache(simInitAndSpades
                   , times = list(start = 0, end = 1)
                   , params = speciesParameters
                   , modules = speciesModules
                   , objects = speciesObjects
                   , paths = speciesPaths
                   , debug = TRUE
                   , .plotInitialTime = NA
                   , loadOrder = unlist(speciesModules))

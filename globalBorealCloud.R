library(SpaDES)
library(raster)
library(LandR)

spadesModulesDirectory <- file.path("modules") # where modules are 
modules <- list("Boreal_LBMRDataPrep", "LBMR", "Biomass_Regeneration", "PSP_Clean", "gmcsDataPrep",
                "scfmLandcoverInit", "scfmRegime", "scfmDriver", "scfmIgnition", "scfmEscape", "scfmSpread")
times <- list(start = 2011, end = 2100)


studyArea <- prepInputs(url = 'https://drive.google.com/open?id=1TlBfGfes_6UQW4M3jib8zgY5sGd_yjmY',
                        destinationPath = file.path(getwd(), "inputs"))
# rasterToMatch <- Cache(prepInputsLCC, 
#                        destinationPath = file.path(getwd(), "inputs"), 
#                        studyArea = studyArea, 
#                        filename2 = "RIArtm.tif")
studyAreaLarge <- prepInputs(url = 'https://drive.google.com/open?id=1vsgb1Bg8B_vUe-rk7LplkUifCkyPWtf3', 
                             destinationPath = file.path(getwd(), "inputs"))
studyAreaPSP <- studyAreaLarge

parameters <- list(
  LBMR = list(.plotInitialTime = NA,
              seedingAlgorithm = "wardDispersal",
              useCache = TRUE,
              successionTimestep = 10,
              initialBiomassSource = "cohortData",
              sppEquivCol = "RIA",
              growthAndMortalityDrivers = "LandR.CS",
              vegLeadingProportion = 0), 
  Boreal_LBMRDataPrep = list(
    successionTimestep = 10,
    pixelGroupAgeClass = 10,
    sppEquivCol = 'RIA'),
  scfmSpread = list(
    .plotInitialTime = NA,
    .plotInterval = 1),
  scfmLandcoverInit = list(
    .plotInitialTime = NA),
  scfmDriver = list(
    .useParallel = TRUE),
  Biomass_regeneration = list(
    fireInitialTime = times$start + 1,
    fireTimeStep = 1,
    successionTimeStep = 10),#,
  gmcsDataPrep = list(
    useHeight = TRUE)
)
## Paths are not workign with multiple module paths yet
setPaths(cachePath =  file.path(getwd(), "cache"),
         modulePath = c(file.path(getwd(),"modules"), file.path(getwd(), "modules/scfm/modules")),
         inputPath = file.path(getwd(), "inputs"),
         outputPath = file.path(getwd(),"outputs"))
paths <- SpaDES.core::getPaths()
#
options("spades.moduleCodeChecks" = FALSE)

data("sppEquivalencies_CA", package = "LandR")
sppEquivalencies_CA[grep("Pin", LandR), `:=`(EN_generic_short = "Pine",
                                             EN_generic_full = "Pine",
                                             Leading = "Pine leading")]

# Make LandWeb spp equivalencies
sppEquivalencies_CA[, RIA := c(Pice_mar = "Pice_mar", Pice_gla = "Pice_gla",
                               Pinu_con = "Pinu_con", Popu_tre = "Popu_tre", 
                               #Betu_pap = "Betu_pap", 
                               Pice_eng = "Pice_eng")[LandR]]
sppEquivalencies_CA[LANDIS_traits == "ABIE.LAS"]$RIA <- "Abie_las"

sppEquivalencies_CA <- sppEquivalencies_CA[!LANDIS_traits == "PINU.CON.CON"]

sppEquivalencies_CA[RIA == "Abie_las", EN_generic_full := "Subalpine Fir"]
sppEquivalencies_CA[RIA == "Abie_las", EN_generic_short := "Fir"]
sppEquivalencies_CA[RIA == "Abie_las", Leading := "Fir leading"]
sppEquivalencies_CA[RIA == "Popu_tre", Leading := "Pop leading"]
# sppEquivalencies_CA[RIA == "Betu_pap", EN_generic_short := "Betula"]
# sppEquivalencies_CA[RIA == "Betu_pap",  Leading := "Betula leading"]
sppEquivalencies_CA[RIA == "Betu_pap",  EN_generic_full := "Paper birch"]
sppEquivalencies_CA[RIA == "Pice_eng", EN_generic_full := 'Engelmann Spruce']
sppEquivalencies_CA[RIA == 'Pice_eng', EN_generic_short  := "En Spruce"]

sppEquivalencies_CA <- sppEquivalencies_CA[!is.na(RIA)]

#Assign colour
setkey(sppEquivalencies_CA, RIA)
sppNames <- unique(sppEquivalencies_CA$RIA)
names(sppColors) <- c(sppNames, "mixed")

objectSynonyms <- list(c('vegMap', "LCC2005"))
objects <- list(
  studyArea = studyArea,
  rasterToMatch = rasterToMatch,
  sppEquiv = sppEquivalencies_CA,
  sppColorVect = sppColors,
  studyAreaLarge = studyAreaLarge,
  studyAreaReporting = studyArea,
  studyAreaPSP = studyAreaPSP, 
  objecSynonyms = objectSynonyms
)
#                 

opts <- options(
  "future.globals.maxSize" = 1000*1024^2,
  "LandR.assertions" = FALSE,
  "LandR.verbose" = 1,
  "reproducible.futurePlan" = FALSE,
  "reproducible.inputPaths" = NULL,
  "reproducible.quick" = FALSE,
  "reproducible.overwrite" = TRUE,
  "reproducible.useMemoise" = TRUE, # Brings cached stuff to memory during the second run
  "reproducible.useNewDigestAlgorithm" = TRUE,  # use the new less strict hashing algo
  "reproducible.useCache" = TRUE,
  "reproducible.cachePath" = paths$cachePath,
  "reproducible.useCloud" = FALSE,
  "spades.moduleCodeChecks" = FALSE, # Turn off all module's code checking
  "spades.useRequire" = FALSE # assuming all pkgs installed correctly
)

mySim <- simInit(times = times, params = parameters, modules = modules, objects = objects,
                 paths = paths, loadOrder = unlist(modules))

#Edit longevity of some species according to #Burton and Cumming 1995
mySim$speciesTable[LandisCode == "PICE.GLA"]$Longevity <- 400
mySim$speciesTable[LandisCode == "PINU.CON.LAT"]$Longevity <- 335
mySim$speciesTable[LandisCode == "PICE.MAR"]$Longevity <- 250
mySim$speciesTable[LandisCode == "POPU.TRE"]$Longevity <- 200
mySim$speciesTable[LandisCode == "ABIE.LAS"]$Longevity <- 250
 
mySimOut <- spades(mySim, debug = TRUE)


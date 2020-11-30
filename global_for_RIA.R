library(reticulate)
library(SpaDES.core)
library(raster)
library(sf)
library(data.table)

# devtools::install_github("PredictiveEcology/LandR@development")
data.table::setDTthreads(2)
#need LandR.CS
# py_install('ws3', pip=TRUE, pip_options=c('--upgrade', '-e git+https://github.com/gparadis/ws3.git@dev#egg=ws3')) #To upgrade WS3
googledrive::drive_deauth()

if (runName == '4TSAs'){
  TSAs <- c('16', '24', '40', '41')
} else {
  TSAs <- c('08', '16', '24', '40', '41')
}

basenames <-paste0('tsa', TSAs)
basenames <- as.list(basenames) #This must absolutely match whatever studyArea you are going to use for harvest
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

studyAreaLarge <- studyAreaLarge[studyAreaLarge$TSA_NUMBER %in%TSAs,]
if (length(unique(sf::st_geometry_type(studyAreaLarge))) > 1)  ## convert sfc to sf if needed
  sf::st_geometry(studyAreaLarge) <- sf::st_collection_extract(x = sf::st_geometry(studyAreaLarge), type = "POLYGON")

studyAreaLarge <- sf::st_buffer(studyAreaLarge, 0) %>%
  sf::as_Spatial(.) %>%
  raster::aggregate(.) %>%
  sf::st_as_sf(.)
studyAreaLarge$studyArea <- runName
studyAreaLarge <- sf::as_Spatial(studyAreaLarge)
studyArea <- studyAreaLarge
studyArea <- buffer(studyArea, 0)

rasterToMatchLarge <- rasterToMatch
studyArea <- spTransform(studyArea, CRS = crs(rasterToMatch))
studyAreaLarge <- spTransform(studyAreaLarge, CRS = crs(rasterToMatchLarge))
studyAreaName <- runName


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
                              rasterToMatch = rasterToMatch,
                              filename2 = NULL,
                              studyArea = studyArea,
                              useCache = TRUE,
                              userTags = c("fireRegimePolys")
                              )

times <- list(start = 2011, end = 2101)
source('generateSppEquiv.R')


if (writeOutputs) {
  source('generateSpeciesLayers.R')
  saveRDS(simOutSpp$biomassMap, file.path('outputs/paramData/', runName, 'biomassMap.rds'))
  saveRDS(simOutSpp$cohortData, file.path('outputs/paramData/', runName, 'cohortData.rds'))
  saveRDS(simOutSpp$ecodistrict, file.path('outputs/paramData/', runName, 'ecodistrict.rds'))
  saveRDS(simOutSpp$ecoregion, file.path('outputs/paramData/', runName, 'ecoregion.rds'))
  saveRDS(simOutSpp$ecoregionMap, file.path('outputs/paramData/', runName, 'ecoregionMap.rds'))
  saveRDS(simOutSpp$pixelGroupMap, file.path('outputs/paramData/', runName, 'pixelGroupMap.rds'))
  saveRDS(simOutSpp$minRelativeB, file.path('outputs/paramData/', runName, 'minRelativeB.rds'))
  saveRDS(simOutSpp$species, file.path('outputs/paramData/', runName, 'species.rds'))
  saveRDS(simOutSpp$speciesLayers, file.path('outputs/paramData/', runName, 'speciesLayers.rds'))
  saveRDS(simOutSpp$speciesEcoregion, file.path('outputs/paramData/', runName, 'speciesEcoregion.rds'))
  saveRDS(simOutSpp$sufficientLight, file.path('outputs/paramData/', runName, 'sufficientLight.rds'))
  saveRDS(simOutSpp$rawBiomassMap, file.path('outputs/paramData/', runName, 'rawBiomassMap.rds'))
  saveRDS(simOutSpp$vegMap, file.path('outputs/paramData/', runName, 'vegMap.rds'))
  saveRDS(simOutSpp$landscapeAttr, file.path('outputs/paramData/', runName, 'landscapeAttr.rds'))
  saveRDS(simOutSpp$flammableMap, file.path('outputs/paramData/', runName, 'flammableMap.rds'))
  saveRDS(simOutSpp$cellsByZone, file.path('outputs/paramData/', runName, 'cellsByZone.rds'))
  saveRDS(simOutSpp$fireRegimePolys, file.path('outputs/paramData/', runName, 'fireRegimePolys.rds'))
  saveRDS(simOutSpp$scfmRegimePars, file.path('outputs/paramData/', runName, 'scfmRegimePars.rds'))
  saveRDS(simOutSpp$firePoints, file.path('outputs/paramData/', runName, 'firePoints.rds'))
  saveRDS(simScfmDriver$scfmDriverPars, file.path('outputs/paramData/', runName, 'scfmDriverPars.rds'))
  saveRDS(simOutSpp$fireRegimeRas, file.path('outputs/paramData/', runName, 'fireRegimeRas.rds'))
}

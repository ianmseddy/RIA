library(magrittr)
library(raster)
library(ggplot2)
fires <- list.files("C:/users/ieddy/Downloads/CCSM4_RCP85_3Arc_asym10to3/CCSM4_RCP85_3Arc_asym10to3/scfm/", full.names = TRUE)
fireStack <- lapply(fires, FUN = 'raster') %>%
  stack(.)

#Note this should be in a folder
initialBiomasS <- raster("C:/users/ieddy/Downloads/InitialBiomassMap/biomassMap2011.tif")
kNNBiomass <- raster("C:/users/ieddy/Downloads/InitialBiomassMap/RawBiomassMap.tif")

filePath <- file.path("C:/users/ieddy/downloads",
                      'CCSM4_RCP85_3Arc_asym10to3',
                      'CCSM4_RCP85_3Arc_asym10to3/figures')
#postSimulation scripts
aNPP <- list.files(filePath, pattern = "*ANPP", full.names = TRUE) %>% lapply(., 'raster')
names(aNPP) <- list.files(filePath, pattern = '*ANPP')

biomass <- list.files(filePath, pattern = "*simulatedBiomassMap_Year", full.names = TRUE) %>% lapply(., 'raster')
names(biomass) <- list.files(filePath, pattern = '*simulatedBiomassMap_Year')

mortality <- list.files(filePath, pattern = "*mortality", full.names = TRUE) %>% lapply(., 'raster')
names(mortality) <- list.files(filePath, pattern = '*mortality')



#convert some
makeMgPerHa <- function(raster) {
  rasValues <- getValues(raster)
  raster <- setValues(raster, values = round(rasValues/100), digits = 2)
  return(raster)
}
makePercent <- function(numerator, denominator) {

  top <- as.numeric(getValues(numerator))
  bot <- as.numeric(getValues(denominator))
  percentChange <- (top - bot)/bot * 100
  asPercent <- setValues(numerator, percentChange)
  return(asPercent)
}

makeDiff <- function(new, original) {

  newValues <- as.numeric(getValues(new))
  originalValues <- as.numeric(getValues(original))
  diffRas <- setValues(new, newValues - originalValues)
  return(diffRas)
}

aNPPChange <- makePercent(denominator = aNPP$ANPP_Year2021.tif,
                          numerator = aNPP$ANPP_Year2101.tif)

Biomass2011 <- makeMgPerHa(initialBiomasS)
Biomass2101 <- makeMgPerHa(biomass$simulatedBiomassMap_Year2101.tif)
BiomassChange <- makePercent(denominator = Biomass2011, numerator = Biomass2101)
BiomassDiff <- makeDiff(Biomass2101, Biomass2011)
# writeRaster(BiomassChange, "C:/ian/Campbell/RIA/ProjectResults/RCP85_asym_BiomassChangePct.tif", overwrite = TRUE)
# writeRaster(BiomassDiff, "C:/Ian/Campbell/RIA/ProjectResults/RCP85_asym_BiomassDiffMgPerHa.tif", overwrite = TRUE)
# writeRaster(Biomass2011, "C:/Ian/Campbell/RIA/ProjectResults/RCP85_asym_Biomass2011.tif", overwrite = TRUE)
# writeRaster(Biomass2101, "C:/Ian/Campbell/RIA/ProjectResults/RCP85_asym_Biomass2101.tif", overwrite = TRUE)

makeHistogram <- function(raster) {
  vals <- getValues(raster) %>%
    na.omit(.) %>%
    data.frame('Biomass' = .)

  ggplot(vals, aes(x = Biomass)) +
    geom_histogram(binwidth = 5, color = 'black') +
    theme_minimal() +
    theme(text = element_text(size = 18),
          axis.title = element_text(size = 20, face = 'bold')) +
    scale_y_continuous(labels = scales::scientific)


}
#####FIGURE 1
#Biomass change figure uses this histogram
# makeHistogram(BiomassDiff)
#####
ecoregions <- prepInputs("")






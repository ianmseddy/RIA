#make yukon study area
library(sp)
library(raster)
library(magrittr)
library(sf)
library(smoothr) #for hole filling
library(reproducible) #our own package with the function prepInputs -
#prepInputs will download to destinationPath and crop/mask/reproject if you pass studyArea or rasterToMatch

studyArea <- prepInputs(url = 'https://drive.google.com/file/d/1FlC5YdjNF8wXLcA4hQxLvrRjVC6ShqND/view?usp=sharing',
                        destinationPath = 'inputs/Yukon') %>%
  sf::st_as_sf(.)

YukonBoundaries <- prepInputs(url = 'https://drive.google.com/file/d/1dp5E2G7JdeVgzqztfD7wMLl2Mg-qIG8i/view?usp=sharing',
                              destinationPath = 'inputs/Yukon') %>%
  .[.$PRNAME == 'Yukon',] %>%
  spTransform(.,CRSobj = crs(studyArea)) %>%
  sf::st_as_sf(.)

studyAreaYukon <- sf::st_snap(YukonBoundaries, studyArea, tolerance = 1) %>%
  sf::st_intersection(., studyArea)
centroid <- sf::st_centroid(studyAreaYukon)
studyAreaYukon <- st_cast(studyAreaYukon)
NotSlivers <- st_contains(studyAreaYukon, centroid)
which <- lapply(NotSlivers, length) > 0
studyAreaYukon <- studyAreaYukon[which,]

sf::st_write(studyAreaYukon, dsn = 'inputs/Yukon/', layer = 'studyAreaYukon', driver = 'ESRI Shapefile')

BCBoundaries <- prepInputs(url = 'https://drive.google.com/file/d/1dp5E2G7JdeVgzqztfD7wMLl2Mg-qIG8i/view?usp=sharing',
                              destinationPath = 'inputs/BC')%>%
  .[.$PREABBR == 'B.C.',] %>%
  spTransform(.,CRSobj = crs(studyArea)) %>%
  sf::st_as_sf(.)


studyAreaBC <- sf::st_snap(BCBoundaries, studyArea, tolerance = 1) %>%
  sf::st_intersection(., studyArea)
centroid <- sf::st_centroid(studyAreaBC)
studyAreaBC <- st_cast(studyAreaBC)
NotSlivers <- st_contains(studyAreaBC, centroid)
which <- lapply(NotSlivers, length) > 0
studyAreaBC <- studyAreaBC[which,]
st_buffer(studyAreaBC, 0)
studyAreaBC <- smoothr::fill_holes(studyAreaBC, threshold = 5000)
sf::st_write(studyAreaBC, dsn = "inputs/BC", layer = "studyAreaBC", driver = "ESRI Shapefile")

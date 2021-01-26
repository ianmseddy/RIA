#make yukon study area
library(sf)
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

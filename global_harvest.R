library(reticulate)
use_python("/usr/bin/python3")
#library(raster)
library(SpaDES)

setPaths(modulePath = 'modules',
         inputPath = 'inputs',
         outputPath = 'outputs',
         cachePath = 'cache')
paths <- getPaths()
modules <- list('spades_ws3_dataInit', 'spades_ws3')
base.year <- 2015
basenames <- c("tsa40", "tsa41")
horizon <- 1
times <- list(start = 0, end = horizon - 1)

tifPath = "tif"
hdtPath = "hdt"
hdtPrefix = "hdt_"

objects <-  list()
params <- list(spades_ws3_dataInit = list(basenames = basenames,
                                          tifPath = tifPath,
                                          hdtPath = hdtPath,
                                          hdtPrefix = hdtPrefix,
                                          .saveInitialTime = 0,
                                          .saveInterval = 1,
                                          .saveObjects = c("landscape"),
                                          .savePath = file.path(paths$outputPath, "landscape")),
               spades_ws3 = list(basenames = basenames,
                                 tifpath = 'tif',
                                 horizon = 1))

sim <- simInit(paths=paths, modules = modules, times=times, params= params, objects = objects)
simOut <- spades(sim, debug=TRUE)


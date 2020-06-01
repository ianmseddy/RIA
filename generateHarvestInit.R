#integrated harvest
setPaths(inputPath = 'inputs',
         outputPath = 'outputs',
         cachePath = 'harvestCache',
         modulePath = 'modules')
paths <- getPaths()

horizon <- 1
times <- list(start = 0, end = horizon - 1)
harvestParams <- list(spades_ws3_dataInit = list(basenames = basenames,
                                          tifPath = "tif",
                                          hdtPath = "hdt",
                                          hdtPrefix = "hdt_",
                                          .saveInitialTime = 0,
                                          .saveInterval = 1,
                                          .saveObjects = c("landscape"),
                                          .savePath = file.path(paths$outputPath, "landscape")))

harvestFiles <- Cache(simInitAndSpades, paths=paths, modules = 'spades_ws3_dataInit',
                      times=times, params= harvestParams, objects = list())

rm(horizon, times, harvestParams)

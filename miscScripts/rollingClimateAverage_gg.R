ykATA <- projectRaster(climObjs$ATAstack, to = climObjs$CMInormal)
ykATA <- mask(ykATA, climObjs$CMInormal)
ykCMI <- projectRaster(climObjs$CMIstack, to = climObjs$CMInormal)
ykCMI <- mask(ykCMI, climObjs$CMInormal)


testFun <- function(rasterStack, layer) {
  raster <- rasterStack[[layer]]
  a <- median(getValues(raster), na.rm = TRUE)
  return(a)
}

IMNATA <- lapply(names(ykATA), FUN = testFun, rasterStack = ykATA)
IMNATA <- unlist(IMNATA)
IMNCMI <- lapply(names(ykCMI), FUN = testFun, rasterStack = ykCMI)
IMNCMI <- unlist(IMNCMI)

climDat <- data.table(year = 2011:2100, ATA = IMNATA, CMI = IMNCMI)
library(ggplot2)

#calculate rolling average

climDat[,paste0("ravg_", c("CMI", "ATA")) := lapply(.SD, zoo::rollmean, k = 5, na.pad = TRUE), .SDcols = c("CMI", "ATA")]
climDat$year <- as.numeric(climDat$year)


a <- ggplot(data = climDat, aes(x = ravg_ATA/10, y = ravg_CMI, colour = year)) +
  geom_path(size = 1.5, alpha = 0.5) +
  scale_colour_gradientn(colours = rainbow(10)) +
  labs(x = "5-year rolling median ATA (°C)", y = "5-year rolling median CMI",
       title = "IMN CM4 RCP 4.5")
a


library(magrittr)
library(raster)
library(reproducible)
library(data.table)
studyAreaLarge <- shapefile("C:/Ian/Campbell/RIA/RIA/inputs/RIA_fiveTSA.shp")
stl <- spTransform(x = studyAreaLarge, CRSobj = crs('+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0'))
rasterToMatchLarge <- raster("C:/ian/Campbell/RIA/RIA/inputs/RIA5tsaRTM.tif")

BEC2020 <- raster(x = "C:/Ian/data/BC/FlyingBECs/ConsesusBEC/mx_2020/w001001.adf")
BEC2050 <- raster("C:/Ian/data/BC/FlyingBECs/ConsesusBEC/mx_2050/w001001.adf")
BEC2080 <- raster("C:/Ian/data/BC/FlyingBECs/ConsesusBEC/mx20g_2080/dblbnd.adf")
BECref <- raster("C:/Ian/Data/BC/FlyingBECs/ReferenceBEC/BEC_zone.tif")

#Fix the classification scheme, add year to distinguish between different ID fields
dt2020 <- as.data.table(BEC2020@data@attributes) %>%
  .[ID %in% getValues(BEC2020)]
dt2020$year <- 2020
dt2020$VAR <- gsub(" ", "", dt2020$VAR, fixed = TRUE)

dt2050 <- as.data.table(BEC2050@data@attributes) %>%
  .[ID %in% getValues(BEC2020)]
dt2050$year <- 2050
dt2050$VAR <- gsub(" ", "", dt2050$VAR, fixed = TRUE)

dt2080 <- as.data.table(BEC2080@data@attributes) %>%
  .[ID %in% getValues(BEC2080)]
dt2080$year <- 2080
dt2080$VAR <- gsub(" ", "", dt2080$VAR, fixed = TRUE)


dtref <- as.data.table(BECref@data@attributes) %>%
  .[ID %in% getValues(BECref)]
dtref$year <- 2005
dtref$VAR <- gsub(" ", "", dtref$VAR, fixed = TRUE)

key <- as.factor(c(dtref$VAR, dt2020$VAR, dt2050$VAR, dt2080$VAR))

year <- c(dtref$year, dt2020$year, dt2050$year, dt2080$year)
newKey <- data.table(newKey = key, newCode = as.integer(as.numeric(key)), year = year)
#join the key to the raster values of each and reclassify. consider using reclassify? nah
newKey <- unique(newKey[, .(newKey, newCode)])
#2020
dt2020j <- newKey[dt2020, on = c(newKey = 'VAR')]
ras2020 <- data.table(ID = getValues(BEC2020))
ras2020 <- dt2020j[ras2020, on = c(ID = 'ID')]
BEC2020r <- setValues(BEC2020, ras2020$newCode)
dt2020j[, c('year', 'ID') := NULL]
setnames(dt2020j, old = c('newKey', 'newCode'), new = c('VAR', 'ID'))
setcolorder(dt2020j, c("ID", "COUNT", "VAR", "MX", 'ZONE'))
setkey(dt2020j, ID)
BEC2020r@data@attributes[[1]] <- dt2020j
writeRaster(BEC2020r, "C:/Ian/Data/BC/FlyingBECs/reclassifiedBEC2020.grd", overwrite = TRUE)
# proof1 <- raster("C:/Ian/Data/BC/FlyingBECs/reclassifiedBEC2020.grd")

#2050
dt2050j <- newKey[dt2050, on = c(newKey = 'VAR')]
ras2050 <- data.table(ID = getValues(BEC2050))
ras2050 <- dt2050j[ras2050, on = c(ID = 'ID')]
BEC2050r <- setValues(BEC2050, ras2050$newCode)
dt2050j[, c('year', 'ID') := NULL]
setnames(dt2050j, old = c('newKey', 'newCode'), new = c('VAR', 'ID'))
setcolorder(dt2050j, c("ID", "COUNT", "VAR", "MX", 'ZONE'))
setkey(dt2050j, ID)
BEC2050r@data@attributes[[1]] <- dt2050j
writeRaster(BEC2050r, "C:/Ian/Data/BC/FlyingBECs/reclassifiedBEC2050.grd", overwrite = TRUE)


#2080
dt2080j <- newKey[dt2080, on = c(newKey = 'VAR')]
ras2080 <- data.table(ID = getValues(BEC2080))
ras2080 <- dt2080j[ras2080, on = c(ID = 'ID')]
BEC2080r <- setValues(BEC2080, ras2080$newCode)
dt2080j[, c('year', 'ID') := NULL]
setnames(dt2080j, old = c('newKey', 'newCode'), new = c('VAR', 'ID'))
setcolorder(dt2080j, c("ID", "COUNT", "VAR", "MX", 'ZONE'))
setkey(dt2080j, ID)
BEC2080r@data@attributes[[1]] <- dt2080j
writeRaster(BEC2080r, "C:/Ian/Data/BC/FlyingBECs/reclassifiedBEC2080.grd", overwrite = TRUE)

#ref

#There is one extra row in the BEC ref data
BECref <- postProcess(BECref, rasterToMatch = BEC2080r)

dtrefj <- newKey[dtref, on = c(newKey = 'VAR')]
rasref <- data.table(ID = getValues(BECref))
rasref <- dtrefj[rasref, on = c(ID = 'ID')]
BECrefr <- setValues(BECref, rasref$newCode)
dtrefj[, c('year', 'ID') := NULL]
setnames(dtrefj, old = c('newKey', 'newCode'), new = c('VAR', 'ID'))
setcolorder(dtrefj, c("ID", "COUNT", "VAR", "SUBZ", 'ZONE'))
setkey(dtrefj, ID)
BECrefr@data@attributes[[1]] <- dtrefj
writeRaster(BECrefr, "C:/Ian/Data/BC/FlyingBECs/reclassifiedBECref.grd", overwrite = TRUE)
BECstack <- stack(BECrefr, BEC2020r, BEC2050r, BEC2080r)
writeRaster(BECstack, filename = "C:/Ian/Data/BC/FlyingBECs/projectedBECzones.grd")

#Crop to the RIA
riaRef <- postProcess(x = BECrefr, rasterToMatch = rasterToMatchLarge)
ria2020 <- postProcess(x = BEC2020r, rasterToMatch = rasterToMatchLarge)
ria2050 <- postProcess(x = BEC2050r, rasterToMatch = rasterToMatchLarge)
ria2080 <- postProcess(x = BEC2080r, rasterToMatch = rasterToMatchLarge)

test2020 <- as.data.table(table(getValues(ria2020)))
test2050 <- as.data.table(table(getValues(ria2050)))
test2080 <- as.data.table(table(getValues(ria2080)))
testref <- as.data.table(table(getValues(riaRef)))

test2020$year <- 2020
test2050$year <- 2050
test2080$year <- 2080
testref$year <- 2005
all <- rbind.data.frame(test2020, test2050, test2080, testref)
setnames(all, 'V1', "newCode")
all[, newCode := as.numeric(newCode)]
setkey(all, newCode)

setkey(newKey, newCode)
all <- newKey[all]
all <- all[!is.na(newKey)]
setnames(all, c("newKey", "newCode", "N", "year"), c('variant', 'rasterCode', 'N', 'year'))
write.csv(all, "C:/Ian/Data/BC/FlyingBECs/RIA_variant_key.csv")

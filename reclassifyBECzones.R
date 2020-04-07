library(raster)
library(magrittr)
BECref <- raster("C:/Users/ianms/Downloads/BEC_zone/BEC_zone.tif")
#BECref has one row fewer
BEC2020 <- raster("C:/users/ianms/Downloads/consensus/mx_2020/w001001.adf") %>%
  crop(., y = BECref)
BEC2050 <- raster("C:/users/ianms/Downloads/consensus/mx_2050/w001001.adf") %>%
  crop(., y = BECref)
BEC2080 <- raster("C:/Users/ianms/Downloads/consensus/mx20g_2080/w001001.adf") %>%
  crop(., y = BECref)

dt2020 <- as.data.table(BEC2020@data@attributes)
dt2020$id2020 <- dt2020$ID
dt2020[, c('ID', 'MX', 'COUNT') := NULL]

dt2050 <- as.data.table(BEC2050@data@attributes)
dt2050$id2050 <- dt2050$ID
dt2050[, c('ID', 'MX', 'COUNT') := NULL]

dt2080 <- as.data.table(BEC2080@data@attributes)
dt2080$id2080 <- dt2080$ID
dt2080[, c('ID', 'MX', 'COUNT') := NULL]

dtref <- as.data.table(BECref@data@attributes)
dtref$idref <- dtref$ID
dtref[, c('Rowid', 'ID', 'SUBZ', 'COUNT') := NULL]

dtall <- dt2020[dtref, on = c('VAR' = "VAR", 'ZONE' = 'ZONE')]
dtall <- dt2050[dtall, on = c('VAR' = "VAR", 'ZONE' = 'ZONE')]
dtall <- dt2080[dtall,, on = c('VAR' = "VAR", 'ZONE' = 'ZONE')]

dtall$ID <- dtall$idref
#turns out the reference BEC has all BECs (no new BECs materialize)
#now join new data.table value with old raster
resetValues <- function(BECraster, oldkey, keyname) {
  oldkey <- copy(oldkey)
  vals <- data.table(ID = getValues(BECraster), cellNumber = 1:ncell(BECraster))
  #the multiple NA will cause problem with NA raster when joining unless you omit

  noNAs <- na.omit(oldkey)
  setkey(vals, ID)
  setkeyv(noNAs, keyname)
  newkey <- noNAs[vals]

  #order by cellNumber
  setkey(newkey, cellNumber)
  newBEC <- setValues(BECraster, newkey$ID)

  #build attribute table
  counts <- as.data.table(table(newkey$ID))
  setnames(counts, old = c('V1', 'N'), new = c("ID", "COUNT"))
  counts$ID <- as.integer(counts$ID)
  oldkey <- counts[oldkey, on = c("ID" = "ID")]
  oldkey[is.na(COUNT), COUNT := 0]
  oldkey <- oldkey[, .SD, .SDcols = c("ID", "COUNT", "ZONE", "VAR")]

  newBEC@data@attributes[[1]] <- oldkey
  return(newBEC)
}


newBEC2020 <- resetValues(BECraster = BEC2020, oldkey = dtall, keyname = "id2020")
newBEC2050 <- resetValues(BECraster = BEC2050, oldkey = dtall, keyname = "id2050")
newBEC2080 <- resetValues(BECraster = BEC2080, oldkey = dtall, keyname = "id2080")
newBECref <- resetValues(BECraster = BECref, oldkey = dtall, keyname = "idref" )


reclassifiedBECs <- stack(newBECref, newBEC2020, newBEC2050, newBEC2080)
names(reclassifiedBECs) <- c("BECref", "BEC2020", "BEC2050", "BEC2080")
writeRaster(reclassifiedBECs, "C:/PFC/reclassifiedBECs.grd", overwrite = TRUE, RAT = TRUE)

dat <- as.data.table(newBECref@data@attributes[[1]])
dat[, zsv := gsub(pattern = "* ", replacement = "", x = VAR)]
key <- dat[, .SD, .SDcols = c("ID", 'ZONE', "VAR", 'zsv')]
write.csv("data/BECkey.csv")

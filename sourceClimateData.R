{
  if (scenario == "RCP8.5") {
    ATAstack <- prepInputs(url = "https://drive.google.com/open?id=16BNxOXnt0indxUUht5A_vKbeVb_0lDCr",
                           targetFile = 'RIA_1ArcMinute_CCSM4_85_ATA2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CCSM4_85_ATA2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CCSM4_85_ATA2011-2100.grd',
                           fun = 'raster::stack')
    CMIstack <- prepInputs(url = 'https://drive.google.com/open?id=16BNxOXnt0indxUUht5A_vKbeVb_0lDCr',
                           targetFile = 'RIA_1ArcMinute_CCSM4_85_CMI2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CCSM4_85_CMI2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CCSM4_85_CMI2011-2100.grd',
                           fun = 'raster::stack') #get the high quality stuff
    CMInormal <- prepInputs(url = "https://drive.google.com/open?id=1AH_jAWi39pAeLtjHRuqEn4FArXNUt-ap",
                            targetFile = 'RIA_1ArcMinute_CCSM4_CMInormal.tif',
                            fun = 'raster::raster',
                            studyArea = studyArea,
                            rasterToMatch = rasterToMatch,
                            method = 'bilinear',
                            destinationPath = 'inputs')

  } else if (scenario == "RCP4.5") {
    ATAstack <- prepInputs(url = "https://drive.google.com/open?id=1jNDWarev57Az2Z1j2doJp5C9nGyZ6Tmc",
                           targetFile = 'RIA_1ArcMinute_CCSM4_RCP45_ATA2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CCSM4_RCP45_ATA2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CCSM4_45_ATA2011-2100.grd',
                           fun = 'raster::stack')
    CMIstack <- prepInputs(url = 'https://drive.google.com/open?id=1jNDWarev57Az2Z1j2doJp5C9nGyZ6Tmc',
                           targetFile = 'RIA_1ArcMinute_CCSM4_RCP45_CMI2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CCSM4_RCP45_CMI2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CCSM4_45_CMI2011-2100.grd',
                           fun = 'raster::stack') #get the high quality stuff
    CMInormal <- prepInputs(url = "https://drive.google.com/open?id=1AH_jAWi39pAeLtjHRuqEn4FArXNUt-ap",
                            targetFile = 'RIA_1ArcMinute_CCSM4_CMInormal.tif',
                            fun = 'raster::raster',
                            studyArea = studyArea,
                            rasterToMatch = rasterToMatch,
                            method = 'bilinear',
                            destinationPath = 'inputs')
  }
  climData = list(ATAstack = ATAstack,
                  CMIstack = CMIstack,
                  CMInormal = CMInormal)
  return(climData)
}
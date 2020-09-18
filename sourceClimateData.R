sourceClimData <- function(scenario, model = 'CCSM4'){
  CMInormal <- prepInputs(url = "https://drive.google.com/open?id=1AH_jAWi39pAeLtjHRuqEn4FArXNUt-ap",
                          targetFile = 'RIA_1ArcMinute_CCSM4_CMInormal.tif',
                          fun = 'raster::raster',
                          studyArea = studyArea,
                          rasterToMatch = rasterToMatch,
                          method = 'bilinear',
                          destinationPath = 'inputs')

  if (model == "CCSM4") {
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
    }

  }
} else if (model == 'CanESM2') {
  if (scenario == "RCP8.5") {
    ATAstack <- prepInputs(url = "https://drive.google.com/file/d/17zBna_wegLmQs_m4FQd_JBhUcA0Da6lR/view?usp=sharing",
                           targetFile = 'RIA_1ArcMinute_CanESM2_RCP85_ATA2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CanESM2_RCP85_ATA2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CanESM2_85_ATA2011-2100.grd',
                           fun = 'raster::stack')
    CMIstack <- prepInputs(url = 'https://drive.google.com/file/d/17zBna_wegLmQs_m4FQd_JBhUcA0Da6lR/view?usp=sharing',
                           targetFile = 'RIA_1ArcMinute_CanESM2_RCP85_CMI2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CanESM2_RCP85_CMI2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CanESM2_85_CMI2011-2100.grd',
                           fun = 'raster::stack') #get the high quality stuff

  } else if (scenario == "RCP4.5") {
    ATAstack <- prepInputs(url = "https://drive.google.com/file/d/1RMSiv4_M57IKDHrs9amMyctkyRWvclGH/view?usp=sharing",
                           targetFile = 'RIA_1ArcMinute_CanESM2_RCP45_ATA2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CanESM2_RCP45_ATA2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CanESM2_45_ATA2011-2100.grd',
                           fun = 'raster::stack')
    CMIstack <- prepInputs(url = 'https://drive.google.com/file/d/1RMSiv4_M57IKDHrs9amMyctkyRWvclGH/view?usp=sharing',
                           targetFile = 'RIA_1ArcMinute_CanESM2_RCP45_CMI2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CanESM2_RCP45_CMI2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CanESM2_45_CMI2011-2100.grd',
                           fun = 'raster::stack') #get the high quality stuff

  }
} else if (model == 'CNRM CM5') {
  if (scenario == 'RCP4.5'){
    ATAstack <- prepInputs(url = "https://drive.google.com/file/d/1KwobnIwRd9klNR4_45X_WOnjTLFQgS8J/view?usp=sharing",
                           targetFile = 'RIA_1ArcMinute_CNRM_CM5_RCp45_ATA2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CNRM_CM5_RCp45_ATA2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CanESM2_45_ATA2011-2100.grd',
                           fun = 'raster::stack')
    CMIstack <- prepInputs(url = 'https://drive.google.com/file/d/1KwobnIwRd9klNR4_45X_WOnjTLFQgS8J/view?usp=sharing',
                           targetFile = 'RIA_1ArcMinute_CNRM_CM5_RCp45_CMI2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CNRM_CM5_RCp45_CMI2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CNRM_CM5_45_CMI2011-2100.grd',
                           fun = 'raster::stack') #get the high quality stuff
  } else {
    stop("don't have RCP 8.5")
  }
} else if (model == 'CSIRO MK3') {
  if (scenario == 'RCP4.5') {
    ATAstack <- prepInputs(url = "https://drive.google.com/file/d/1iye_G-F6Dxm7Pd4IDbgdwwvJ-KW9pj3-/view?usp=sharing",
                           targetFile = 'RIA_1ArcMinute_CSIRO_mk3_ATA2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CSIRO_mk3_ATA2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CSIRO_mk3_45_ATA2011-2100.grd',
                           fun = 'raster::stack')
    CMIstack <- prepInputs(url = 'https://drive.google.com/file/d/1iye_G-F6Dxm7Pd4IDbgdwwvJ-KW9pj3-/view?usp=sharing',
                           targetFile = 'RIA_1ArcMinute_CSIRO_mk3_CMI2011-2100.grd',
                           alsoExtract = 'RIA_1ArcMinute_CSIRO_mk3_CMI2011-2100.gri',
                           destinationPath = 'inputs',
                           filename2 = 'inputs/RIA_1ArcMinute_CSIRO_mk3_45_CMI2011-2100.grd',
                           fun = 'raster::stack') #get the high quality stuff
  } else {
    stop("don't have RCP 8.5")
  }
}

climData = list(ATAstack = ATAstack,
                CMIstack = CMIstack,
                CMInormal = CMInormal)
return(climData)
######################
# Topic: GSM drone shots analysis
# Purpose: (1) To identify the hotspot area for drone shots to detect surface changes and produce kmz
#          (2) To extract the coordinates from different drone shots and calculate ground seperation
# Author: One Tech Agency
###################### 

# load libraries
library(sf)
library(dplyr)
library(terra)
library(exifr) # to extract exif data
library(geosphere) # to compare coordinates between different GPS coordinates
library(mapview)

# get datasets
# EOS-RS Damage Proxy Map: Myanmar, Earthquakes, 5 Apr 2025, v0.9 from EOS-RS https://eos-rs-products.earthobservatory.sg/EOS-RS_202503_Myanmar_Earthquakes/
# drone photos from TSBM

# load datasets
rupture <- st_read("data/rupture.json")
dpm <- rast("data/EOS-RS_20250405_DPM_S1_Myanmar_Earthquakes_v0.9.tif") 
dpm <- dpm$`EOS-RS_20250405_DPM_S1_Myanmar_Earthquakes_v0.9_4` # use the latest release
# res (dpm) # 0.0002777778 degree (EPSG:4326) 1 arc-sec approx. 30m

### 1. Identify the hotspot areas ###
# 1.2 manipulate damage proxy map 
# # improve efficiency
dpm[dpm == 0] <- NA # set 0 to NA to exclude no damage areas (NA - 153,132,759 cells)  
summary (values(dpm)) # min 1, max 255, median 255, mean 198, 1st Quartile 137 
# # set cut off values based on the summary statistics
cutoff_strict <- 255 # extreme damage only
cutoff_mid <- 198 # above average damage
cutoff_sensitive <- 137 # includes moderate and above
# # create raster layers according to cut off values (Binary Masks - TRUE/FALSE raster showing pixels that pass the threshold)
dpm_strict <- dpm == 255
dpm_mid <- dpm > cutoff_mid
dpm_sensitive <- dpm > cutoff_sensitive
# # save the binary masks
# terra::writeRaster(dpm_strict, "outputs/dpm_strict.tif", overwrite=TRUE)
# terra::writeRaster(dpm_mid, "outputs/dpm_mid.tif", overwrite=TRUE)
# terra::writeRaster(dpm_sensitive, "outputs/dpm_sensitive.tif", overwrite=TRUE)

# 1.3 create 25sqkm areas
# # count the number of pixels in each 5x5km window and aggregate 
# factor 167 - (1sqKM - 33x33 pixels as resolution is approx 30m)
hs_strict <- aggregate(dpm_strict, fact=167, fun=sum, na.rm=TRUE)
hs_mid <- aggregate(dpm_mid, fact=167, fun=sum, na.rm=TRUE)
hs_sensitive <- aggregate(dpm_sensitive, fact=167, fun=sum, na.rm=TRUE)
# # save the raster layers
# terra::writeRaster(hs_strict, "outputs/hs_strict.tif", overwrite=TRUE)
# terra::writeRaster(hs_mid, "outputs/hs_mid.tif", overwrite=TRUE)
# terra::writeRaster(hs_sensitive, "outputs/hs_sensitive.tif", overwrite=TRUE)
# # check the results (mean approx 34-43, median approx 1-3)
# summary(values(hs_sensitive))

# 1.4 create hotspot areas
# 1.4.1 convert 0 to NA
hs_strict[hs_strict ==0 ] <- NA
hs_mid[hs_mid == 0] <- NA
hs_sensitive[hs_sensitive == 0] <- NA

# 1.4.2 Option 1: assign NA to cells with less than threshold values (mean - 51.03758)
hs_strict[hs_strict < mean(values(hs_strict),na.rm=T)] <- NA
hs_mid[hs_mid < mean(values(hs_mid),na.rm=T)] <- NA
hs_sensitive[hs_sensitive < mean(values(hs_sensitive),na.rm=T)] <- NA

# 1.5 save as polygons
# # convert to polygons
zones <- as.polygons(hs_strict, dissolve=FALSE, values=TRUE) # focus only severly damaged buidlings
zones$ID <- sprintf("gsm%02d", 1:nrow(zones)) # create ID 
names(zones)[names(zones) == "EOS-RS_20250405_DPM_S1_Myanmar_Earthquakes_v0.9_4"] <- "values" # rename
# # save as kml
writeVector(zones, "outputs/zones.kml", filetype = "KML")

# 1.6 visualize
mapview(zones, zcol = "values", layer.name = "Count of pixels <br/> with maximum damage") + 
  mapview(st_zm(rupture, drop = TRUE, what = "ZM"),color="red", col.regions ="red")

### 2. Analyze coordinates from drone shots ###
# 2.1 set up ExifTool (as needed)
# # Step 1: download standalone ExifTool from https://exiftool.org/ - v13.27 in this analysis
# # Step 2: locate the exiftool.exe file and set the path
# options(exifr.exiftoolpath = "data/exiftool-13.27_64/exiftool.exe")

# 2.2 Extract EXIF data from photo
# # set the directory ory to the folder containing the drone photos
photo <- list.files(path = "EOS-RS", pattern = "\\.JPG$", full.names = TRUE, ignore.case = TRUE)
# # extract raw EXIF data
raw_data <- read_exif(photo)
# # select relevant columns
data <- raw_data %>% select(
  Make, Model,
  LRFStatus, LRFTargetAbsAlt, LRFTargetAlt, LRFTargetLat, LRFTargetLon, # Laser range finder parameters
  Megapixels, ImageSize, # image size
  RtkFlag, RtkStdHgt, RtkStdLat, RtkStdLon, # RTK (Real-Time Kinematic) parameters
  GPSAltitude, GPSLatitude, GPSLongitude, GPSMapDatum, # GPS parameters
  GpsStatus, GPSPosition, # more GPS parameters
)

# 2.3 compare coordinates
# # load GPS coordinates
ge <- c(96.06752222, 20.50791111) # manually acquired from Google Earth
oblique <- c(data$LRFTargetLon[1], data$LRFTargetLat[1]) # laser range finder from drone - oblique photo 
nadir <- c(data$LRFTargetLon[2], data$LRFTargetLat[2]) # laser range finder from drone - nadir photo
nd_camera <- c(as.numeric(strsplit(data$GPSPosition[2], " ")[[1]][2]), # camera position lat from nadir photo
               as.numeric(strsplit(data$GPSPosition[2], " ")[[1]][1])) # camera position lon from nadir photo 
# # calculate distances
nd_ndcam <- distHaversine(nadir, nd_camera) # distance between Google Earth and nadir camera position
nd_oblique <- distHaversine(nadir, oblique) # distance between Google Earth and oblique camera position
ge_ndcam <- distHaversine(ge, nd_camera) # distance between Google Earth and nadir camera position
# # create a data frame to store the results (around 5m ground separation)
data.frame(
  name = c("lrfnd_ndcam", "lrfnd_lrfob", "ge_ndcam"),
  value = c(nd_ndcam, nd_oblique, ge_ndcam)
)

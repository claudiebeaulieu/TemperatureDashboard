################################################################################
# Temperature Monitoring Dashboard
################################################################################
# Description: Interactive Shiny dashboard for exploring surface temperature 
#              trends with changepoint detection analysis
# Data Source: Berkeley Earth Surface Temperature 
################################################################################

# Script to fetch the raw data and place in the /data/raw/ folder.


raw_nc_path = here::here("data", "raw", "Land_and_Ocean_LatLong1.nc")

# Direct URL hosting the file for berkeleyearth.org
data_url = "https://berkeley-earth-temperature.s3.us-west-1.amazonaws.com/Global/Gridded/Land_and_Ocean_LatLong1.nc"

# Download automatically if missing from the /data/raw/ folder
if (!file.exists(raw_nc_path)) {
  message("Raw data file missing. Downloading from Berkeley Earth website. ")
  dir.create(dirname(raw_nc_path), showWarnings = FALSE, recursive = TRUE)
  
  download.file(url = data_url, 
    destfile = raw_nc_path, 
    mode     = "wb", 
    method   = "libcurl")
  
  message("Download completed successfully!")
}
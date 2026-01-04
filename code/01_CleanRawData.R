################################################################################
######################## Temperature dashboard project ##############################
################################################################################

################################################################################
# Script to import the raw data and clean up into 3-D arrays for the gridded 
# datasets and a data table for the global mean time series.

## Gridded datasets #####

dataset_name = "Berkeley"
Tas_varname = "temperature" 
lon_varname = "longitude"
lat_varname = "latitude"
time_varname = "time"
start_year = 1850
end_year = 2024

file_path = "./data/Land_and_Ocean_LatLong1.nc"

ImportncData(file_path,dataset_name,Tas_varname,lon_varname,lat_varname,time_varname,start_year,end_year)

# A file named annual_Berkeley_anom.RData containing annual anomalies has been created 
# in /data. Those are the intermediate datasets used in this study, not saved in the repository as they are too large.

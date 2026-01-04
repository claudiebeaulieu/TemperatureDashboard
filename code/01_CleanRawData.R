################################################################################
######################## Temperature dashboard project ##############################
################################################################################

################################################################################
# Script to import the raw data and clean up into 3-D arrays for the gridded 
# datasets and a data table for the global mean time series.

## Gridded datasets #####

dataset_name=c("NASA","HadCRUT","NOAA","Berkeley","DCENT")
Tas_varname = c("tempanomaly","tas_mean","air","temperature","temperature") # The variables we want from the different gridded datasets
lon_varname = c("lon","longitude","lon","longitude","lon")
lat_varname = c("lat","latitude","lat","latitude","lat")
time_varname = "time"
start_year = c(1880,1850,1850,1850,1850)
end_year = 2024

file_paths=c("./data/raw/gistemp1200_GHCNv4_ERSSTv5.nc",
             "./data/raw/HadCRUT.5.0.2.0.analysis.anomalies.ensemble_mean.nc",
             "./data/raw/air.mon.anom.nc",
             "./data/raw/Land_and_Ocean_LatLong1.nc",
             "./data/raw/DCENT_ensemble_1850_2024_ensemble_mean.nc")

for(i in 1:5){
  ImportncData(file_paths[i],dataset_name[i],Tas_varname[i],lon_varname[i],lat_varname[i],time_varname,start_year[i],end_year)
}
# For each dataset listed above, a file named annual_*dataset_name*_anom.RData containing annual anomalies has been created 
# in /data/processed. Those are the intermediate datasets used in this study, not saved in the repository as they are too large.

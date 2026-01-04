ImportncData = function(filepath,dataset,tas_varname,lon_varname,lat_varname,time_varname,start_year,end_year){
  
  #open the nc file
  lm_filename = paste0(filepath)
  lm_file = nc_open(lm_filename)
  
  # extract variables
  lon = ncvar_get(lm_file, lon_varname)
  lat = ncvar_get(lm_file, lat_varname)
  time = ncvar_get(lm_file,time_varname)
  tas_monthly = ncvar_get(lm_file, tas_varname)
  nc_close(lm_file)
  
  #define new variables to calculate anoms
  nlon = length(lon)
  nlat = length(lat)
  range_yr = seq(start_year,end_year)
  ny = length(range_yr)
  nm = ny*12
  year = rep(range_yr,each=12)
  month = rep(seq(1,12),ny)
  tas_annual = array(data=NA,c(nlon,nlat,ny))
  
  #loop going through longitudes and latitudes to calculate the annual means at each grid
  for(i in 1:nlon){
    for(j in 1:nlat){
      tmp = tas_monthly[i,j,1:nm]
      if(sum(is.na(tmp)) < round(nm,digits=-2)){
        
        for(k in 1:ny){
          index = year == range_yr[k]
          tas_annual[i,j,k] = mean(tmp[index])
        }
      }
    }
  }
  time = range_yr
  save(file=paste0("./data/processed/annual_", dataset, "_anom.RData"),tas_annual,lat,lon,time)
}
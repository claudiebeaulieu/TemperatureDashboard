################################################################################
# Temperature Monitoring Dashboard
################################################################################
# Description: Interactive Shiny dashboard for exploring surface temperature 
#              trends with changepoint detection analysis
# Data Source: Berkeley Earth Surface Temperature 
################################################################################



# ==============================================================================
# Script 02: Process NetCDF to Annual Gridded & Global Mean Time Series
# Output: Lightweight .rds files in data/processed/
# ==============================================================================



#' Compute Annual Means from Monthly NetCDF Climate Data
#'
#' @param nc_path Path to the raw NetCDF file
#' @param var_name Variable name inside NetCDF (default: "temperature")
#' 


# Function that reads raw monthly gridded surface temperature (NetCDF) and 
# computes annual means.

# nc_path = "./data/raw/Land_and_Ocean_LatLong1.nc"

process_annual_means = function(nc_path, var_name = "temperature") {
  
  if (!file.exists(nc_path)) {
    stop(sprintf("File not found at %s. Please run Script 01 first.", nc_path))
  }
  
  message("Opening NetCDF file...")
  nc = nc_open(nc_path)
  
  # 1. Extract Dimensions & Variables
  lon  = ncvar_get(nc, "longitude")
  lat  = ncvar_get(nc, "latitude")
  time = ncvar_get(nc, "time") # Usually decimal years or months since baseline
  tas_monthly = ncvar_get(nc, var_name) # 3D Array: [lon, lat, time]
  
  nc_close(nc)
  
  message("Calculating annual means...")
  
  # 2. Extract unique years
  years = floor(time)
  unique_years = unique(years)
  n = length(unique_years)
  
  n_lon = length(lon)
  n_lat = length(lat)
  
  # Initialize 3D array for annual gridded anomalies [lon, lat, year]
  tas_annual = array(NA, dim = c(n_lon, n_lat, n))
  
  
  # 3. Aggregate monthly slices into annual averages
  for (i in seq_along(unique_years)) {
    yr = unique_years[i]
    yr_idx = which(years == yr)
    
    # Slice time dimension for current year and take mean across months
    monthly_slice = tas_monthly[, , yr_idx, drop = FALSE]
    annual_slice  = apply(monthly_slice, c(1, 2), mean, na.rm = TRUE)
    
    tas_annual[, , i] = annual_slice
    
  }
  
  
  # 5. Save intermediate datasets as fast .rds files
  out_dir = here::here("data", "processed")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  
  saveRDS(
    list(lon = lon, lat = lat, years = unique_years, data = tas_annual),
    file.path(out_dir, "tas_annual_gridded_berkeley.rds")
  )
  
  message("Processing complete! Processed files saved in data/processed/")
}

# --- Execution Block ---
if (sys.nframe() == 0) {
  nc_file = here::here("data", "raw", "Land_and_Ocean_LatLong1.nc")
  process_annual_means(nc_file)
}


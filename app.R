################################################################################
# Temperature Monitoring Dashboard
################################################################################
# Description: Interactive Shiny dashboard for exploring surface temperature 
#              trends with changepoint detection analysis
# Data Source: Berkeley Earth Surface Temperature 
################################################################################


# Script that executes different scripts in order and launch the Shiny App

# Setup
source("./code/00_Setup.R")

# Load processed data
rds_path = here::here("data", "processed", "tas_annual_gridded_berkeley.rds")

# Build the App
source("./code/03_BuildRunApp.R")

# Launch app
app
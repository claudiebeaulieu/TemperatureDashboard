################################################################################
# Temperature Monitoring Dashboard
################################################################################
# Description: Interactive Shiny dashboard for exploring surface temperature 
#              trends with changepoint detection analysis
# Data Source: Berkeley Earth Surface Temperature 
################################################################################


# Script that executes different scripts in order and launch the Shiny App

# Execute different steps to setup, fetch data, process and build App
source("./code/00_Setup.R")
source("./code/01_FetchRawData.R")
source("./code/02_ProcessData.R")
source("./code/03_BuildRunApp.R")

# Launch app
app
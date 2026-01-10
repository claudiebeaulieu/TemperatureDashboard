################################################################################
# Temperature Monitoring Dashboard
################################################################################
# Description: Interactive Shiny dashboard for exploring surface temperature 
#              trends with changepoint detection analysis
# Data Source: Berkeley Earth Surface Temperature 
################################################################################


# Script to load libraries and functions that will be used in this project.

# load libraries #####

library(shiny)
library(shinydashboard)
library(leaflet)
library(ggplot2)
library(dplyr)
library(ncdf4)
library(sp)
library(tidyverse)
library(plotly)
library(bslib)
library(common)
library(leaflet.extras)

# load  analysis functions #####

source('./code/ImportncData.R')
source('./code/StCpts.R')
source('./code/PELTtrendARpJOIN.R')

################################################################################
######################## Temperature dashboard project #########################
################################################################################

################################################################################
# Script to load libraries and functions that will be used in this project.

# load libraries #####

library(shiny)
library(leaflet)
library(ggplot2)
library(dplyr)
library(ncdf4)
library(sp)
library(tidyverse)
library(plotly)
library(bslib)
library(leaflet.extras)

# load functions #####

source('./code/ImportncData.R')
source('./code/StCpts.R')
source('./code/PELTtrendARpJOIN.R')

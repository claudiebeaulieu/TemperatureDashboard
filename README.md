############################

Temperature dashboard project

############################

This repository contains the code required to run a user-friendly dashboard to explore changes in surface temperature trends since 1970.  

The main goal of this project is to allow the users to click on a location of their choice and assess whether changes in surface temperature trends took place at that location.

Steps are as follow:

(0) The script to setting up libraries and load functions to be used in the main scripts in 00_Setup.R

(1) The script to process the raw monthly gridded surface temperature files and computing annual anomalies is in 01_CleanRawData.R.

(2) The script to process monthly gridded annual surface temperature anomalies and analyze for changes in the rate of warming via changepoint detection is in 02_AnalysisGriddedDatasets.R.

(3) The script to run the dashboard and interact with results is in 03_RunDashboard.R

Please contact Claudie Beaulieu (beaulieu@ucsc.edu) for comments, suggestions, etc.

Credits:

Contributors to the development of this dashboard include Courtney Stratton, Kim Porras, Nicholas Chavez, Dongran Zhai and Joelle Yang.

Changepoint code/analysis results is from Beaulieu, Johnson, Killick, Lanzante and Knutson, currently under review at NCC.

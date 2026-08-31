# Temperature Trends Explorer

[![R Shiny](https://img.shields.io/badge/R-Shiny-2165B7?style=flat&logo=R)](https://shiny.posit.co/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An interactive R Shiny dashboard for analyzing global surface temperature anomalies, running real-time changepoint detection, and calculating localized warming trends (°C/decade).

---

## Features

- **Interactive Global Map:** Click any coordinate on a Leaflet map and analyze data at selected location.
- **Real-Time Changepoint Detection:** Automatically fits piecewise linear models to data.
- **Dynamic Trend Analysis:** Calculates localized warming rates (°C/decade) with custom start-year.

---

## Project Structure

```
├── code/                 # Helper functions & analysis modules
│   ├── app.R             # Main Shiny application script
│   └── www/
│       └── styles.css    # Custom CSS styling & alignment fixes
├── data/
│   ├── raw/               # Folder for raw temperature anomaly ncdf file
│   └── processed/         # Cleaned, formatted datasets ready for app 
└── README.md              # Project documentation
```
---

## Getting Started

# Prerequisites

Ensure you have R (>= 4.0.0) installed on your system.

# Install required packages
install.packages(c(
  "here",
  "shiny",
  "shinydashboard",
  "leaflet",
  "ggplot2",
  "dplyr",
  "ncdf4",
  "sp",
  "tidyverse",
  "plotly",
  "bslib",
  "common",
  "leaflet.extras"
))


## Data Pipeline & Running the Shiny App

Follow these steps in R / RStudio to set up your environment, prepare the dataset, and launch the application:

1. Run Setup Script

Initialize project directories and load environment configuration:

R
source("code/00_setup.R")

2. Fetch Raw Data

Download the necessary raw climate anomaly files into data/raw/:

R

source("code/01_fetch_data.R")

3. Process Data

Clean, structure, and export the processed datasets to data/processed/:

R

source("code/02_ProcessData.R")

4. Launch Application

Launch the R Shiny dashboard locally:

R

source("code/03_RunApp.R")


Usage

    Overview Tab: Read background context on methodology, changepoint modeling, and trend estimation.

    Interactive Map Tab:

        Select any location on the global map.

        Adjust the Start Year slider in the header control to filter the time horizon.

        Inspect the generated time series plot and automated model summary text.

License

Distributed under the MIT License. See LICENSE for more information.


Please contact Claudie Beaulieu (beaulieu@ucsc.edu) for comments, suggestions, etc.

Credits:

Contributors to the development of this dashboard include Courtney Stratton, Kim Porras, Nicholas Chavez, Dongran Zhai and Joelle Yang.


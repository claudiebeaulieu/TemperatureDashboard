# Temperature Trends Explorer

An interactive R Shiny dashboard for analyzing global surface temperature anomalies, running real-time changepoint detection, and calculating localized warming trends (°C/decade).

---

## Features

- **Interactive Global Map:** Click any coordinate on a Leaflet map and analyze data at the selected location.
- **Real-Time Changepoint Detection:** Automatically fits piecewise linear models to data.
- **Dynamic Trend Analysis:** Calculates localized warming rates (°C/decade) with a custom start-year filter.

---

## Project Structure
```
├── code/
│   ├── 00_setup.R        # Environment setup & library dependencies
│   ├── 01_fetch_data.R   # Download raw climate datasets
│   ├── 02_ProcessData.R  # Data cleaning, formatting, & preprocessing
│   ├── 03_RunApp.R       # Script to launch the Shiny dashboard
│   ├── app.R             # Main Shiny application script
│   └── www/
│       └── styles.css    # Custom CSS styling & alignment fixes
├── data/
│   ├── raw/              # Folder for raw temperature anomaly NetCDF file
│   └── processed/        # Cleaned, formatted datasets ready for app ingestion
└── README.md             # Project documentation
```
---

## Getting Started

### Prerequisites

Ensure you have R (>= 4.0.0) installed on your system.

Required R packages:

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

---

## Data Pipeline & Running the Shiny App

Follow these steps in R / RStudio to set up your environment, prepare the dataset, and launch the application:

### 1. Run Setup Script
Initialize project directories and load environment configuration:
source("code/00_setup.R")

### 2. Fetch Raw Data
Download the necessary raw climate anomaly files into data/raw/:
source("code/01_fetch_data.R")

### 3. Process Data
Clean, structure, and export the processed datasets to data/processed/:
source("code/02_ProcessData.R")

### 4. Launch Application
Launch the R Shiny dashboard locally:
source("code/03_RunApp.R")

---

## Usage

1. **Overview Tab:** Read background context on methodology, changepoint modeling, and trend estimation.
2. **Interactive Map Tab:**
   * Select any location on the global map by clicking.
   * Adjust the Start Year slider in the header control to decide when to start your analysis.
   * Inspect the data and fitted model with a model summary output.

---

## Dataset & Methodology Citations

### Primary Data Source
* **Berkeley Earth Surface Temperature Anomalies:**  
  * Reference: Rohde, R.A., Hausfather, Z.: The Berkeley Earth land/ocean temperature record. Earth System Science Data 12(4), 3469–3479 (2020) https://doi.org/10.5194/618essd-12-3469-2020619
  * url: https://berkeleyearth.org/data

### Methodology
* **Changepoint Detection on Surface Temperatures:**  
  * Global: Beaulieu, C., Gallagher, C., Killick, R., Lund, R., Shi, X.: A recent surge in global warming is not detectable yet. Communications Earth & Environment 5(1), 576374 (2024) https://doi.org/10.1038/s43247-024-01711-1
  * Regional: Beaulieu, C., Johnson, A., Killick, R., Lanzante, J. & Knutson, T. Space-time signature of surface warming accelerations since 1970. Nature Communications, accepted. (2026)
  
## License

Distributed under the MIT License. See LICENSE for more information.


## Credits:

Contributors to the development of this dashboard include Courtney Stratton, Kim Porras, Nicholas Chavez, Dongran Zhai and Joelle Yang.


Please contact Claudie Beaulieu (beaulieu@ucsc.edu) for comments, suggestions, etc.
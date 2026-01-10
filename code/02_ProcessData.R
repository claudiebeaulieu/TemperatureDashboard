################################################################################
# Temperature Monitoring Dashboard
################################################################################
# Description: Interactive Shiny dashboard for exploring surface temperature 
#              trends with changepoint detection analysis
# Data Source: Berkeley Earth Surface Temperature 
################################################################################


# Script that goes through the Berkeley gridded dataset and analyze
# for the presence of changes in the rate of warming. 

year = seq(1970,2024)

load('./data/annual_Berkeley_anom.RData') #BIC penalty
data = tas_annual[,,which(time == 1970):which(time == 2024)]#we extract the data over the 1970-2024 period
results = st.cpts(data,lon,lat,year,"BIC")
save(file='./results/ResultsBerkeley.RData',results)

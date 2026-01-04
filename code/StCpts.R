# Function to go through surface temperature gridded dataset
# and analyze every grid cell through a continuous AR1 model

st.cpts=function(data,lon,lat,year,penalty){
  #data is the gridded surface temperature dataset, an array organized by lon, lat and year
  
  #initialise results arrays
  n = length(year)
  ncpts = array(data=NA,c(length(lon),length(lat)))
  ycpts = array(data=NA,c(length(lon),length(lat),3))
  fittrend = array(data=NA,c(length(lon),length(lat),n))
  fittrendAR = array(data=NA,c(length(lon),length(lat),n))
  dift = array(data=NA,c(length(lon),length(lat)))
  difficulty = array(data=NA,c(length(lon),length(lat)))
  NAs = array(data=0,c(length(lon),length(lat)))#0/1, 0 indicate too many NAs to analyze this grid
  results = list()
  
  if(penalty == "BIC"){
    pen.value = 4*log(n)
  }else{
    pen.value = penalty
  }
  
  # loop through longitude and latitude
  for(i in 1:length(lon)){
    print(i)
    for(j in 1:length(lat)){
      print(j)
      tmp = data[i,j,]#extract anomaly at a given grid cell
      if(sum(is.na(tmp)) == 0 && sum(tmp == tmp[1]) <5){#only analyze grid cells with no NA and with less than 10% of repeated values
        NAs[i,j]=1
        cpt.trendARpJOIN = PELT.trendARpJOIN(tmp,p=1,pen=pen.value,minseglen=10)
        ncpts[i,j] = length(cpt.trendARpJOIN)
        fittrend_tmp = try({fit.trendARpJOIN(data=tmp,cpts=cpt.trendARpJOIN,p=1,dates=year,add.ar=F)},silent=T)# fit with no AR
        fittrendAR_tmp = try({fit.trendARpJOIN(data=tmp,cpts=cpt.trendARpJOIN,p=1,dates=year,add.ar=T)},silent=T)# fit including AR
        if(is.list(fittrend_tmp)==T){
          fittrend[i,j,] = fittrend_tmp$fit}
        if(is.list(fittrendAR_tmp)==T){
          fittrendAR[i,j,] = fittrendAR_tmp$fit}
        if(ncpts[i,j]>0){
          ycpts[i,j,1:length(cpt.trendARpJOIN)] = year[cpt.trendARpJOIN]
          cpt.difficulty = cpt_difficulty(tmp,cpt.trendARpJOIN, fittrend_tmp$coeffs)
          difficulty[i,j] = cpt.difficulty[length(cpt.difficulty)]
          dift[i,j] = cpt.difficulty[2]-cpt.difficulty[1] 
        }
      }
    }
  }
  results = list(ncpts, ycpts, fittrend, fittrendAR, dift, difficulty,NAs)
  names(results)=c("ncpts","ycpts","fittrend","fittrendAR","dift","difficulty","NAs")
  return(results)
}
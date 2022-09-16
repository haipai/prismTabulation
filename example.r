
  prismfold <- file.path('r:/prism/daily')  # the fold I saved downloaded Daily PRISM raster zip files. 
  wvars     <- c('ppt')  # only 'ppt', if you downloaded other variables from PRISM, you can add other variables like 'tmax', 'tmin' et al. 
  spatialid <- 'huc12'  # since I use huc12_prism, the id is 'huc12', 'huc8' for huc8_prism and 'geoid' for county files 
  interfile <- file.path('d:/git/prismTabulation/data/','huc12_prism.csv')  # point to the huc12_prism.csv you downloaded from this repository 
  filterfile<- file.path('d:/git/prismTabulation/data/','prism_nlcd2001.csv') # point to one of the filter csv file you downloaded from this repository 
  timespan  <- c(2020:2020) # the whole year of 2020 
  
  

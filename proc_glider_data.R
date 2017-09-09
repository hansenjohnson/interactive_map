# proc_glider_data
# read in glider tracklines from OTN kml file, and detections from dcs.whoi.edu, and process them for use in a shiny interactive map

# user input --------------------------------------------------------------

# name of output file with processed glider data
glider_data_file = 'glider_data.rda'

# define processing functions ---------------------------------------------

proc_glider_detections = function(manual_analysis_file){
  
  # message('Processing glider detection file: ', manual_analysis_file)
  # s = proc.time()
  
  # read in data
  detections = read.csv(manual_analysis_file)
  
  # subset to only include right whales
  detections = subset(detections, detections$right!='absent')
  detections = droplevels(detections)
  
  # remove unneeded columns
  detections$analyst = NULL
  detections$notes = NULL
  detections$sei = NULL
  detections$fin = NULL
  detections$humpback = NULL
  
  # fix time
  detections$datetime_utc = as.character(detections$datetime_utc)
  detections$time = as.POSIXct(detections$datetime_utc,format = '%Y%m%d%H%M%S',tz = 'UTC')
  detections$date = as.Date(detections$time)
  
  # message('Complete! Time elapsed = ', round((proc.time()-s)[3],2), 's')
  
  return(detections)
}

proc_glider_kml = function(glider_file){
  library(rgdal, quietly = T,warn.conflicts = F,verbose = F)
  
  # message('Processing glider file: ', glider_file)
  # s = proc.time()
  
  # list layers of kml
  lyrs = ogrListLayers(glider_file)
  
  # extract glider surfacings
  surf = readOGR(glider_file, layer = lyrs[grep('Surfacings', lyrs)], verbose = F)
  
  # re-arrange in data frame
  glider = cbind.data.frame(surf@coords[,c(2,1)], as.character(surf$Name))
  colnames(glider) = c('lat', 'lon', 'time')
  glider$time = as.character(glider$time)
  
  # convert timestamp of latest surfacing
  glider$time[nrow(glider)] = strsplit(x = as.character(glider$time[nrow(glider)]), split = '[()]')[[1]][2]
  
  # fix date
  glider$time = as.POSIXct(glider$time, format = '%m-%d %H:%M')
  glider$date = as.Date(glider$time)
  
  # message('Complete! Time elapsed = ', round((proc.time()-s)[3],2), 's')
  
  # return(list(glider=glider,latest=latest))
  return(glider)
}

# process and save glider tracks -----------------------------------------

# list files to include
glider_kml_list = dir(path = dir(pattern = 'data_', full.names = T), pattern="\\.kml$", full.names = T)

# loop through glider file list and process all the files
glider = list()
for(i in seq_along(glider_kml_list)){
  tmp = glider_kml_list[i]
  gld = proc_glider_kml(tmp)
  NArow = rep(NA, ncol(gld))
  glider[[i]] = rbind.data.frame(gld,NArow)
}

# combine output into a single data frame
glider = do.call(rbind, glider)

# process and save glider detections --------------------------------------------

# list files to include
glider_detects_list = dir(path = dir(pattern = 'data_', full.names = T), pattern="\\manual_analysis.csv$", full.names = T)

# loop through glider file list and process all the files
detections = list()
for(i in seq_along(glider_detects_list)){
  detections[[i]] = proc_glider_detections(glider_detects_list[i])
}

# combine output into a single data frame
detections = do.call(rbind, detections)

# subset
detected = subset(detections, detections$right == 'present')
possible = subset(detections, detections$right == 'maybe')

# save glider data --------------------------------------------------------
save(glider, detections, detected, possible, file = glider_data_file)
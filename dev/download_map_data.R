#### offline helper ####
# load in data if the computer is offline (useful for offshore plotting)

# useful libraries
library(curl)

# user input --------------------------------------------------------------

download_map_data = function(
  glider_detections_file = 'Summer2017_NARWGliderDetections', 
  sightings_file = 'Summer2017_NARWSightings', 
  sonobuoy_file = 'Summer2017_Sonobuoys',
  noaa_track_dir = 'gps_files/',
  begin_date = as.Date('2017-06-01'),
  map_data_fname = ''){
  
  # define functions --------------------------------------------------------
  
  load_data_gsheets <- function(TABLE_NAME) {
    TABLE_NAME %>% gs_title %>% gs_read_csv
  }
  
  clean_latlon = function(d){
    d$lat = gsub(",","",d$lat)
    d$lat = d$lat = gsub("^\\s","",d$lat)
    d$lat = as.numeric(d$lat)
    
    d$lon = gsub(",","",d$lon)
    d$lon = d$lon = gsub("^\\s","",d$lon)
    d$lon = as.numeric(d$lon)
    
    d$lon[which(d$lon>0)] = -d$lon[which(d$lon>0)]
    
    return(d)
  }
  
  proc_glider_kml = function(glider, download = T){
    message('Downloading and processing tracklines for ', glider)
    
    s = proc.time()
    
    glider_file = paste0('./', glider, '.kml')
    glider_url = paste0('http://gliders.oceantrack.org/ge/', glider, '.kml')
    
    if(download){
      download.file(url = glider_url, destfile = glider_file, quiet = T)
      message('File saved as: ', glider_file)
    }
    
    # glider surfacings
    surf = readOGR(glider_file, layer = paste0(glider, ' Surfacings'), verbose = F)
    glider = cbind.data.frame(surf@coords[,c(2,1)], as.character(surf$Name))
    colnames(glider) = c('lat', 'lon', 'time')
    glider$time = as.character(glider$time)
    
    # convert timestamp of latest surfacing
    glider$time[nrow(glider)] = strsplit(x = as.character(glider$time[nrow(glider)]), split = '[()]')[[1]][2]
    
    # latest = glider[nrow(glider),] # latest surfacing
    glider = glider[1:nrow(glider),] # all surfacings
    
    # fix date
    glider$time = as.POSIXct(glider$time, format = '%m-%d %H:%M')
    glider$date = as.Date(glider$time)
    
    message('Complete! Time elapsed = ', (proc.time()-s)[3])
    
    # return(list(glider=glider,latest=latest))
    return(glider)
  }
  
  message('Downloading and saving map data...')
  
  # read in NOAA tracklines -------------------------------------------------
  
  load('noaa_tracks.rda')
  
  # read in shelagh tracklines ----------------------------------------------
  
  load('shelagh_tracks.rda')
  
  # sightings data ----------------------------------------------------------
  sightings = load_data_gsheets(sightings_file)
  
  colnames(sightings) = c('date', 'time', 'lat', 'lon', 'number', 'platform', 'photos', 'notes')
  
  # clean lat lon
  sightings = clean_latlon(sightings)
  
  # convert to date
  sightings$date = as.Date(sightings$date, "%m/%d/%Y")
  
  # glider detections -------------------------------------------------------
  detections = load_data_gsheets(glider_detections_file)
  
  colnames(detections) = c('date', 'time','score', 'lat', 'lon', 'notes', 'platform', 'name')
  
  # clean lat lon
  detections = clean_latlon(detections)
  
  # fix date
  detections$date = as.Date(detections$date, format = '%m/%d/%Y')
  
  # subset
  detected = subset(detections, detections$score == 'Detected')
  possible = subset(detections, detections$score == 'Possibly detected')
  
  # sonobuoy data -----------------------------------------------------------
  sono = load_data_gsheets(sonobuoy_file)
  colnames(sono) = c('date', 'lat', 'lon')
  
  # clean lat lon
  sono = clean_latlon(sono)
  
  # fix date
  sono$date = as.Date(sono$date, format = '%m/%d/%Y')
  
  # glider data ----------------------------------------------------------
  
  bond = proc_glider_kml('bond')
  dal556 = proc_glider_kml('dal556')
  otn200 = proc_glider_kml('otn200')
  NArow = rep(NA, ncol(dal556))
  
  glider = rbind(bond, NArow, dal556, NArow, otn200)
  
  # save data ---------------------------------------------------------------  
  
  save(list = c('sightings', 'detected', 'possible', 'sono', 'glider', 'noaa_track'), file = map_data_fname)
  
  message('Map data saved as: ', map_data_fname)
  
}




#### offline helper ####
# load in data if the computer is offline (useful for offshore plotting)

# useful libraries
library(curl)

# user input --------------------------------------------------------------

get_map_data = function(
  glider_detections_file = 'Summer2017_NARWGliderDetections', 
  sightings_file = 'Summer2017_NARWSightings', 
  sonobuoy_file = 'Summer2017_Sonobuoys',
  noaa_track_dir = 'gps_files/',
  begin_date = as.Date('2017-06-01'),
  map_data_fname = '2017-08-06_map_data.rda'){
  
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
    
    # latest = glider[nrow(glider),] # latest surfacing
    glider = glider[1:nrow(glider)-1,] # all other surfacings
    
    glider$time = as.POSIXct(glider$time, format = '%m-%d %H:%M')
    glider$date = as.Date(glider$time)
    
    message('Complete! Time elapsed = ', (proc.time()-s)[3])
    
    # return(list(glider=glider,latest=latest))
    return(glider)
  }
  
  # read in NOAA tracklines -------------------------------------------------
  
  noaa_track_list = list.files(noaa_track_dir)
  noaa_track = data.frame()
  
  for(i in seq_along(noaa_track_list)){
    tmp = read.table(paste0(noaa_track_dir, '/', noaa_track_list[i]), sep = ',')
    NArow = rep(NA, ncol(tmp))
    tmp = rbind(tmp, NArow)
    noaa_track = rbind(tmp, noaa_track) 
  }
  
  colnames(noaa_track) = c('time', 'lat', 'lon', 'unk1', 'unk2', 'unk3', 'unk4')
  noaa_track$time = as.POSIXct(noaa_track$time, format = '%d/%m/%Y %H:%M:%S')
  noaa_track$date = as.Date(noaa_track$time)
  
  # test internet -----------------------------------------------------------
  
  has_internet = has_internet()
  
  if(has_internet){
    message('Internet connection detected. Downloading and saving map data...')
    
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
    
    save(list = c('sightings', 'detected', 'possible', 'sono', 'glider'), file = map_data_fname)
    
    message('Map data saved as: ', map_data_fname)
    
  } else {
    
    # load data ---------------------------------------------------------------  
    
    message('No internet connection detection. Loading map data from: ', map_data_fname)
    
    load(map_data_fname)
  }
}




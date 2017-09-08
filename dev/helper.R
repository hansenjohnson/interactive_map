library(googlesheets)

# user input --------------------------------------------------------------

# glider detections
glider_detections_file = 'Summer2017_NARWGliderDetections.xlsx'

# sightings data
sightings_file = 'Summer2017_NARWSightings_updatedJuly312017.xlsx'

# sonobuoy data
sonobuoy_file = 'Summer2017_Sonobuoys.xlsx'

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

# sightings data ----------------------------------------------------------

sightings = load_data_gsheets(sightings_file)

colnames(sightings) = c('date', 'time', 'lat', 'lon', 'number', 'platform', 'photos', 'notes')

# clean lat lon
sightings = clean_latlon(sightings)

# convert to date
sightings$date = as.Date(sightings$date, "%m/%d/%Y")

# glider detections -------------------------------------------------------
detections = load_data_gsheets(glider_detections_file)

colnames(detections) = c('date', 'time', 'score', 'lat', 'lon', 'notes', 'platform')

# clean lat lon
detections = clean_latlon(detections)

# fix time and date
detections$time = as.POSIXct(paste(detections$date, detections$time, sep = ' '), format = '%m/%d/%y %H:%M:%S')
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

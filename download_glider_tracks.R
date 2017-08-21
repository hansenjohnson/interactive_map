# download and process data from ongoing (or recent) glider deployments

# setup -------------------------------------------------------------------

# useful libraries
library(curl)
library(rgdal)

# user input --------------------------------------------------------------

# name of output file with processed glider data
glider_track_file = 'glider_tracks.rda'

# define kml processing function ------------------------------------------

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

# process and save glider data --------------------------------------------

# process each deployment
bond = proc_glider_kml('bond')
dal556 = proc_glider_kml('dal556')
otn200 = proc_glider_kml('otn200')

# define a row of NAs to separate deployments
NArow = rep(NA, ncol(dal556))

# combine all deployments
glider = rbind(bond, NArow, dal556, NArow, otn200)

# save for use in the application
save(glider, file = glider_track_file)
message('Glider tracks saved as: ', glider_track_file)

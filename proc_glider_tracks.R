# process data from ongoing (or recent) glider deployments

# user input --------------------------------------------------------------

# name of output file with processed glider data
# !!! NOTE - this must include the full path WITHOUT symlinks !!!
glider_track_file = '/srv/shiny-server/whale_map/glider_tracks.rda' 

# define kml processing function ------------------------------------------

proc_glider_kml = function(glider_file){
  library(rgdal)
  
  message('Processing glider file: ', glider_file)
  s = proc.time()
  
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
  
  message('Complete! Time elapsed = ', round((proc.time()-s)[3],2), 's')
  
  # return(list(glider=glider,latest=latest))
  return(glider)
}

# process and save glider data --------------------------------------------

# list files to include
glider_file_list = list.files(pattern = '*_tracks.kml')

# loop through glider file list and process all the files
glider = list()
for(i in seq_along(glider_file_list)){
  tmp = glider_file_list[i]
  gld = proc_glider_kml(tmp)
  NArow = rep(NA, ncol(gld))
  glider[[i]] = rbind.data.frame(gld,NArow)
}

# combine output into a single data frame
glider = do.call(rbind, glider)

# save for use in the application
save(glider, file = glider_track_file)
message('Glider tracks combined and saved as: ', glider_track_file)

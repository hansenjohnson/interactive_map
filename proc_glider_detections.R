# process data from ongoing (or recent) glider deployments

# user input --------------------------------------------------------------

# name of output file with processed glider data
glider_detection_file = 'glider_detections.rda' 

# define processing function ----------------------------------------------

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

# process and save glider data --------------------------------------------

# list files to include
glider_file_list = list.files(pattern = '*_manual_analysis.csv')

# loop through glider file list and process all the files
detections = list()
for(i in seq_along(glider_file_list)){
  detections[[i]] = proc_glider_detections(glider_file_list[i])
}

# combine output into a single data frame
detections = do.call(rbind, detections)

# save for use in the application
save(detections, file = glider_detection_file)
# message('Glider tracks combined and saved as: ', glider_detection_file)

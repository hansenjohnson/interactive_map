# Search google drive for sightings and gps files
# build function to find and download files

get_gdrive = function(pattern, dir, download = T, ...){
  library(googledrive)
  library(RCurl)
  
  # find files
  message('Searching for files containing: ', pattern)
  files = drive_find(pattern)
  
  # remove duplicates
  files = files[which(!duplicated(files$name)),]
  
  if(nrow(files) == 0){
    stop('No files meet your search criteria :(\nTry again...')
  }
  
  # print files to screen
  message('The following ', nrow(files), ' contained: ', pattern)
  print(files$name)
  
  # create ouput dir
  if(!dir.exists(dir)){
    message('Creating output directory: ', dir)
    dir.create(dir)
  }
  
  if(download){
    message('Downloading files...')
    # download all gps files
    for(i in 1:nrow(files)){
      drive_download(files[i,], path = paste0(dir, '/', files[i,]$name), overwrite = T, ...)
    }
  }
  message('File download complete! Files saved in: ', dir)
}

# find and save files -----------------------------------------------------

# find gps files
get_gdrive(pattern = '.gps', dir = 'gps_files/', download = T)

# # find sightings files
# get_gdrive(pattern = 'sig_17', dir = 'sightings_files', download = T)




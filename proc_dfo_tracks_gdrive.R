# Download .gpx tracks from shared google drive folder, then process them and save them for use in the app

# setup -------------------------------------------------------------------

library(googledrive, warn.conflicts = F, quietly = T, verbose = F)
library(plotKML, warn.conflicts = F, quietly = T, verbose = F)

# user input --------------------------------------------------------------

# name of google drive folder with tracklines
drive_dir_name = 'DFO_aerial_tracklines'

# name of data directory
local_dir = 'dfo_tracks'

# name output file
fout = 'dfo_tracks.rda'

# debug switch - turn on to make rough plots of tracks
debug = F

# setup -------------------------------------------------------------------

# create output directory if it doesn't exist already
if(!dir.exists(local_dir)){
  dir.create(local_dir)
}

# list data files in data dir
local_data_list = list.files(path = local_dir, pattern = '.gpx')

# # set up drive authorization (must be done manually)
# drive_auth = drive_auth()
# saveRDS(drive_auth, 'drive_auth.rds')

# authorize google drive
drive_auth('drive_auth.rds')

# download files ----------------------------------------------------------

# locate google drive file
drive_dir = drive_find(pattern = drive_dir_name, type = 'folder')

# list files on google drive
drive_data_list = drive_ls(drive_dir)

# loop through each file on the drive
for(i in 1:nrow(drive_data_list)){
  
  # isolate file info
  f = drive_data_list[i,]
  
  # download file if it doesn't exist locally
  c = 0
  if(!f$name %in% local_data_list){
    drive_download(f, path = paste0(local_dir, '/', f$name), verbose = F)  
    c = c+1
  }
}

# process tracks ----------------------------------------------------------

# proceed only if new files were downloaded, or data file does not exist
if(c > 0 | !file.exists(fout)){
  
  # prepare loop
  dfo_track_list = list.files(local_dir)
  dfo_track = data.frame()
  
  for(i in seq_along(dfo_track_list)){
    tmp = readGPX(paste0(local_dir, '/', dfo_track_list[i]))$tracks
    tmp = tmp[[1]]; tmp = tmp[[1]] # unsure why this needs to be run twice...
    tmp$ele = NULL
    if(debug){
      plot(tmp$lon,tmp$lat, type = 'l', main = paste0(dfo_track_list[i]))
    }
    
    NArow = rep(NA, ncol(tmp))
    tmp = rbind(tmp, NArow)
    dfo_track = rbind(tmp, dfo_track) 
  }
  
  # fix time and date
  dfo_track$time = as.POSIXct(dfo_track$time, format = '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
  dfo_track$date = as.Date(dfo_track$time)
  
  # plot all tracks together
  if(debug){
    plot(dfo_track$lon,dfo_track$lat, type = 'l', main = 'All tracks')
  }
  
  # error
  if(nrow(dfo_track) == 0){
    error('DFO trackline table is empty!!')
  }
  
  # save for use in the app
  save(dfo_track, file = fout)
}


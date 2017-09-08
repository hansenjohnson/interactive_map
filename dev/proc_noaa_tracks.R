# process NOAA tracklines

noaa_track_dir = 'gps_files/'
noaa_track_fout = 'noaa_tracks.rda'

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

save(noaa_track, file = noaa_track_fout)
message('NOAA tracklines saved as: ', noaa_track_fout)

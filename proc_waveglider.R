# process wave glider data

# telemetry ---------------------------------------------------------------

# read in data
wave = read.csv('data_dl/m76_DL-Telemetry.csv')

# drop unused columns
wave = wave[c(1,13,14)]

# rename columns
colnames(wave) = c('time', 'lat', 'lon')

# drop empty rows
wave = wave[complete.cases(wave),]

# convert time
wave$time = as.POSIXct(wave$time, tz = 'UTC')

# date
wave$date = as.Date(wave$time)

# test
plot(wave$lon, wave$lat, type = 'l')

# detections --------------------------------------------------------------

# (currently no detections...)

# save --------------------------------------------------------------------

save(wave, file ='waveglider_data.rda')



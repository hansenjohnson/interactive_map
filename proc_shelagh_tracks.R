# process shelagh trackline data

# output file name
shelagh_track_file = 'shelagh_tracks.rda'

# read in data ------------------------------------------------------------

trip1_file = '~/Projects/2017_shelagh_gsl/mysticetus/2017-07-10-CWI-V/2017-07-10-CWI-V.csv'
trip2_file = '~/Projects/2017_shelagh_gsl/mysticetus/2017-08-02-CWI-V/2017-08-02-CWI-V.csv'

trip1 = read.csv(trip1_file)
trip2 = read.csv(trip2_file)

shelagh = rbind.data.frame(trip1, trip2)

# correct timestamps ------------------------------------------------------

# convert time to character
shelagh$Time = as.character(shelagh$Time)

# find rows that need to be converted to each time zone
adt_ind = grep('ADT', x = shelagh$Time)
utc_ind = grep('UTC', x = shelagh$Time)

# create posix vector for new times
shelagh$time = rep(as.POSIXct('1970-01-01 00:00:00', tz = 'GMT'), nrow(shelagh))

# specify correct timezones for each timestamp
shelagh$time[utc_ind] = as.POSIXct(shelagh$Time[utc_ind], format = '%Y-%m-%d %H:%M:%S' ,tz = 'GMT')
shelagh$time[adt_ind] = as.POSIXct(shelagh$Time[adt_ind], tz = 'America/Halifax')

# create date column for use in the app
shelagh$date = as.Date(shelagh$time)

# # verify
# View(cbind.data.frame(shelagh$Time, shelagh$t))

# isolate tracks ----------------------------------------------------------
# # use this handy function to carry forward all previous observations (fill down)
# library(zoo)
# sh = na.locf(shelagh)

# identify start and end rows when 'on effort'
effort = cbind(which(shelagh$LEGSTAGE...ENVIRONMENTALS == 1),
which(shelagh$LEGSTAGE...ENVIRONMENTALS == 5))

# fill in leg stage info
for(i in 1:nrow(effort)){
  shelagh$LEGSTAGE...ENVIRONMENTALS[(effort[i,1]+1):(effort[i,2]-1)] = 2
}

# define NA row to separate lines
NArow = rep(NA, ncol(shelagh))

# combine all data within effort start and end points into single data frame
for(i in 1:nrow(effort)){
  if(i==1){
    e = shelagh[effort[i,1]:effort[i,2],]
    e = rbind.data.frame(e,NArow)
  }
  tmp = shelagh[effort[i,1]:effort[i,2],]
  tmp = rbind.data.frame(tmp,NArow)
  e = rbind.data.frame(e,tmp)
}

# clean up data
shelagh_track = cbind.data.frame(e$date, e$time, e$TrkLatitude, e$TrkLongitude)
colnames(shelagh_track) = c('date', 'time', 'lat', 'lon')

plot(shelagh_track$lon, shelagh_track$lat, col = 'blue', lty = 3, type='b', cex = 0.1)

# save for later use
save(shelagh_track, file = shelagh_track_file)

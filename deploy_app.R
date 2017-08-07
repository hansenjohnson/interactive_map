# deploy 2017 right whale sightings app

library(rsconnect)

rsconnect::deployApp(appDir = '~/Projects/interactive_map/', 
                     appFiles = c('app.R', 'noaa_tracks.rda'), 
                     appName = '2017_right_whale_map')
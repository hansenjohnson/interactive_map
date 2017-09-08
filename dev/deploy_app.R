# deploy 2017 right whale sightings app to shinyapps.io

library(rsconnect)

rsconnect::deployApp(appDir = '~/Projects/interactive_map/', 
                     appFiles = c('app.R', 'noaa_tracks.rda', 'shelagh_tracks.rda', 'gs_auth.rds'), 
                     appName = '2017_right_whale_map')
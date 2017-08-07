# deploy 2017 right whale sightings app

library(rsconnect)
rsconnect::deployApp('~/Projects/interactive_map/', appName = '2017_right_whale_map')

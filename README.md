# interactive_map
*Create an interactive map for visualizing right whale survey effort using R and Shiny*

## Goal(s)

I am a member of a large team of researchers working to monitor and mitigate risks to endangered whales in Atlantic Canada. We use a variety of assets to survey for these whales at different locations and times. I created this interactive mapping tool to help us:

1. all stay up to date on the various survey efforts in Atlantic Canada  

2. gain insights from the work we've done so far  

3. effectively plan future surveys this season and beyond  

## Approach / Overview

I wrote this application in R. It relies heavily on 'Shiny' for the dynamic components (i.e. date slider bar, etc), 'leaflet' for interactive mapping, and 'googlesheets' for convenient, shared data input. Ideally a data originator can enter their sighting, glider detection, or otherwise into a common google spreadsheet, then open the shiny application and have it update immediately.

Currently the app is live on my shinyapps.io account, but if it proves useful I hope to host it locally to improve performance and build in other capabilities.

## Description of Contents

* `app-offline.R` - a version of the app that runs without internet (useful for working offshore, or troubleshooting)
* `app-local.R` - the version of the app that's live on shinyapps.io  
* `app-server.R` - the version of the app that I'm currently working to host on a local server
* `get_glider_tracks.sh` - bash script that downloads the glider data and runs `proc_glider_tracks.R` (called by cron job)  
* `proc_glider_tracks.R` - processes all `*_track.kml` files on the server and saves them for use in the app
* `deploy_app.R` - deploy the app and necessary components to shinyapps.io
* `download_map_data.R` - download and save all data required for mapping for later use by `app_offline.R`
* `get_noaa_tracks.R` - search google drive folder for .gps files (from NOAA aerial surveys) and download
* `proc_noaa_tracks.R` - process (and save) NOAA aerial survey effort for use in the app
* `proc_shelagh_tracks.R` - process (and save) vessel survey effort from the R/V Shelagh for use in the app

NOTE - the data (e.g. sightings, tracklines, etc) plotted on the map are not included here. Please email me (hansen.johnson@dal.ca) if you require access to these data.

## Demonstration

The live application can currently be accessed [here](https://hansenjohnson.shinyapps.io/2017_right_whale_map/)

## Ongoing work

* Improve interface for mobile users  

* Figure out how to overlay isobaths (from ETOPO1 or other)  

* Host locally  

* Store and host map tiles locally so they can be accessed offline  

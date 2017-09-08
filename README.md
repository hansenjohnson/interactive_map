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

* `app.R` - the version of the app that is currently running on a local server here at Dal
* `get_glider_tracks.sh` - bash script that downloads the glider data and runs `proc_glider_tracks.R` (called by cron job)  
* `get_glider_detections.sh` - bash script that downloads the glider detections and runs `proc_glider_detections.R` (called by cron job)
* `proc_glider_tracks.R` - processes all `*_track.kml` files on the server and saves them for use in the app
* `proc_glider_detections.R` - processes all `*_manual_analysis` files on the server and saves them for use in the app
* `dev/` - directory with numerous scripts used in the development process

NOTE - the data (e.g. sightings, tracklines, etc) plotted on the map are not included here. Please email me (hansen.johnson@dal.ca) if you require access to these data.

## Demonstration

The live application can currently be accessed [here](http://leviathan.ocean.dal.ca/right_whale_map/)

## Ongoing work

* remove internal messages to reduce chron mail

* adjust wget settings to only download new data, but save as new filename (i.e. use both -O and -N options)

* add glider waypoint layer

* improve interface for mobile users  

* figure out how to overlay isobaths (from ETOPO1 or other)  

# interactive_map
*Create an interactive map for visualizing right whale survey effort using R and Shiny*

## Goal(s)

I am a member of a large team of researchers working to monitor and mitigate risks to endangered whales in Atlantic Canada. We use a variety of assets to survey for these whales at different locations and times. I created this interactive mapping tool to help us:

1. all stay up to date on the various survey efforts in Atlantic Canada  

2. gain insights from the work we've done so far  

3. effectively plan future surveys this season and beyond  

## Approach / Overview

I wrote this application in R. It relies heavily on 'Shiny' for the dynamic components (i.e. date slider bar, etc), 'leaflet' for interactive mapping, and 'googlesheets' for convenient, shared data input.

I have taken steps to keep the map's content up to date with as little effort as possible. Sightings data are read directly from a google spreadsheet shared with DFO and several other data originators. As soon as the spreadsheet is updated, the map updates as well. Glider tracklines and acoustic detections are updated hourly via server-side cron job. With planning, the same could be done for vessel and plane tracklines, but because these surveys are mostly concluded there's no need to keep them updated regularly.

## Description of Contents

* `app.R` - the version of the app that is currently running on a local server here at Dal
* `get_glider_data.sh` - bash script that downloads the glider data (both tracks and detections) and runs `proc_glider_data.R` (called by cron job)  
* `proc_glider_data.R` - processes and combines glider data on the server and saves them as `glider_data.rda` for use in the app
* `dev/` - directory with numerous scripts used in the development process

NOTE - the data (e.g. sightings, tracklines, etc) plotted on the map are not included here. Please email me (hansen.johnson@dal.ca) if you require access to these data.

## Demonstration

The live application can currently be accessed [here](http://leviathan.ocean.dal.ca/right_whale_map/)

## Ongoing work

* improve interface for mobile users  

* figure out how to overlay isobaths (from ETOPO1 or other)  

* scale size of markers to reflect group size  

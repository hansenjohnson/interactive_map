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

## Demonstration

The live application can currently be accessed [here](https://hansenjohnson.shinyapps.io/2017_right_whale_map/)


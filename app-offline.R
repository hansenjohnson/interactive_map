# Shiny application for visualizing right whale surveys

# setup -------------------------------------------------------------------

library(shiny)
library(leaflet)
library(rgdal)
library(mapview)
library(htmltools)
library(htmlwidgets)
library(maptools)
library(readxl)
library(googlesheets)
library(curl)
source('download_map_data.R')

# user input --------------------------------------------------------------

begin_date = as.Date('2017-06-01')
map_data_fname = '2017-08-07_map_data.rda'
force_load_data_from_file = T

# read in data ------------------------------------------------------------

has_internet = has_internet()

if(has_internet & !force_load_data_from_file){
  download_map_data(begin_date = begin_date, map_data_fname = map_data_fname)
  load(map_data_fname)
}else{
  load(map_data_fname)
}

# ui ----------------------------------------------------------------------
ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%;padding:0px;margin:0px}"),
  
  leafletOutput("map", width = "100%", height = "100%"),
  
  absolutePanel(top = 10, right = 50,fixed = F,
                h3(strong('2017 Right whale surveys'), align = 'center'),
                h6(strong(paste0('CAUTION: raw data! Updating automatically...')), 
                   br(),
                   'Suggestions or issues? Email: hansen.johnson@dal.ca', 
                   align = 'center'),
                
                sliderInput("range", "", begin_date, Sys.Date(),
                            value = c((Sys.Date() - 14),Sys.Date()), animate = T),
                tags$div(align = 'right', checkboxInput("legend", "Show legend", FALSE), 
                         checkboxInput("NOAA_charts", "NOAA charts", FALSE)))
)


# server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  # define groups -----------------------------------------------------------
  
  sightings_grp = paste0("Sightings [latest: ",
                         format(max(sightings$date), '%d-%b'),'; n = ', nrow(sightings),']')
  noaa_track_grp = paste0("NOAA plane tracks [latest: ",
                          format(max(noaa_track$date, na.rm = T), '%d-%b'),']')
  sono_grp = paste0("Sonobuoys [latest: ", 
                    format(max(sono$date, na.rm = T), '%d-%b'),'; n = ', nrow(sono),']')
  detected_grp = paste0("Definite glider detections [latest: ",
                        format(max(detected$date, na.rm = T), '%d-%b'),'; n = ', nrow(detected),']')
  possible_grp = paste0("Possible glider detections [latest: ",
                        format(max(possible$date, na.rm = T), '%d-%b'),'; n = ', nrow(possible),']')
  glider_track_grp = paste0("Glider tracks [latest: ", 
                            format(max(glider$date, na.rm = T), '%d-%b'),']')
  glider_surf_grp = paste0("Glider surfacings [latest: ", 
                           format(max(glider$date, na.rm = T), '%d-%b'),']')
  
  # reactive data -----------------------------------------------------------
  
  # Reactive expression for the data subsetted to what the user selected
  filteredSightings <- reactive({
    sightings[sightings$date >= input$range[1] & sightings$date <= input$range[2],]
  })
  
  filteredNoaaTrack <- reactive({
    noaa_track[noaa_track$date >= input$range[1] & noaa_track$date <= input$range[2],]
  })
  
  filteredGlider <- reactive({
    glider[glider$date >= input$range[1] & glider$date <= input$range[2],]
  })
  
  filteredDetected <- reactive({
    detected[detected$date >= input$range[1] & detected$date <= input$range[2],]
  })
  
  filteredPossible <- reactive({
    possible[possible$date >= input$range[1] & possible$date <= input$range[2],]
  })
  
  filteredSono <- reactive({
    sono[sono$date >= input$range[1] & sono$date <= input$range[2],]
  })
  
  # basemap -----------------------------------------------------------------
  
  output$map <- renderLeaflet({
    # Use leaflet() here, and only include aspects of the map that
    # won't need to change dynamically (at least, not unless the
    # entire map is being torn down and recreated).
    leaflet(sightings) %>% 
      addProviderTiles(providers$Esri.OceanBasemap) %>%
      addProviderTiles(providers$Hydda.RoadsAndLabels, group = 'Place names') %>%
      fitBounds(~max(lon, na.rm = T), ~min(lat, na.rm = T), ~max(lon, na.rm = T), ~max(lat, na.rm = T)) %>%
      
      # use NOAA graticules
      addWMSTiles(
        "http://maps.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer/",
        layers = c("1-degree grid", "5-degree grid"),
        options = WMSTileOptions(format = "image/png8", transparent = TRUE),
        attribution = "NOAA") %>%
      
      # add extra map features
      addMouseCoordinates(style = 'basic') %>%
      addScaleBar(position = 'bottomleft')%>%
      addMeasure(primaryLengthUnit = "kilometers",secondaryLengthUnit = 'miles', primaryAreaUnit =
                   "hectares",secondaryAreaUnit="acres", position = 'bottomleft') %>%
      
      # add layer control panel
      addLayersControl(
        overlayGroups = c('Place names',
                          sightings_grp, 
                          noaa_track_grp,
                          sono_grp, 
                          detected_grp, 
                          possible_grp,
                          glider_track_grp, 
                          glider_surf_grp),
        options = layersControlOptions(collapsed = TRUE), position = 'bottomright') %>%
      
      # hide some groups by default
      hideGroup(c('Place names', noaa_track_grp, glider_surf_grp, possible_grp, sono_grp))
  })
  
  # add NOAA chart ------------------------------------------------------------------
  
  observe({
    proxy <- leafletProxy("map")
    
    proxy %>% removeTiles(layerId = 'noaa')
    if (input$NOAA_charts) {
      proxy %>%
        addWMSTiles("https://seamlessrnc.nauticalcharts.noaa.gov/arcgis/services/RNC/NOAA_RNC/ImageServer/WMSServer",layers = 'NOAA_RNC',layerId = 'noaa', options = WMSTileOptions(format = "image/png", transparent = TRUE), attribution = "", group = 'NOAA Charts')
    }
  })
  
  # legend ------------------------------------------------------------------
  # Use a separate observer to recreate the legend as needed.
  observe({
    proxy <- leafletProxy("map")
    
    # Remove any existing legend, and only if the legend is
    # enabled, create a new one.
    proxy %>% clearControls()
    if (input$legend) {
      proxy %>%
        # add legend
        addLegend(position = 'bottomleft', title = 'Legend', 
                  colors = c('black', '#8B6914', 'green', 'red', 'yellow', 'blue', 'orange'), 
                  labels = c('Sightings', 'NOAA Tracklines',  'Sonobuoys', 'Definite glider detections', 'Possible glider detections', 'Glider track/surfacings', 'Glider waypoints'))
    }
  })
  
  # add map components ------------------------------------------------------  
  # use an observer to adjust values according to date slider input
  observe({
    leafletProxy("map") %>%
      clearMarkers() %>%
      clearShapes() %>%
      
      # add NOAA gps track
      addPolylines(data = filteredNoaaTrack(), ~lon, ~lat, weight = 2, color = '#8B6914', group = noaa_track_grp) %>%
      
      # add sightings
      addCircleMarkers(data = filteredSightings(), ~lon, ~lat, radius = 6, fillOpacity = .3, stroke = F, col = 'black',
                       popup = ~paste(sep = "<br/>",
                                      "NARW sighting",
                                      as.character(platform),
                                      as.character(date),
                                      paste0('Number: ', as.character(number)),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0(as.character(platform), ' sighting: ', as.character(date)), group = sightings_grp) %>%
      
      # add sonobuoys
      addCircleMarkers(data = filteredSono(), ~lon, ~lat, 
                       radius = 6, stroke = T, fillOpacity = 1, color = 'white', fillColor = 'green',
                       popup = ~paste(sep = "<br/>",
                                      "Sonobuoy deployed",
                                      as.character(date),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('Sonobuoy: ', as.character(date)), group = sono_grp) %>%
      
      # add possible glider detections
      addCircleMarkers(data = filteredPossible(), ~lon, ~lat, 
                       radius = 6, col = 'yellow', fillOpacity = 0.8, stroke = F,
                       popup = ~paste(sep = "<br/>",
                                      "Glider detection",
                                      paste0('Glider name: ', as.character(name)),
                                      "Score: Possible",
                                      as.character(date),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('Possible glider detection: ', as.character(date)), 
                       group = possible_grp) %>%
      
      # add definite glider detections
      addCircleMarkers(data = filteredDetected(), ~lon, ~lat, 
                       radius = 6, weight = 2, col = 'red', fillOpacity = 0.8, stroke = F,
                       popup = ~paste(sep = "<br/>",
                                      "Glider detection",
                                      paste0('Glider name: ', as.character(name)),
                                      "Score: Definite",
                                      as.character(date),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('Definite glider detection: ', as.character(date)), 
                       group = detected_grp) %>%
      
      # add glider track
      addPolylines(data = filteredGlider(), ~lon, ~lat, weight = 2, group = glider_track_grp) %>%
      
      # add glider surfacings
      addCircleMarkers(data = filteredGlider(), ~lon, ~lat, radius = 6, fillOpacity = .2, stroke = F,
                       popup = ~paste(sep = "<br/>",
                                      "Glider surfacing",
                                      as.character(time),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('Glider surfacing: ', as.character(time)), group = glider_surf_grp)
    
  })
}

# run app
shinyApp(ui, server)
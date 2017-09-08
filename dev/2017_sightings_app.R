library(shiny)
library(leaflet)
library(RColorBrewer)
library(mapview)
library(htmltools)
library(htmlwidgets)
library(maptools)

# user input --------------------------------------------------------------

sightings_file = 'sightings_master.csv'

# sightings data ----------------------------------------------------------

all = read.csv(sightings_file)

# change shelagh time
all$date = as.Date(all$date)

# create subset for generating points
dead = subset(all, all$live == 0)
sightings = subset(all, all$live == 1 | is.na(all$live))
shelagh = subset(sightings, sightings$platform == 'Shelagh')
noaa = subset(sightings, sightings$platform == 'NOAA Plane')
dfo = subset(sightings, sightings$platform == 'DFO Plane')

# glider track data -------------------------------------------------------

# specify paths to glider data
glider_url = 'http://gliders.oceantrack.org/ge/dal556.kml'
glider_file = 'dal556.kml'

# download glider data
# download.file(glider_url, destfile = glider_file)

# read and format glider data from kml
glider_layers = ogrListLayers(glider_file)
surf = readOGR(glider_file, layer = glider_layers[2])
glider = cbind.data.frame(surf@coords[,c(2,1)], as.character(surf$Name)); glider = glider[1:nrow(glider)-1,]
colnames(glider) = c('lat', 'lon', 'time')
glider$time = as.POSIXct(glider$time, format = '%m-%d %H:%M')
glider$date = as.Date(glider$time)

# glider detections -------------------------------------------------------

detections = read.delim('glider_detections.txt')
detections$time = as.POSIXct(detections$time, format = '%m/%d/%y %H:%M:%S')
detections$date = as.Date(detections$time)

detected = subset(detections, detections$occurence == 'Detected')
possible = subset(detections, detections$occurence == 'Possibly detected')

# make icons --------------------------------------------------------------

slocumIcon <- makeIcon(
  iconUrl = "slocum_clean.png",
  iconWidth = 70, iconHeight = 50,
  iconAnchorX = 35, iconAnchorY = 25)

# app ---------------------------------------------------------------------

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
                sliderInput("range", "Date", min(glider$date), max(glider$date),
                            value = c(min(glider$date),max(glider$date)), animate = T)))

server <- function(input, output, session) {
  
  # Reactive expression for the data subsetted to what the user selected
  filteredShelagh <- reactive({
    shelagh[shelagh$date >= input$range[1] & shelagh$date <= input$range[2],]
  })
  
  filteredNOAA <- reactive({
    noaa[noaa$date >= input$range[1] & noaa$date <= input$range[2],]
  })
  
  filteredDFO <- reactive({
    dfo[dfo$date >= input$range[1] & dfo$date <= input$range[2],]
  })
  
  filteredDEAD <- reactive({
    dead[dead$date >= input$range[1] & dead$date <= input$range[2],]
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
  
  output$map <- renderLeaflet({
    # Use leaflet() here, and only include aspects of the map that
    # won't need to change dynamically (at least, not unless the
    # entire map is being torn down and recreated).
    leaflet(all) %>% 
      addProviderTiles(providers$Esri.OceanBasemap) %>%
      addProviderTiles(providers$Hydda.RoadsAndLabels) %>%
      fitBounds(~min(lon), ~min(lat), ~max(lon), ~max(lat)) %>%
      
      # add extra map features
      addMouseCoordinates(style = 'basic') %>%
      addScaleBar(position = 'bottomleft')%>%
      addMeasure(primaryLengthUnit = "kilometers",secondaryLengthUnit = 'miles', primaryAreaUnit =
                   "hectares",secondaryAreaUnit="acres", position = 'bottomleft') %>%
    
    addLayersControl(
      overlayGroups = c("NOAA plane sightings", "DFO plane sightings", 'Shelagh sightings', 'Dead whales', 'Glider track', 'Glider surfacings', 'Definite glider detections', 'Possible glider detections'), 
      options = layersControlOptions(collapsed = FALSE), position = 'bottomright') %>%
    
    hideGroup(c('Dead whales','Glider surfacings', 'Possible glider detections'))
  })
    
    # Incremental changes to the map (in this case, replacing the
    # circles when a new color is chosen) should be performed in
    # an observer. Each independent set of things that can change
    # should be managed in its own observer.
  observe({
    leafletProxy("map") %>%
      clearMarkers() %>%
      clearShapes() %>%
      
    # add shelagh sightings
    addCircleMarkers(data = filteredShelagh(), ~lon, ~lat, radius = 6, fillOpacity = .3, stroke = F, col = 'black',
                     popup = ~paste(sep = "<br/>",
                                    "Shelagh sighting",
                                    as.character(date),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Shelagh: ', as.character(date)), group = 'Shelagh sightings') %>%
      
      # add noaa sightings
      addCircleMarkers(data = filteredNOAA(), ~lon, ~lat, radius = 6, fillOpacity = .3, stroke = F, col = 'black',
                       popup = ~paste(sep = "<br/>",
                                      "NOAA Plane sighting",
                                      as.character(date),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('NOAA Plane: ', as.character(date)), group = 'NOAA plane sightings') %>%
    
    # add dfo sightings
    addCircleMarkers(data = filteredDFO(), ~lon, ~lat, radius = 6, fillOpacity = .3, stroke = F, col = 'black',
                     popup = ~paste(sep = "<br/>",
                                    "DFO Plane sighting",
                                    as.character(date),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('DFO Plane: ', as.character(date)), group = 'DFO plane sightings') %>%
    
    # add dead sightings
    addCircleMarkers(data = filteredDEAD(), ~lon, ~lat, 
                     radius = 6, stroke = T, fillOpacity = 1, color = 'black', fillColor = 'white',
                     popup = ~paste(sep = "<br/>",
                                    "Dead whale sighting",
                                    as.character(date),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Dead whale: ', as.character(date)), group = 'Dead whales') %>%
    
    # add glider track
    addPolylines(data = filteredGlider(), ~lon, ~lat, weight = 2, group = 'Glider track') %>%
    
    # add glider surfacings
    addCircleMarkers(data = filteredGlider(), ~lon, ~lat, radius = 6, fillOpacity = .2, stroke = F,
                     popup = ~paste(sep = "<br/>",
                                    "Glider surfacing",
                                    as.character(time),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Glider surfacing: ', as.character(time)), group = 'Glider surfacings') %>%
    
    # add possible glider detections
    addCircleMarkers(data = filteredPossible(), ~lon, ~lat, 
                     radius = 6, col = 'yellow', fillOpacity = 0.8, stroke = F,
                     popup = ~paste(sep = "<br/>",
                                    "Glider detection",
                                    "Score: Possible",
                                    as.character(time),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Possible glider detection: ', as.character(time)), 
                     group = 'Possible glider detections') %>%
    
    # add definite glider detections
    addCircleMarkers(data = filteredDetected(), ~lon, ~lat, 
                     radius = 6, weight = 2, col = 'red', fillOpacity = 0.8, stroke = F,
                     popup = ~paste(sep = "<br/>",
                                    "Glider detection",
                                    "Score: Definite",
                                    as.character(time),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Definite glider detection: ', as.character(time)), 
                     group = 'Definite glider detections')
    
  })
}

shinyApp(ui, server)
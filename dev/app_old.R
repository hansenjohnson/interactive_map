library(shiny)
library(leaflet)
library(rgdal)
library(mapview)
library(htmltools)
library(htmlwidgets)
library(maptools)
library(gdata)
library(googledrive)

# user input --------------------------------------------------------------

# sightings data
sightings_file = 'sightings_master.xlsx'

# plane gps data
noaa_track_dir = 'gps_files/'

# specify paths to glider data
glider_url = 'http://gliders.oceantrack.org/ge/dal556.kml'
glider_file = './dal556.kml'

# sonobuoy data
sono_file = 'sonobuoy.txt'

# begin date
begin_date = as.Date('2017-06-03')

# last updated
last_update = as.Date('2017-07-30')

# sightings data ----------------------------------------------------------

all = read.xls(sightings_file)

# change shelagh time
all$date = as.Date(all$date)

# create subset for generating points
dead = subset(all, all$live == 0)
sightings = subset(all, all$live == 1 | is.na(all$live))
shelagh = subset(sightings, sightings$platform == 'Shelagh')
noaa = subset(sightings, sightings$platform == 'NOAA Plane')
dfo = subset(sightings, sightings$platform == 'DFO Plane')

# plane gps data ----------------------------------------------------------

noaa_track_list = list.files(noaa_track_dir)
noaa_track = data.frame()

for(i in seq_along(noaa_track_list)){
  tmp = read.table(paste0(noaa_track_dir, '/', noaa_track_list[i]), sep = ',')
  NArow = rep(NA, ncol(tmp))
  tmp = rbind(tmp, NArow)
  noaa_track = rbind(tmp, noaa_track) 
}

colnames(noaa_track) = c('time', 'lat', 'lon', 'unk1', 'unk2', 'unk3', 'unk4')
noaa_track$time = as.POSIXct(noaa_track$time, format = '%d/%m/%Y %H:%M:%S')
noaa_track$date = as.Date(noaa_track$time)

# glider track data -------------------------------------------------------

# download glider file
# download.file(url = glider_url, destfile = glider_file)

# read and format glider data from kml
glider_layers = ogrListLayers(glider_file)
surf = readOGR(glider_file, layer = glider_layers[2])
glider = cbind.data.frame(surf@coords[,c(2,1)], as.character(surf$Name)); glider = glider[1:nrow(glider)-1,]
colnames(glider) = c('lat', 'lon', 'time')
glider$time = as.POSIXct(glider$time, format = '%m-%d %H:%M')
glider$date = as.Date(glider$time)

glider_wpts = readOGR(glider_file, layer = glider_layers[1])

# glider detections -------------------------------------------------------

detections = read.delim('glider_detections.txt')
detections$time = as.POSIXct(detections$time, format = '%m/%d/%y %H:%M:%S')
detections$date = as.Date(detections$time)

detected = subset(detections, detections$occurence == 'Detected')
possible = subset(detections, detections$occurence == 'Possibly detected')

# sonobuoy data -----------------------------------------------------------

sono = read.delim(sono_file)
sono$date = as.Date(sono$date)

# app ---------------------------------------------------------------------

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%;padding:0px;margin:0px}"),
  
  leafletOutput("map", width = "100%", height = "100%"),
  
  absolutePanel(top = 10, right = 50,fixed = T,
                h3(strong('2017 Right whale surveys'), align = 'center'),
                h6(strong(paste0('CAUTION: raw data! Last updated: ', last_update)), 
                   br(),
                   'Suggestions or issues? Email: hansen.johnson@dal.ca', 
                   align = 'center'),
                
                sliderInput("range", "", begin_date, Sys.Date(),
                            value = c(begin_date,Sys.Date()), animate = T),
                tags$div(align = 'right', checkboxInput("legend", "Show legend", FALSE)))
)

server <- function(input, output, session) {

  # define groups -----------------------------------------------------------
  
  noaa_grp = paste0("NOAA plane sightings [latest: ",format(max(noaa$date), '%d-%b'),'; n = ', nrow(noaa),']')
  noaa_track_grp = paste0("NOAA plane tracklines [latest: ",format(max(noaa_track$date, na.rm = T), '%d-%b'),']')
  dfo_grp = paste0("DFO plane sightings [latest: ", format(max(dfo$date), '%d-%b'),'; n = ', nrow(dfo),']')
  shelagh_grp = paste0("Shelagh sightings [latest: ", format(max(shelagh$date), '%d-%b'),'; n = ', nrow(shelagh),']')
  dead_grp = paste0("Dead whales [latest: ", format(max(dead$date), '%d-%b'),'; n = ', nrow(dead),']')
  sono_grp = paste0("Sonobuoys [latest: ", format(max(sono$date), '%d-%b'),'; n = ', nrow(sono),']')
  detected_grp = paste0("Definite glider detections [latest: ",format(max(detected$date), '%d-%b'),'; n = ', nrow(detected),']')
  possible_grp = paste0("Possible glider detections [latest: ",format(max(possible$date), '%d-%b'),'; n = ', nrow(possible),']')
  glider_track_grp = paste0("Glider track [latest: ", format(max(glider$date), '%d-%b'),']')
  glider_surf_grp = paste0("Glider surfacings [latest: ", format(max(glider$date), '%d-%b'),']')
  glider_wpts_grp = 'Glider waypoints'
  
  # reactive data -----------------------------------------------------------
  
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
      
       # add layer control panel
    addLayersControl(
      overlayGroups = c(noaa_grp, 
                        dfo_grp, 
                        shelagh_grp,
                        noaa_track_grp,
                        dead_grp, 
                        sono_grp, 
                        detected_grp, 
                        possible_grp,
                        glider_track_grp, 
                        glider_surf_grp, 
                        glider_wpts_grp),
      options = layersControlOptions(collapsed = TRUE), position = 'bottomright') %>%
    
      # hide some groups by default
    hideGroup(c(noaa_track_grp, dead_grp, glider_surf_grp, possible_grp, glider_wpts_grp, sono_grp))
  })
    
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
                  colors = c('black', 'white', '#8B6914', 'green', 'red', 'yellow', 'blue', 'orange'), 
                  labels = c('Sightings', 'Dead whales', 'NOAA Tracklines',  'Sonobuoys', 'Definite glider detections', 'Possible glider detections', 'Glider track/surfacings', 'Glider waypoints'))
    }
  })
  
    # Incremental changes to the map (in this case, replacing the
    # circles when a new color is chosen) should be performed in
    # an observer. Each independent set of things that can change
    # should be managed in its own observer.
  observe({
    leafletProxy("map") %>%
      clearMarkers() %>%
      clearShapes() %>%
    
    # add NOAA gps track
    addPolylines(data = filteredNoaaTrack(), ~lon, ~lat, weight = 2, color = '#8B6914', group = noaa_track_grp) %>%
        
    # add shelagh sightings
    addCircleMarkers(data = filteredShelagh(), ~lon, ~lat, radius = 6, fillOpacity = .3, stroke = F, col = 'black',
                     popup = ~paste(sep = "<br/>",
                                    "Shelagh sighting",
                                    as.character(date),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Shelagh sighting: ', as.character(date)), group = shelagh_grp) %>%
      
      # add noaa sightings
      addCircleMarkers(data = filteredNOAA(), ~lon, ~lat, radius = 6, fillOpacity = .3, stroke = F, col = 'black',
                       popup = ~paste(sep = "<br/>",
                                      "NOAA Plane sighting",
                                      as.character(date),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('NOAA Plane sighting: ', as.character(date)), group = noaa_grp) %>%
    
    # add dfo sightings
    addCircleMarkers(data = filteredDFO(), ~lon, ~lat, radius = 6, fillOpacity = .3, stroke = F, col = 'black',
                     popup = ~paste(sep = "<br/>",
                                    "DFO Plane sighting",
                                    as.character(date),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('DFO Plane sighting: ', as.character(date)), group = dfo_grp) %>%
    
    # add dead sightings
    addCircleMarkers(data = filteredDEAD(), ~lon, ~lat, 
                     radius = 6, stroke = T, fillOpacity = 1, color = 'black', fillColor = 'white',
                     popup = ~paste(sep = "<br/>",
                                    "Dead whale sighting",
                                    as.character(date),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Dead whale sighting: ', as.character(date)), group = dead_grp) %>%
    
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
                                    "Score: Possible",
                                    as.character(time),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Possible glider detection: ', as.character(time)), 
                     group = possible_grp) %>%
    
    # add definite glider detections
    addCircleMarkers(data = filteredDetected(), ~lon, ~lat, 
                     radius = 6, weight = 2, col = 'red', fillOpacity = 0.8, stroke = F,
                     popup = ~paste(sep = "<br/>",
                                    "Glider detection",
                                    "Score: Definite",
                                    as.character(time),
                                    paste0(as.character(lat), ', ', as.character(lon))),
                     label = ~paste0('Definite glider detection: ', as.character(time)), 
                     group = detected_grp) %>%
    
      # add glider track
      addPolylines(data = filteredGlider(), ~lon, ~lat, weight = 2, group = glider_track_grp) %>%
      
      # add glider surfacings
      addCircleMarkers(data = filteredGlider(), ~lon, ~lat, radius = 6, fillOpacity = .2, stroke = F,
                       popup = ~paste(sep = "<br/>",
                                      "Glider surfacing",
                                      as.character(time),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('Glider surfacing: ', as.character(time)), group = glider_surf_grp) %>%
      
    # add glider wpts
    addCircleMarkers(data = glider_wpts,
                     label = ~paste0('Glider waypoint: ', as.character(Name)),
                     popup = ~paste0('Glider waypoint: ', as.character(Name)),
                     radius = 6, weight = 2, col = 'orange', fillOpacity = 0.8, stroke = F, 
                     group = glider_wpts_grp)
    
  })
}


shinyApp(ui, server)
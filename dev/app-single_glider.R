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

# user input --------------------------------------------------------------

# Google sheets
glider_detections_file = 'Summer2017_NARWGliderDetections'
sightings_file = 'Summer2017_NARWSightings'
sonobuoy_file = 'Summer2017_Sonobuoys'

# user info
# gs_auth = gs_auth()
# saveRDS(gs_auth, 'gs_auth.rds')

# plane gps data
noaa_track_dir = 'gps_files/'

# specify paths to glider data
glider_url = 'http://gliders.oceantrack.org/ge/dal556.kml'
glider_file = './dal556.kml'

# begin date
begin_date = as.Date('2017-06-01')

# read in static data -----------------------------------------------------

## NOAA tracklines ##

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

# define functions --------------------------------------------------------

load_data_gsheets <- function(TABLE_NAME) {
  TABLE_NAME %>% gs_title %>% gs_read_csv
}

clean_latlon = function(d){
  d$lat = gsub(",","",d$lat)
  d$lat = d$lat = gsub("^\\s","",d$lat)
  d$lat = as.numeric(d$lat)
  
  d$lon = gsub(",","",d$lon)
  d$lon = d$lon = gsub("^\\s","",d$lon)
  d$lon = as.numeric(d$lon)
  
  d$lon[which(d$lon>0)] = -d$lon[which(d$lon>0)]
  
  return(d)
}

# app ---------------------------------------------------------------------

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%;padding:0px;margin:0px}"),
  
  leafletOutput("map", width = "100%", height = "100%"),
  
  absolutePanel(top = 10, right = 50,fixed = T,
                h3(strong('2017 Right whale surveys'), align = 'center'),
                h6(strong(paste0('CAUTION: raw data! Updating automatically...')), 
                   br(),
                   'Suggestions or issues? Email: hansen.johnson@dal.ca', 
                   align = 'center'),
                
                sliderInput("range", "", begin_date, Sys.Date(),
                            value = c(begin_date,Sys.Date()), animate = T),
                tags$div(align = 'right', checkboxInput("legend", "Show legend", FALSE)))
)

server <- function(input, output, session) {
  
  # authorize google drive
  gs_auth(token = 'gs_auth.rds')
  
  # sightings data ----------------------------------------------------------
  
  sightings = load_data_gsheets(sightings_file)
  
  colnames(sightings) = c('date', 'time', 'lat', 'lon', 'number', 'platform', 'photos', 'notes')
  
  # clean lat lon
  sightings = clean_latlon(sightings)
  
  # convert to date
  sightings$date = as.Date(sightings$date, "%m/%d/%Y")
  
  # glider detections -------------------------------------------------------
  detections = load_data_gsheets(glider_detections_file)
  
  colnames(detections) = c('date', 'time','score', 'lat', 'lon', 'notes', 'platform')
  
  # clean lat lon
  detections = clean_latlon(detections)
  
  # fix date
  detections$date = as.Date(detections$date, format = '%m/%d/%Y')
  
  # subset
  detected = subset(detections, detections$score == 'Detected')
  possible = subset(detections, detections$score == 'Possibly detected')
  
  # sonobuoy data -----------------------------------------------------------
  sono = load_data_gsheets(sonobuoy_file)
  colnames(sono) = c('date', 'lat', 'lon')
  
  # clean lat lon
  sono = clean_latlon(sono)
  
  # fix date
  sono$date = as.Date(sono$date, format = '%m/%d/%Y')
  
  # glider data ----------------------------------------------------------
  
  # download glider file
  download.file(url = glider_url, destfile = glider_file)
  
  # read and format glider data from kml
  glider_layers = ogrListLayers(glider_file)
  surf = readOGR(glider_file, layer = glider_layers[2])
  glider = cbind.data.frame(surf@coords[,c(2,1)], as.character(surf$Name)); glider = glider[1:nrow(glider)-1,]
  colnames(glider) = c('lat', 'lon', 'time')
  glider$time = as.POSIXct(glider$time, format = '%m-%d %H:%M')
  glider$date = as.Date(glider$time)
  
  glider_wpts = readOGR(glider_file, layer = glider_layers[1])
  
  # define groups -----------------------------------------------------------
  
  sightings_grp = paste0("Sightings [latest: ",format(max(sightings$date), '%d-%b'),'; n = ', nrow(sightings),']')
  noaa_track_grp = paste0("NOAA plane tracklines [latest: ",format(max(noaa_track$date, na.rm = T), '%d-%b'),']')
  sono_grp = paste0("Sonobuoys [latest: ", format(max(sono$date), '%d-%b'),'; n = ', nrow(sono),']')
  detected_grp = paste0("Definite glider detections [latest: ",format(max(detected$date), '%d-%b'),'; n = ', nrow(detected),']')
  possible_grp = paste0("Possible glider detections [latest: ",format(max(possible$date), '%d-%b'),'; n = ', nrow(possible),']')
  glider_track_grp = paste0("Glider track [latest: ", format(max(glider$date), '%d-%b'),']')
  glider_surf_grp = paste0("Glider surfacings [latest: ", format(max(glider$date), '%d-%b'),']')
  glider_wpts_grp = 'Glider waypoints'
  
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
  
  output$map <- renderLeaflet({
    # Use leaflet() here, and only include aspects of the map that
    # won't need to change dynamically (at least, not unless the
    # entire map is being torn down and recreated).
    leaflet(sightings) %>% 
      addProviderTiles(providers$Esri.OceanBasemap) %>%
      # addProviderTiles(providers$Hydda.RoadsAndLabels) %>%
      fitBounds(~max(lon, na.rm = T), ~min(lat, na.rm = T), ~max(lon, na.rm = T), ~max(lat, na.rm = T)) %>%
      
      # add extra map features
      addMouseCoordinates(style = 'basic') %>%
      addScaleBar(position = 'bottomleft')%>%
      addMeasure(primaryLengthUnit = "kilometers",secondaryLengthUnit = 'miles', primaryAreaUnit =
                   "hectares",secondaryAreaUnit="acres", position = 'bottomleft') %>%
      
       # add layer control panel
    addLayersControl(
      overlayGroups = c(sightings_grp, 
                        noaa_track_grp,
                        sono_grp, 
                        detected_grp, 
                        possible_grp,
                        glider_track_grp, 
                        glider_surf_grp, 
                        glider_wpts_grp),
      options = layersControlOptions(collapsed = TRUE), position = 'bottomright') %>%
    
      # hide some groups by default
    hideGroup(c(noaa_track_grp, glider_surf_grp, possible_grp, glider_wpts_grp, sono_grp))
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
                  colors = c('black', '#8B6914', 'green', 'red', 'yellow', 'blue', 'orange'), 
                  labels = c('Sightings', 'NOAA Tracklines',  'Sonobuoys', 'Definite glider detections', 'Possible glider detections', 'Glider track/surfacings', 'Glider waypoints'))
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
                       label = ~paste0('Glider surfacing: ', as.character(time)), group = glider_surf_grp) %>%
      
    # add glider wpts
    addCircleMarkers(data = glider_wpts,
                     label = ~paste0('Glider waypoint: ', as.character(Name)),
                     popup = ~paste0('Glider waypoint: ', as.character(Name)),
                     radius = 6, weight = 2, col = 'orange', fillOpacity = 0.8, stroke = F, 
                     group = glider_wpts_grp)
    
  })
}

# run app
shinyApp(ui, server)
# Shiny application for visualizing right whale surveys

# This is the version of the app that is hosted locally at our server at Dal. Note that it must be named 'app.R' to be deployed successfully...

# setup -------------------------------------------------------------------
message('Loading useful libraries')

library(shiny)
library(leaflet)
library(rgdal)
# library(mapview)
library(htmltools)
library(htmlwidgets)
library(maptools)
library(readxl)
library(googlesheets)

# user input --------------------------------------------------------------

# Google sheets
sightings_file = 'Summer2017_NARWSightings'

# # user info
# gs_auth = gs_auth()
# saveRDS(gs_auth, 'gs_auth.rds')

# glider data
glider_data_file = 'glider_data.rda'

# wave glider data
waveglider_data_file = 'waveglider_data.rda'

# plane gps data
noaa_track_file = 'noaa_tracks.rda'

# shelagh gps data
shelagh_track_file = 'shelagh_tracks.rda'

# sonobuoy positions
sonobuoy_file = 'sonobuoys.rda'

# begin date
begin_date = as.Date('2017-06-01')

# define functions --------------------------------------------------------

load_data_gsheets <- function(TABLE_NAME) {
  TABLE_NAME %>% gs_title(verbose = FALSE) %>% gs_read_csv(verbose = FALSE)
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

# read in NOAA tracklines -------------------------------------------------

load(noaa_track_file)

# read in shelagh tracklines ----------------------------------------------

load(shelagh_track_file)

# sonobuoy data -----------------------------------------------------------

load(sonobuoy_file)

# read in waveglider track ------------------------------------------------

load(waveglider_data_file)

# ui ----------------------------------------------------------------------

ui <- bootstrapPage(
  
  tags$style(type = "text/css", "html, body {width:100%;height:100%;padding:0px;margin:0px}"),
  
  leafletOutput("map", width = "100%", height = "100%"),
  
  absolutePanel(top = 10, right = 50,fixed = T, width='200px',
                h3(strong('2017 Right whale surveys'), align = 'center'),
                h6(strong(paste0('CAUTION: raw data! Updating automatically...')), 
                   br(),
                   'Suggestions or issues? Email: hansen.johnson@dal.ca', 
                   align = 'center'),
                
                sliderInput("range", "", begin_date, Sys.Date(),
                            value = c((Sys.Date() - 14),Sys.Date()), animate = T),
                tags$div(align = 'right', 
                         # checkboxInput("legend", "Show legend", FALSE), 
                         checkboxInput("NOAA_charts", "NOAA charts", FALSE)))
)


# server ------------------------------------------------------------------

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
  
  # glider data -------------------------------------------------------
  
  # load glider data file
  load(glider_data_file)
  
  # combine detections/sightings --------------------------------------------
  
  lat = c(detections$lat, sightings$lat)
  lon = c(detections$lon, sightings$lon)
  ALL = cbind.data.frame(lat,lon)
  
  # define groups -----------------------------------------------------------
  
  sightings_grp = paste0("Sightings (all vessel and aerial) [latest: ",
                         format(max(sightings$date), '%d-%b'),'; n = ', nrow(sightings),']')
  noaa_track_grp = paste0("NOAA plane effort [latest: ",
                          format(max(noaa_track$date, na.rm = T), '%d-%b'),']')
  shelagh_track_grp = paste0("Shelagh effort [latest: ",
                             format(max(shelagh_track$date, na.rm = T), '%d-%b'),']')
  sono_grp = paste0("Sonobuoys [latest: ", 
                    format(max(sono$date, na.rm = T), '%d-%b'),'; n = ', nrow(sono),']')
  detected_grp = paste0("Definite glider detections [latest: ",
                        format(max(detected$date, na.rm = T), '%d-%b'),'; n = ', nrow(detected),']')
  possible_grp = paste0("Possible glider detections [latest: ",
                        format(max(possible$date, na.rm = T), '%d-%b'),'; n = ', nrow(possible),']')
  glider_track_grp = paste0("Glider effort [latest: ", 
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
  
  filteredShelaghTrack <- reactive({
    shelagh_track[shelagh_track$date >= input$range[1] & shelagh_track$date <= input$range[2],]
  })
  
  filteredGlider <- reactive({
    glider[glider$date >= input$range[1] & glider$date <= input$range[2],]
  })
  
  filteredWave <- reactive({
    wave[wave$date >= input$range[1] & wave$date <= input$range[2],]
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
    leaflet(ALL) %>% 
      addProviderTiles(providers$Esri.OceanBasemap) %>%
      addProviderTiles(providers$Stamen.TonerLabels, group = 'Place names') %>%
      fitBounds(~max(lon, na.rm = T), ~min(lat, na.rm = T), ~min(lon, na.rm = T), ~max(lat, na.rm = T)) %>%
      
      # use NOAA graticules
      addWMSTiles(
        "https://maps.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer/",
        layers = c("1-degree grid", "5-degree grid"),
        options = WMSTileOptions(format = "image/png8", transparent = TRUE),
        attribution = "NOAA") %>%

      # add extra map features
      # addMouseCoordinates(style = 'basic') %>%
      addScaleBar(position = 'bottomleft')%>%
      addMeasure(primaryLengthUnit = "kilometers",secondaryLengthUnit = 'miles', primaryAreaUnit = "hectares",secondaryAreaUnit="acres", position = 'bottomleft') %>%
      
       # add layer control panel
    addLayersControl(
      overlayGroups = c('Place names',
                        sightings_grp, 
                        noaa_track_grp,
                        shelagh_track_grp,
                        sono_grp, 
                        detected_grp, 
                        possible_grp,
                        glider_track_grp, 
                        glider_surf_grp),
      options = layersControlOptions(collapsed = TRUE), position = 'bottomright') %>%
    
      # hide some groups by default
    hideGroup(c('Place names', noaa_track_grp, shelagh_track_grp, glider_surf_grp, possible_grp, sono_grp))
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
  # # Use a separate observer to recreate the legend as needed.
  # observe({
  #   proxy <- leafletProxy("map")
  #   
  #   # Remove any existing legend, and only if the legend is
  #   # enabled, create a new one.
  #   proxy %>% clearControls()
  #   if (input$legend) {
  #     proxy %>%
  #       # add legend
  #       addLegend(position = 'bottomleft', title = 'Legend', 
  #                 colors = c('black', '#8B6914', 'green', 'red', 'yellow', 'blue', 'orange'), 
  #                 labels = c('Sightings', 'NOAA Tracklines',  'Sonobuoys', 'Definite glider detections', 'Possible glider detections', 'Glider track/surfacings', 'Glider waypoints'))
  #   }
  # })
  
  # add map components ------------------------------------------------------  
  # use an observer to adjust values according to date slider input
  
  observe({
    leafletProxy("map") %>%
      clearMarkers() %>%
      clearShapes() %>%
      
      # add NOAA gps track
      addPolylines(data = filteredNoaaTrack(), ~lon, ~lat, weight = 2, color = '#8B6914', group = noaa_track_grp) %>%
      
      # add shelagh gps track
      addPolylines(data = filteredShelaghTrack(), ~lon, ~lat, weight = 2, color = '#2E2E2E', group = shelagh_track_grp) %>%
      
      # addCircleMarkers(data = filteredShelaghTrack(), ~lon, ~lat,
      #                  popup = ~paste(sep = "<br/>",
      #                                 "Shelagh position",
      #                                 paste0(as.character(time), ' UTC'),
      #                                 paste0(as.character(lat), ', ', as.character(lon))),
      #                  label = ~paste0('Shelagh track: ', as.character(time), ' UTC'),
      #                  radius = 2, fillOpacity = .3, stroke = F, color = 'green', group = shelagh_track_grp) %>%
      
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
                                      # paste0('Glider name: ', as.character(name)),
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
                                      # paste0('Glider name: ', as.character(name)),
                                      "Score: Definite",
                                      as.character(date),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('Definite glider detection: ', as.character(date)), 
                       group = detected_grp) %>%
      
      # add glider track
      addPolylines(data = filteredGlider(), ~lon, ~lat, weight = 2, group = glider_track_grp) %>%
      
      # add wave glider track
      addPolylines(data = filteredWave(), ~lon, ~lat, weight = 2, group = glider_track_grp) %>%
      
      # add glider surfacings
      addCircleMarkers(data = filteredGlider(), ~lon, ~lat, radius = 6, fillOpacity = .2, stroke = F,
                       popup = ~paste(sep = "<br/>",
                                      "Glider surfacing",
                                      as.character(time),
                                      paste0(as.character(lat), ', ', as.character(lon))),
                       label = ~paste0('Glider surfacing: ', as.character(time)), group = glider_surf_grp)
    
  })
}

# run app -----------------------------------------------------------------
shinyApp(ui, server)

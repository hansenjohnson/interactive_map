library(leaflet)
leaflet() %>% 
  addProviderTiles(providers$Esri.OceanBasemap) %>% 
  setView(-63.65, 40.0285, zoom = 8) %>%
  
#   addWMSTiles(
#   "http://maps.ngdc.noaa.gov/arcgis/services/graticule/MapServer/WMSServer/",
#   layers = c("1-degree grid", "5-degree grid", "10-degree grid"),
#   options = WMSTileOptions(format = "image/png8", transparent = TRUE),
#   attribution = "NOAA"
# ) %>%


  addSimpleGraticule(interval = 0.5, group = "Graticule") %>%
  addLayersControl(overlayGroups = c("Graticule"),
                   options = layersControlOptions(collapsed = FALSE))
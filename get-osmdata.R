library(osmdata)
library(dplyr)
library(purrr)
library(sf)
library(leaflet)

q <- opq(bbox = c(-113.9, 53.3, -113.0, 53.9))

available_features()

# land use ----
landuse_types <- available_tags("landuse")

landuse <- q |>
  add_osm_feature(key = "landuse") |>
  osmdata_sf()

pal <- colorFactor("viridis", domain = unique(landuse$landuse))

leaflet() |>
  addProviderTiles(providers$OpenStreetMap) |>
  addPolygons(data = landuse$osm_polygons, fillOpacity = 0.7, fillColor = ~ pal(landuse),
              popup = ~ paste(landuse)) |>
  fitBounds(lat1 = 53.354, lng1 = -113.418, lat2 = 53.349, lng2 = -113.410)

# buildings ----
building_types <- available_tags("building")

buildings <- q |>
  add_osm_feature(key = "building") |>
  osmdata_sf()

pal <- colorFactor("viridis", domain = unique(buildings$building))

leaflet() |>
  addProviderTiles(providers$OpenStreetMap) |>
  addPolygons(data = buildings$osm_polygons, fillOpacity = 0.7,
              fillColor = ~ pal(building), popup = ~ paste(building)) |>
  fitBounds(
    lat1 = 53.354584,
    lng1 = -113.418872,
    lat2 = 53.349873,
    lng2 = -113.410271
  )

# amenities
available_tags("amenity")

amenity <- q |>
  add_osm_feature(key = "amenity") |>
  osmdata_sf()

pal <- colorFactor("viridis", domain = unique(amenity$amenity))

leaflet() |>
  addProviderTiles(providers$OpenStreetMap) |>
  addPolygons(data = amenity$osm_polygons, fillOpacity = 0.7,
              fillColor = ~ pal(building), popup = ~ paste(amenity)) |>
  fitBounds(
    lat1 = 53.354584,
    lng1 = -113.418872,
    lat2 = 53.349873,
    lng2 = -113.410271
  )

library(osmdata)
library(dplyr)
library(purrr)
library(sf)
library(leaflet)

q <- opq(bbox = c(-113.9, 53.3, -113.0, 53.9))

available_features()

# land use data ----
landuse_types <- available_tags("landuse")

landuse_data <- map_dfr(
  landuse_types$Value,
  function(value) {
    df <- q |>
      add_osm_feature(key = "landuse", value = value) |>
      osmdata_sf()
    df$osm_polygons
  }, .id = "value"
)

pal <- colorFactor("viridis", domain = unique(landuse_data$landuse))

leaflet() |>
  addProviderTiles(providers$OpenStreetMap) |>
  addPolygons(data = landuse_data, fillOpacity = 0.7, fillColor = ~ pal(landuse),
              popup = ~ paste(landuse)) |>
  fitBounds(
    lat1 = 53.354584,
    lng1 = -113.418872,
    lat2 = 53.349873,
    lng2 = -113.410271
  )

# building types ----
building_types <- available_tags("building")

building_data <- map_dfr(
  building_types$Value,
  function(value) {
    df <- q |>
      add_osm_feature(key = "building", value = value) |>
      osmdata_sf()
    df$osm_polygons
  }
)

pal <- colorFactor("viridis", domain = unique(building_data$building))

leaflet() |>
  addProviderTiles(providers$OpenStreetMap) |>
  addPolygons(data = building_data, fillOpacity = 0.7, fillColor = ~ pal(building),
              popup = ~ paste(building)) |>
  fitBounds(
    lat1 = 53.354584,
    lng1 = -113.418872,
    lat2 = 53.349873,
    lng2 = -113.410271
  )

landuse_residential <- q |>
  add_osm_feature(key = "landuse", value = "residential") |>
  osmdata_sf()

landuse_commercial <- q |>
  add_osm_feature(key = "landuse", value = "commercial") |>
  osmdata_sf()

landuse_retail <- q |>
  add_osm_feature(key = "landuse", value = "retail") |>
  osmdata_sf()

landuse_religious <- q |>
  add_osm_feature(key = "landuse", value = "religious") |>
  osmdata_sf()

landuse_greenfield <- q |>
  add_osm_feature(key = "landuse", value = "greenfield") |>
  osmdata_sf()

landuse_social_fac <- q |>
  add_osm_feature(key = "landuse", value = "social_facility") |>
  osmdata_sf()

schools <- q |>
  add_osm_feature(key = "amenity", value = "school") |>
  osmdata_sf()

fire <- q |>
  add_osm_feature(key = "amenity", value = "fire_station") |>
  osmdata_sf()

parks <- q |>
  add_osm_feature(key = "leisure", value = "park") |>
  osmdata_sf()

res <- q |>
  add_osm_feature(key = "highway") |>
  osmdata_sf()

res <- q |>
  add_osm_feature(key = "building", value = "retail") |>
  osmdata_sf()

leaflet() |>
  addProviderTiles(providers$OpenStreetMap) |>
  addPolygons(data = landuse_residential$osm_polygons, fillColor = "blue", fillOpacity = 0.8) |>
  addPolygons(data = landuse_commercial$osm_polygons, fillColor = "red", fillOpacity = 0.8) |>
  addPolygons(data = landuse_retail$osm_polygons, fillColor = "green", fillOpacity = 0.8) |>
  addPolygons(data = parks$osm_polygons, fillColor = "yellow", fillOpacity = 0.8) |>
  addPolygons(data = landuse_greenfield$osm_polygons, fillColor = "yellow", fillOpacity = 0.8) |>
  addPolygons(data = schools$osm_polygons, fillColor = "black", fillOpacity = 0.8) |>
  addPolygons(data = landuse_religious$osm_polygons, fillColor = "purple", fillOpacity = 0.8) |>
  addPolygons(data = fire$osm_polygons, fillColor = "cyan", fillOpacity = 0.8) |>
  fitBounds(
    lat1 = 53.354584,
    lng1 = -113.418872,
    lat2 = 53.349873,
    lng2 = -113.410271
  )

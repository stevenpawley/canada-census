library(osmdata)
library(dplyr)
library(purrr)
library(sf)
library(leaflet)

q <- opq(bbox = c(-113.9, 53.3, -113.0, 53.9))

schema <- yaml::read_yaml("landcover-osm.yaml")

landcover_osm <- map(schema, function(type) {
  browser()
})

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

# specific landcover types ----
# open water
open_water1 <- q |>
  add_osm_feature(key = "landuse", value = c("reservoir", "basin")) |>
  osmdata_sf()

open_water2 <- q |>
  add_osm_feature(key = "natural", value = "water") |>
  osmdata_sf()

# ice
ice <- q |>
  add_osm_feature(key = "natural", value = "glacier") |>
  osmdata_sf()

# bare rock/soil
rock_soil1 <- q |>
  add_osm_feature(
    key = "natural",
    value = c("mud", "shingle", "beach", "sand", "scree", "bare_rock")
  ) |>
  osmdata_sf()

rock_soil2 <- q |>
  add_osm_feature(
    key = "landuse",
    value = c("quarry", "brownfield", "landfill")
  ) |>
  osmdata_sf()

# forest
forest <- q |>
  add_osm_feature(
    key = "landuse",
    value = "forest"
  ) |>
  osmdata_sf()

# scrub
shrubland <- q |>
  add_osm_feature(
    key = "natural",
    value = c("scrub", "heath")
  ) |>
  osmdata_sf()

# grassland
grassland1 <- q |>
  add_osm_feature(
    key = "natural",
    value = "grassland"
  ) |>
  osmdata_sf()

grassland2 <- q |>
  add_osm_feature(
    key = "landuse",
    value = "meadow"
  ) |>
  osmdata_sf()

# wetland
wetland <- q |>
  add_osm_feature(
    key = "natural",
    value = "wetland"
  ) |>
  osmdata_sf()

# developed open-space
developed_openspace <- q |>
  add_osm_feature(
    key = "landuse",
    value = c("recreation_ground", "village_green")
  ) |>
  osmdata_sf()

# developed low-medium intensity
developed_low <- q |>
  add_osm_feature(
    key = "landuse",
    value = "residential"
  ) |>
  osmdata_sf()

# developed construction
developed_const <- q |>
  add_osm_feature(
    key = "landuse",
    value = "construction"
  ) |>
  osmdata_sf()

# developed high intensity
developed_high1 <- q |>
  add_osm_feature(
    key = "landuse",
    value = c("commercial", "garages", "industrial", "railway", "retail")
  ) |>
  osmdata_sf()

developed_high2 <- q |>
  add_osm_feature(
    key = "amenity",
    value = c("parking", "motorcycle_parking", "bicycle_parking", "arts_centre",
              "bus_station", "college", "community_centre", "conference_centre",
              "courthouse", "fire_station", "hospital", "university")
  ) |>
  osmdata_sf()

# crops
crops1 <- q |>
  add_osm_feature(
    key = "landuse",
    value = c("farmland", "allotments", "orchard", "vineyard", "plant_nursery")
  ) |>
  osmdata_sf()

crops2 <- q |>
  add_osm_feature(
    key = "leisure",
    value = "garden"
  ) |>
  osmdata_sf()

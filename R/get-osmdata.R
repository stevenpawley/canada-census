library(osmdata)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(sf)
library(leaflet)

q <- opq(bbox = c(-113.9, 53.3, -113.0, 53.9))

schema <- read_csv("data/tables/osm-lulc.csv") |>
  drop_na(lulc)

osm <- list()

lulc_classes <- unique(schema$lulc)

for (lulc_class in lulc_classes) {
  keys <- schema |>
    filter(lulc == lulc_class) |>
    distinct(key) |>
    pluck("key")

  lulc_res <- list()

  for (k in keys) {
    values <- schema |>
      filter(lulc == lulc_class, key == k) |>
      distinct(value) |>
      pluck("value")

    data <- q |>
      add_osm_feature(key = k, value = values) |>
      osmdata_sf()
    data <- data$osm_polygons
    lulc_res[[k]] <- data
  }

  if (length(lulc_res) > 1) {
    lulc_res <- bind_rows(lulc_res)
  } else {
    lulc_res <- lulc_res[[1]]
  }
  osm[[lulc_class]] <- lulc_res
}

osm <- bind_rows(osm, .id = "lulc")
unique(osm$lulc)

osm |>
  filter(lulc == "urban_low") |>
  leaflet() |>
  addProviderTiles(providers$Esri.WorldImagery) |>
  addPolygons()

# buildings ----
building_types <- available_tags("building")

data <- q |>
  add_osm_feature(key = "building", value = "farm_auxiliary") |>
  osmdata_sf()
data <- data$osm_polygons

data[1,] |>
  leaflet() |>
  addProviderTiles(providers$Esri.WorldImagery) |>
  addPolygons()

buildings_lulc <- read_csv("data/raw/buildings.csv")
buildings_lulc <- drop_na(buildings_lulc, lulc)

buildings <- q |>
  add_osm_feature(key = "building", value = buildings_lulc$value) |>
  osmdata_sf()
data <- data$osm_polygons

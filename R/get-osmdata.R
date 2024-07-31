library(here)
library(osmdata)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(sf)
library(leaflet)

# q <- opq(bbox = c(-113.9, 53.3, -113.0, 53.9))
q <- opq(bbox = c(-113.466621, 53.321786, -113.367143, 53.373997))

schema <- read_csv(here("data/tables/osm-lulc.csv")) |>
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

osm |>
  filter(lulc == "urban_construction") |>
  leaflet() |>
  addProviderTiles(providers$Esri.WorldImagery) |>
  addPolygons()

dir.create(here("data/processed"), showWarnings = FALSE)
st_write(osm, here("data/processed/osm-lulc.gpkg"), delete_dsn = TRUE)

library(here)
library(osmdata)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(sf)
library(leaflet)

census <- st_read(here("data/processed/census-data.gpkg"))
bbox <- st_bbox(census)
q <- opq(bbox = bbox)

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

    lulc_res[[k]] <- data |>
      select(any_of(c("osm_id", "name", unique(schema$key))))
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
  filter(lulc == "forest") |>
  leaflet() |>
  addProviderTiles(providers$Esri.WorldImagery) |>
  addPolygons()

dir.create(here("data/processed"), showWarnings = FALSE)
st_write(osm, here("data/processed/osm-lulc.gpkg"), delete_dsn = TRUE)

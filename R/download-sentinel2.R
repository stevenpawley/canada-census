library(here)
library(glue)
library(terra)
library(sf)
library(rstac)
library(gdalcubes)
library(terra)
library(dplyr)
library(purrr)
library(ggplot2)

# setup ----
gdalcubes_options(parallel = TRUE)
planetary_computer <-
  stac("https://planetarycomputer.microsoft.com/api/stac/v1/")

census <- st_read(here("data/processed/census-data.gpkg"))
bbox <- st_bbox(census)

# retrieve items list ----
date_start <- "2021-06-10"
date_end <- "2021-09-10"
date_range <- paste(date_start, date_end, sep = "/")

items <- planetary_computer |>
  stac_search(
    collections = "sentinel-2-l2a",
    bbox = as.numeric(bbox),
    datetime = date_range,
    limit = 1000
  ) |>
  get_request() |>
  items_filter(properties$`eo:cloud_cover` < 30) |>
  items_sign(sign_fn = sign_planetary_computer())

print(paste("Number of products:", length(items$features)))

items_sf <- items_as_sf(items)

ggplot() +
  geom_sf(data = items_sf, aes(fill = `eo:cloud_cover`)) +
  scale_fill_distiller(palette = "Reds", direction = 1)

items |> items_assets()

# create imagery collection with selected assets
for (i in seq_len(items_length(items))) {
  item <- items_select(items, i)
  item <- items_sign(item, sign_planetary_computer())
  assets_download(item, output_dir = here("data/raw"))
}

files <- list.files(
  here("data/raw/sentinel2-l2/"),
  full.names = TRUE,
  recursive = FALSE,
  pattern = glob2rx("*.zip")
)
collection <- create_image_collection(
  files,
  format = "Sentinel2_L2A"
)

# create cube view (reference to object with defined spatiotemporal extent) ----
bbox_tm <- bbox |>
  st_as_sfc() |>
  st_transform(3400) |>
  st_bbox()

overview_ext <- as.list(bbox_tm) |>
  setNames(c("left", "bottom", "right", "top"))

overview_ext$t0 <- date_start
overview_ext$t1 <- date_end

cube_overview <- cube_view(
  srs = "EPSG:3400",
  dx = 500,
  dy = 500,
  dt = "P6M",
  aggregation = "median",
  resampling = "near",
  extent = overview_ext
)

# create raster cube from imagery collection
# cloud mask with all mid- to high-confidence cloud, cirrus and shadows
scl_mask <- image_mask("SCL", values = c(0, 3, 8, 9))

cube <- raster_cube(
  image_collection = collection,
  view = cube_overview,
  mask = scl_mask
) |>
  select_bands(c(paste0("B0", 2:8), "B11", "B12", "B8A"))

plot(cube, rgb = 4:2)

# create detailed cube ----
cube_detailed <- cube_view(
  srs = "EPSG:3400",
  dx = 10,
  dy = 10,
  dt = "P6M",
  aggregation = "median",
  resampling = "near",
  extent = overview_ext
)

cube <- raster_cube(
  image_collection = collection,
  view = cube_detailed,
  mask = scl_mask
) |>
  select_bands(c(paste0("B0", 2:8), "B11", "B12", "B8A"))

# regularize raster cube into regular temporal dimension
# (in this case, 1 time step that covers the range of all images)
cube_aggregated <- cube |>
  reduce_time(
    c(
      "median(B02)",
      "median(B03)",
      "median(B04)",
      "median(B05)",
      "median(B06)",
      "median(B07)",
      "median(B08)",
      "median(B8A)",
      "median(B11)",
      "median(B12)"
    )
  )

# write to file ----
localfile <- write_tif(
  cube_aggregated,
  dir = "data/processed",
  prefix = "sentinel",
  overviews = TRUE,
  COG = TRUE,
  rsmpl_overview = "nearest"
)

r <- rast(here("data/processed/sentinel2021-06-01.tif"))
plotRGB(stretch(r, minq = 0.02, maxq = 0.98), 4, 3, 2)

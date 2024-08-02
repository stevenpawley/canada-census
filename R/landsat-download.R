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
gdalcubes_options(parallel = TRUE, default_chunksize = c())
planetary_computer <-
  stac("https://planetarycomputer.microsoft.com/api/stac/v1/")

census <- st_read(here("data/processed/census-data.gpkg"))
bbox <- st_bbox(census)

# retrieve items list ----
date_start <- "2023-06-10"
date_end <- "2023-09-10"
date_range <- paste(date_start, date_end, sep = "/")

items <- planetary_computer |>
  stac_search(
    collections = "landsat-c2-l2",
    bbox = as.numeric(bbox),
    datetime = date_range,
    limit = 1000
  ) |>
  get_request() |>
  items_filter(
    properties$`eo:cloud_cover` < 30 &
      properties$platform %in% c("landsat-8", "landsat-9")
  ) |>
  items_sign(sign_fn = sign_planetary_computer())

print(paste("Number of products:", length(items$features)))

items_sf <- items_as_sf(items)

ggplot() +
  geom_sf(data = items_sf, aes(fill = `eo:cloud_cover`)) +
  scale_fill_distiller(palette = "Reds", direction = 1)

items |> items_assets()

# create imagery collection with selected assets
collection <- stac_image_collection(
  items$features,
  asset_names = c("blue", "green", "red", "nir08", "swir16",
                  "swir22", "qa_pixel")
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
cloud_mask <-
  image_mask(
    "qa_pixel",
    values = c(
      `fill` = 1,
      `Dilated cloud over land` = 21826,
      `Dilated cloud over water` = 21890,
      `High conf Cloud` = 22280,
      `High conf cloud shadow` = 23888,
      `Water with cloud shadow` = 23952,
      `Mid conf cloud with shadow` = 24088,
      `Mid conf cloud with shadow over water` = 24216,
      `High conf cloud with shadow` = 24344,
      `High conf cloud with shadow over water` = 24472,
      `High conf Cirrus` = 54596,
      `Cirrus, mid cloud` = 54852,
      `Cirrus, high cloud` = 55052,
      `Cirrus, mid conf cloud, shadow` = 56856,
      `Cirrus, mid conf cloud, shadow, over water` = 56984,
      `Cirrus, high conf cloud, shadow` = 57240
    )
  )

cube <- raster_cube(
  image_collection = collection,
  view = cube_overview,
  mask = cloud_mask
) |>
  select_bands(c(
    "blue",
    "green",
    "red",
    "nir08",
    "swir16",
    "swir22"
  ))

plot(cube, rgb = 3:1)

# create detailed cube ----
cube_detailed <- cube_view(
  srs = "EPSG:3400",
  dx = 30,
  dy = 30,
  dt = "P6M",
  aggregation = "median",
  resampling = "near",
  extent = overview_ext
)

cube <- raster_cube(
  image_collection = collection,
  view = cube_detailed,
  mask = cloud_mask
) |>
  select_bands(c(
    "blue",
    "green",
    "red",
    "nir08",
    "swir16",
    "swir22"
  ))

# regularize raster cube into regular temporal dimension
# (in this case, 1 time step that covers the range of all images)
cube_aggregated <- cube |>
  reduce_time(
    c(
      "median(blue)",
      "median(green)",
      "median(red)",
      "median(nir08)",
      "median(swir16)",
      "median(swir22)"
    )
  )

# write to file ----
localfile <- write_tif(
  cube_aggregated,
  dir = "data/processed",
  prefix = "landsat",
  overviews = TRUE,
  COG = TRUE,
  rsmpl_overview = "nearest"
)

r <- rast(here("data/processed/landsat2023-06-01.tif"))
plotRGB(stretch(r, minq = 0.02, maxq = 0.98), 4, 3, 2)

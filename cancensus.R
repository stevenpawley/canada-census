library(here)
library(dplyr)
library(readr)
library(stringr)
library(cancensus)
library(sf)
library(ggplot2)
library(leaflet)
library(leafgl)

# View available Census datasets
list_census_datasets()

# View available named regions at different levels of Census hierarchy
edmonton <- list_census_regions("CA1996") |>
  filter(name == "Edmonton", level == "CSD")

# To view available Census variables for the 2016 Census
list_census_vectors("CA21")

# Return data only
ca_datasets <- tribble(
  ~ dataset, ~ vectors,
  "CA21", "v_CA21_1",
  "CA16", "v_CA16_401",
  "CA11", "v_CA11F_1",
  "CA06", "v_CA06_1"
)

census_data <- mapply(
  function(dataset, vector) {
    get_census(
      dataset = dataset,
      regions = list(CMA = edmonton$CMA_UID),
      geo_format = "sf",
      vectors = vector,
      level = "DB"
    ) |>
      st_cast("POLYGON")
  },
  dataset = ca_datasets$dataset,
  vector = ca_datasets$vectors
)

census_data <- bind_rows(census_data, .id = "dataset")

census_data <- census_data |>
  mutate(
    year = str_extract(dataset, "\\d{2}"),
    year = paste0("20", year),
    year = as.integer(year)
  )

ggplot(census_data, aes(fill = Population)) +
  geom_sf() +
  facet_wrap(vars(year)) +
  scale_fill_manual(cptcity::cpt("grass_population"))

pal <- colorNumeric(
  palette = "viridis",
  domain = census_data_21$Population
)

leaflet() |>
  addProviderTiles(providers$OpenStreetMap) |>
  addGlPolygons(
    data = census_data_21,
    fillColor = ~ pal(Population),
    fillOpacity = 0.9,
    weight = 1,
    color = "white",
    popup = ~ paste("Population: ", Population, "<br>")
  )


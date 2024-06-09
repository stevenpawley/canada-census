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

# Return data only
ca_datasets <- tribble(
  ~ dataset, ~ vectors,
  "CA21", list_census_vectors("CA21") |>
    filter(label == "Population, 2021") |>
    pull(vector),
  "CA16", list_census_vectors("CA16") |>
    filter(label == "Population, 2016") |>
    pull(vector),
  "CA11", list_census_vectors("CA11") |>
    filter(label == "Population, 2011") |>
    pull(vector),
  "CA06", list_census_vectors("CA06") |>
    filter(label == "Population, 2006") |>
    pull(vector)
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
  geom_sf(linewidth = 0) +
  facet_wrap(vars(year)) +
  scale_fill_gradientn(colours = cptcity::cpt("grass_population"))

pal <- colorNumeric(
  palette = cptcity::cpt("grass_population"),
  domain = census_data$Population
)

leaflet() |>
  addProviderTiles(providers$OpenStreetMap) |>
  addGlPolygons(
    data = census_data |> filter(year == 2011),
    fillColor = ~ pal(Population),
    fillOpacity = 0.9,
    weight = 1,
    color = "white",
    popup = ~ paste("Population: ", Population, "<br>")
  )

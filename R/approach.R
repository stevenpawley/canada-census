library(tidyverse)
library(broom)
library(ranger)

pop <- tibble(
  pop = c(435, 230, 17, 15, 319),
  lc = c("red", "red", "pink", "pink", "yellow")
) |>
  mutate(lc = as.factor(lc))

parcels <- tribble(
  ~ n_red, ~ n_yellow, ~ n_pink,
  9, 0, 0,
  11, 1, 0,
  0, 1, 8,
  0, 0, 15,
  0, 9, 0
)

pop$area <- rowSums(parcels)

pop <- pop |>
  mutate(density = pop / area)

parcels <- parcels / rowSums(parcels)

data <- cbind(pop, parcels)
m <- ranger::ranger(density ~ n_red + n_yellow + n_pink, data, min.node.size = 1)

newdata_area <- 6
newdata = tibble(
  n_red = 1,
  n_yellow = 0,
  n_pink = 0
)

p <- predict(m, newdata)$predictions
p*newdata_area

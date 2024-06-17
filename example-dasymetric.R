# install the packages if necessary
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("patchwork")) install.packages("patchwork")
if (!require("sf")) install.packages("sf")
if (!require("raster")) install.packages("raster")
if (!require("biscale")) install.packages("biscale")
if (!require("sysfonts")) install.packages("sysfonts")
if (!require("showtext")) install.packages("showtext")

# packages
library(tidyverse)
library(sf)
library(readxl)
library(biscale)
library(patchwork)
library(raster)
library(sysfonts)
library(showtext)

# import data
# raster of CORINE LAND COVER 2018
urb <- raster("U2018_CLC2018_V2020_20u1.tif")

# income data and Gini index
renta <- read_excel("30824.xlsx")
gini <- read_excel("37677.xlsx")

# census boundaries
limits <- read_sf("SECC_CE_20200101.shp") 
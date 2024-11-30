import os
import yaml
import pandas as pd
import geopandas as gpd
from urllib.request import urlretrieve

# download files from https://download.geofabrik.de/
ab_url = "https://download.geofabrik.de/north-america/canada/alberta-latest-free.shp.zip"
urlretrieve(ab_url, "data/ab-osm.zip")

with open("landcover-osm.yaml", "r") as f:
    schema = yaml.safe_load(f)

file_keys = ["landuse", "natural", "pofw", "pois", "traffic", "transport", "water",
             "buildings"]
geometries = list()

for f in file_keys:
    df = gpd.read_file(f"data/alberta-latest-free/gis_osm_{f}_a_free_1.shp")
    df["key"] = f
    geometries.append(df)

osm = pd.concat(geometries)

lc_types = list()

for lulc, tags in schema.items():
    for key, values in tags.items():
        if isinstance(values, str):
            values = [values]
        df = osm.loc[osm.fclass.isin(values)]
        df["lulc"] = lulc
        lc_types.append(df)

lc_types = pd.concat(lc_types)
lc_types.loc[lc_types.lulc == "water"].plot(column="fclass")

geom = lc_types.loc[lc_types.lulc == "water"]
geom = geom.to_json()
geo_j = folium.GeoJson(geom)
m = folium.Map(tiles="CartoDB Positron")
geo_j.add_to(m)
m

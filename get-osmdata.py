import osmnx as ox
import geopandas as gpd

# landuse types
tags = {"landuse": True}
landuse = ox.features_from_bbox(
    bbox = (53.9, 53.3, -113.0, -113.9),
    tags=tags
)
landuse.plot(column='landuse')

# building types
tags = {"building": True}
buildings = ox.features_from_bbox(
    bbox = (53.9, 53.3, -113.0, -113.9),
    tags=tags
)
buildings.plot()

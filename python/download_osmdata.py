# %% imports
import pandas as pd
import osmnx as ox
from osmnx._errors import InsufficientResponseError
import geopandas as gpd
import folium


# %% get land use/land cover osm data types
tags = {
    "amenity": True,
    "building": True,
    "landuse": True,
    "leisure": True,
    "military": True,
    "natural": True,
    "public_transport": True,
    "shop": True,
    "tourism": True,
    "water": True,
}

# %% download all osm data except 'relation'
osm = ox.features_from_bbox(bbox=(53.9, 53.3, -113.0, -113.9), tags=tags)
osm.reset_index(inplace=True)
osm_py = osm.loc[osm.element_type.isin(["relation", "way"]), :]

osm_py.columns.tolist()
osm_subset = osm_py.loc[
    :,
    [
        "geometry",
        "landuse",
        "building",
        "amenity",
        "water",
        "tourism",
        "leisure",
        "aeroway",
        "military",
        "natural",
        "public_transport",
    ],
]
osm_py.plot(column="natural")

# %% interative map
folium_map = folium.Map(
    location=[53.5444, -113.4909], zoom_start=10, tiles="Esri.WorldImagery"
)
folium.GeoJson(osm_py.loc[osm_py.landuse == "railway"]).add_to(folium_map)
folium_map


# %% buildings-commercial
osm_py.building.unique()

osm_py["landcover"] = pd.Series(dtype="str")
osm_py.loc[
    osm_py.landuse.isin(["retail", "commercial"])
    | osm_py.building.isin(
        [
            "commercial",
            "retail",
            "mall",
            "office",
            "college",
            "hospital",
            "public",
            "civic",
            "pavilion",
            "church",
            "sports_centre",
            "service",
            "garage",
            "garages",
            "mosque",
            "supermarket",
            "community_centre",
            "temple",
            "university",
            "government",
            "chapel",
            "kindergarten",
            "store",
        ]
    ),
    "landcover",
] = "buildings-commercial"
osm_py.loc[osm_py.landcover == "buildings-commercial"].plot()

# %% buildings-industrial
osm_py.loc[
    osm_py.landuse.isin(["industrial"])
    | osm_py.building.isin(["industrial", "warehouse"]),
    "landcover",
] = "buildings-industrial"
osm_py.loc[osm_py.landcover == "buildings-industrial"].plot()

# %% buildings-residential
osm_py.loc[
    osm_py.landuse.isin(["residential"])
    | osm_py.building.isin(
        [
            "apartments",
            "detached",
            "terrace",
            "semidetached_house",
            "hut",
            "ger",
            "houseboat",
            "static_caravan",
            "house",
            "shed",
            "residential",
            "bungalow",
            "cabin",
            "shelter",
            "carport",
            "dormitory",
            "",
        ]
    ),
    "landcover",
] = "buildings-residential"
osm_py.loc[osm_py.landcover == "buildings-residential"].plot()

# %% create land cover classification
osm_subset["landuse"].unique()
landcover_landuse = pd.DataFrame(
    {"key": "landuse", "landuse": osm_subset["landuse"].unique()}
).dropna()
landcover_landuse["landcover"] = pd.Series(dtype="str")

landcover_landuse.loc[
    landcover_landuse.landuse.isin(
        ["residential", "construction", "residential+disused"]
    ),
    "landcover",
] = "urban-residential"

landcover_landuse.loc[
    landcover_landuse.landuse.isin(
        [
            "commercial",
            "retail",
            "industrial",
            "greenhouse_horticulture",
            "civic",
            "civic_admin",
            "education",
            "institutional",
            "civil",
            "healthcare",
            "religious",
        ]
    ),
    "landcover",
] = "urban-commercial"

landcover_landuse.loc[
    landcover_landuse.landuse.isin(
        [
            "recreation_ground",
            "recreation",
            "park",
            "garden",
            "cemetery",
            "brownfield",
            "greenfield",
            "allotments",
            "flowerbed",
            "plant_nursery",
            "churchyard",
            "orchard",
        ]
    ),
    "landcover",
] = "urban-openspace"

landcover_landuse.loc[
    landcover_landuse.landuse.isin(["forest", "wood", "scrub", "heath", "grass"]),
    "landcover",
] = "rural-natural"

landcover_landuse.loc[
    landcover_landuse.landuse.isin(["farmland", "farmyard", "meadow", "vineyard"]),
    "landcover",
] = "rural-agricultural"

landcover_landuse.loc[
    landcover_landuse.landuse.isin(["basin", "reservoir"]),
    "landcover",
] = "water"

landcover_landuse.loc[
    landcover_landuse.landuse.isin(["garages"]),
    "landcover",
] = "parking"

landcover_landuse.loc[
    landcover_landuse.landuse.isin(["railway"]),
    "landcover",
] = "transport"

landcover_landuse.loc[
    landcover_landuse.landuse.isin(["landfill"]),
    "landcover",
] = "barren"

folium_map = folium.Map(
    location=[53.5444, -113.4909], zoom_start=10, tiles="Esri.WorldImagery"
)
folium.GeoJson(osm_subset.loc[osm_subset.landuse == "railway"]).add_to(folium_map)
folium_map

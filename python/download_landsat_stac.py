from pystac_client import Client as STACClient
import planetary_computer as pc
import xarray as xr
import rioxarray
import stackstac
import geopandas as gpd
from dask.distributed import Client, LocalCluster
import multiprocessing as mp
import matplotlib.pyplot as plt

# %% Start a local cluster (keep worker memory to 2GB)
cluster = LocalCluster(
    n_workers=2,
    threads_per_worker=1,
    memory_limit="2GB",
    processes=False,
)
client = Client(cluster)
client

# %% Search against the Planetary Computer STAC API
catalog = STACClient.open(
    "https://planetarycomputer.microsoft.com/api/stac/v1",
    modifier=pc.sign_inplace,
)

# %% Define area of interest
aoi = {
    "type": "Polygon",
    "coordinates": [
        [[-113.9, 53.3], [-113.0, 53.3], [-113.0, 53.9], [-113.9, 53.9], [-113.9, 53.3]]
    ],
}

# %% Define your search with CQL2 syntax
# for summer of 2021, Landsat 8, cloud cover <= 10%
search = catalog.search(
    filter_lang="cql2-json",
    filter={
        "op": "and",
        "args": [
            {"op": "s_intersects", "args": [{"property": "geometry"}, aoi]},
            {"op": "=", "args": [{"property": "collection"}, "landsat-c2-l2"]},
            {"op": "<=", "args": [{"property": "eo:cloud_cover"}, 30]},
            {"op": ">=", "args": [{"property": "datetime"}, "2021-07-01T00:00:00Z"]},
            {"op": "<=", "args": [{"property": "datetime"}, "2021-08-31T23:59:59Z"]},
        ],
    },
)

items = search.get_all_items()
print(f"Found {len(items)} items")

# get scene bounds as geodataframe
scene_bounds = gpd.GeoDataFrame.from_features(items)

fig, ax = plt.subplots(figsize=(8, 8))
img = scene_bounds.plot(linewidth=0.5, edgecolor="red", facecolor="none", ax=ax)
ax.set_title("Landsat 8 Scenes - Summer 2021 - Cloud Cover <= 30%")
plt.savefig('plots/landsat-scenes.png')

# %% Load the data into an xarray dataset
item = items[2]
ds = rioxarray.open_rasterio(item.assets["swir22"].href, masked=True)

fig, ax = plt.subplots(figsize=(8, 8))
ds.squeeze().plot.imshow()
plt.savefig('plots/landsat-single-band.png')

# %% Load all items into a single xarray dataset
asset_list = ["red", "green", "blue", "nir", "swir16", "swir22", "qa_pixel"]
stack = stackstac.stack(
    items, assets=asset_list, epsg=32611, chunksize={"band": 6, "x": 2048, "y": 2048}
)
stack.chunksizes

# %% Mask out clouds using cloud asset
mask_bitfields = [1, 2, 3, 4]  # dilated cloud, cirrus, cloud, cloud shadow
bitmask = 0
for field in mask_bitfields:
    bitmask |= 1 << field

qa = stack.sel(band="qa_pixel").astype("uint16")
bad = qa & bitmask  # just look at those 4 bits
stack_masked = stack.where(bad == 0)  # mask pixels where any one of those bits are set
stack_masked

# %% Create median composite
median = stack_masked.median("time")

subarea = stack_masked.sel(band="swir22").rio.clip_box(
    minx=600000,
    maxx=601000,
    miny=5.80e6,
    maxy=5.81e6
)

fig, ax = plt.subplots(figsize=(8, 8))
subarea.plot.imshow(robust=True)
plt.savefig('plots/landsat-subarea.png')

# %% write to file
median.rio.to_raster("data/landsat-2021-py.tif")

# %% Plot RGB result
result = rioxarray.open_rasterio("data/landsat-2021-py.tif")

fig, ax = plt.subplots()
result.sel(band=["red", "green", "blue"]).plot.imshow(robust=True, ax=ax)
plt.savefig('plots/final.png')

# %% Close the cluster
client.close()

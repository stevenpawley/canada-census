# %% Import libraries
from pystac_client import Client as STACClient
import planetary_computer as pc
import xarray as xr
import rioxarray
import stackstac
import geopandas as gpd
from dask.distributed import Client, LocalCluster
import multiprocessing as mp

# %% Start a local cluster
cluster = LocalCluster(n_workers=mp.cpu_count(), threads_per_worker=1, processes=False)
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
    [
      [-115.1690563443843, 52.46025704809213],
      [-110.0580367599187, 52.46025704809213],
      [-110.0580367599187, 54.47147165510637],
      [-115.1690563443843, 54.47147165510637],
      [-115.1690563443843, 52.46025704809213]
    ]
  ]
}

# %% Define your search with CQL2 syntax
# for summer of 2021, Landsat 8, cloud cover <= 10%
search = catalog.search(filter_lang="cql2-json", filter={
  "op": "and",
  "args": [
    {"op": "s_intersects", "args": [{"property": "geometry"}, aoi]},
    {"op": "=", "args": [{"property": "collection"}, "landsat-c2-l2"]},
    {"op": "<=", "args": [{"property": "eo:cloud_cover"}, 10]},
    {"op": ">=", "args": [{"property": "datetime"}, "2021-06-01T00:00:00Z"]},
    {"op": "<=", "args": [{"property": "datetime"}, "2021-08-31T23:59:59Z"]},
  ]
})

items = search.get_all_items()
print(f"Found {len(items)} items")

# get scene bounds as geodataframe
scene_bounds = gpd.GeoDataFrame.from_features(items)
scene_bounds.plot(linewidth=0.5, edgecolor="red", facecolor="none")

# %% Load the data into an xarray dataset
item = items[0]
ds = rioxarray.open_rasterio(item.assets["swir22"].href, masked=True)
ds.squeeze().plot.imshow()

# %% Load all items into a single xarray dataset
asset_list = ["red", "green", "blue", "nir", "swir16", "swir22", "qa_pixel"]
stack = stackstac.stack(items, assets=asset_list, epsg=32611)

# %% Mask out clouds using cloud asset
mask_bitfields = [1, 2, 3, 4]  # dilated cloud, cirrus, cloud, cloud shadow
bitmask = 0
for field in mask_bitfields:
    bitmask |= 1 << field

qa = stack.sel(band="qa_pixel").astype("uint16")
bad = qa & bitmask  # just look at those 4 bits
stack_masked = stack.where(bad == 0)  # mask pixels where any one of those bits are set

# %% Create median composite
median = stack_masked.median("time")

# Plot RGB result
median.sel(band=["red", "green", "blue"]).plot.imshow(robust=True)

# %% Write to disk
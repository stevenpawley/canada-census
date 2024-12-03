# %% start grass gis from python
import os
import pandas as pd
from grass_helpers import GrassHelper

# %% start a new grass session
gisbase = "/usr/lib/grass83"
gisdbase = "/media/psf/Grassdata"
location = "dasymetric-mapping"
mapset = "PERMANENT"

grassprj = GrassHelper(gisbase, gisdbase, location, mapset, 4326)
grassprj.set_python_path()
session = grassprj.open_grass_session()

# %% import csv into grass gis
import sqlite3

lulc = pd.read_csv("../data/tables/osm-lulc.csv")

db_path = os.path.join(gisdbase, location, mapset, "sqlite", "sqlite.db")

with sqlite3.connect(db_path) as conn:
    lulc.to_sql("osm_lulc", conn, if_exists="replace", index=False)

# %% example the grass gis_osm_landuse_py attribute table
import grass.script as gs

with sqlite3.connect(db_path) as conn:
    gis_osm_landuse_py = pd.read_sql("SELECT * FROM gis_osm_landuse_py", conn)

gis_osm_landuse_py

# %% join lulc table with the gis_osm_landuse_py grass vector
gs.run_command(
    "v.db.join",
    map="gis_osm_landuse_py",
    column="fclass",
    other_table="osm_lulc",
    other_column="value",
)

# %%
with sqlite3.connect(db_path) as conn:
    gis_osm_landuse_py = pd.read_sql("SELECT * FROM gis_osm_landuse_py", conn)

gis_osm_landuse_py

# %% rasterize
# set region
gs.run_command("g.region", vector="gis_osm_landuse_py", res=30)
gs.run_command(
    "v.reclass",
    input="gis_osm_landuse_py",
    output="gis_osm_landuse_py_reclass",
    column="lulc",
    overwrite=True,
)

gs.run_command(
    "v.to.rast",
    input="gis_osm_landuse_py_reclass",
    output="gis_osm_landuse_py_reclass",
    use="cat",
    label_column="lulc",
    memory=4000,
    overwrite=True,
)

gs.run_command("r.colors", map="gis_osm_landuse_py_reclass", color="random")

# %%
with sqlite3.connect(db_path) as conn:
    poly = pd.read_sql("SELECT * FROM multipolygons", conn)

poly

# %% extract
gs.run_command("v.extract", input="multipolygons", output="multipolygons_railway", type="area",
               where="landuse='railway'", overwrite=True)
# %%
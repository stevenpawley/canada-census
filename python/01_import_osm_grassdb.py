# %% start grass gis from python
import os
from grass_helpers import GrassHelper

# %% start a new grass session
gisbase = "/usr/lib/grass83"
gisdbase = "~/grassdata"
location = "dasymetric-mapping"
mapset = "PERMANENT"

grassprj = GrassHelper(gisbase, gisdbase, location, mapset, 4326)
grassprj.set_python_path()
session = grassprj.open_grass_session()

import grass.script as gs

data_dir = "../data/raw/osm-data"

# %% import every shapefile in the data directory
for f in os.listdir(data_dir):
    if f.endswith(".shp"):
        try:
            gs.run_command(
                "v.import",
                input=os.path.join(data_dir, f),
                output=f.split(".")[0],
                overwrite=True,
            )
        except gs.CalledModuleError as e:
            print(e.stderr)

# %% import the pbf file
gs.run_command(
    "v.import",
    input=os.path.join(data_dir, "alberta-latest.osm.pbf"),
    output="osm",
    overwrite=True,
)

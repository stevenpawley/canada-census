# %% start grass gis from python
import os
import sys

# %% set the GRASS-Python environment
gisbase = os.environ["GISBASE"] = "/Applications/GRASS-8.4.app/Contents/Resources"
os.environ["GISDBASE"] = "/Users/stevenpawley/Grassdb"
location = "osm-data"
mapset = "PERMANENT"

sys.path.append(os.path.join(os.environ["GISBASE"], "etc", "python"))

# %% import GRASS Python bindings
import grass.script as gs
import grass.jupyter as gj

session = gj.init(
    grass_path=os.environ["GISBASE"],
    path=os.environ["GISDBASE"],
    location=location,
    mapset=mapset,
)

# %% create land cover map
# To create an OSM based land-cover map, we start off with the land use layer and
# gradually reclassify other polygon layers into the corresponding land use type
# to fill in any gaps

# land cover classes
# heath + scrub ~ scrubland
# allotments + cemetery + grass + park + recreation_ground ~ open_space
# meadow ~ meadow
# forest ~ forest
# farmland + orchard + vineyard + farmyard ~ farmland
# quarry ~ bare_soil
# retail + industrial + commercial ~ developed_commercial
# residential ~ developed_residential

# pofw ~ developed_commercial

# traffic
# parking ~ paved
# parking_multistorey ~ developed_commercial

# water
# reservoir + water ~ water
# wetland ~ scrubland
# glacier ~ ice

# buildings


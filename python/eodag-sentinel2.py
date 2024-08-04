import os
import shutil
from pathlib import Path

import geopandas as gpd
from eodag import setup_logging
from eodag.api.core import EODataAccessGateway

setup_logging(verbose=2)
dag = EODataAccessGateway()
census = gpd.read_file("data/processed/census-data.gpkg")
output_dir = "data/raw/sentinel2-l2/edmonton-2023"
os.makedirs(output_dir, exist_ok=True)

product_type = 'S2_MSI_L2A'
extent = {
    'lonmin': census.total_bounds[0],
    'lonmax': census.total_bounds[2],
    'latmin': census.total_bounds[3],
    'latmax': census.total_bounds[1]
}

products, _ = dag.search(
    productType=product_type,
    start='2023-08-01',
    end='2023-08-31',
    geom=extent,
    provider="cop_dataspace",
    items_per_page=500,
)

filtered_products = products.filter_property(cloudCover=30, operator="lt")
print("Number of items:", len(filtered_products))

product_path = dag.download_all(filtered_products, extract=False)

for d in product_path:
    p = Path(d)
    dst = Path(output_dir)
    dst = dst / p.name
    shutil.move(d, str(dst))

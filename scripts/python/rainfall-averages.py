import geopandas as gpd
import rasterio
from rasterio.mask import mask
import numpy as np
import os

def calculate_average_rainfall(shapefile_path, start_year_month, end_year_month, output_raster_path):
    borders = gpd.read_file(shapefile_path)
    
    cumulative_rainfall = None
    valid_data_points = None
    metadata = None
    
    start_year, start_month = map(int, start_year_month.split('.'))
    end_year, end_month = map(int, end_year_month.split('.'))
    
    for year in range(start_year, end_year + 1):
        for month in range(1, 13):
            for pentad in range(1, 7):
                if year == start_year and month < start_month:
                    continue
                if year == end_year and month > end_month:
                    break
                
                filename = f"chirps-v2.0.{year}.{str(month).zfill(2)}.{pentad}.tif"
                filepath = os.path.join("./data.chc.ucsb.edu", filename)
                
                if not os.path.exists(filepath):
                    print(f"File not found: {filepath}")
                    continue
                
                with rasterio.open(filepath) as src:
                    if metadata is None:
                        metadata = src.meta.copy()
                    
                    out_image, out_transform = mask(src, borders.geometry, crop=True, all_touched=True)
                    out_image = np.ma.masked_equal(out_image, src.nodata)
                    
                    if cumulative_rainfall is None:
                        cumulative_rainfall = np.zeros(out_image.shape, dtype=np.float32)
                        valid_data_points = np.zeros(out_image.shape, dtype=np.float32)
                    
                    cumulative_rainfall += out_image.filled(0)
                    valid_data_points += ~out_image.mask
                    
    with np.errstate(divide='ignore', invalid='ignore'):
        average_rainfall = np.true_divide(cumulative_rainfall, valid_data_points)
        average_rainfall[valid_data_points == 0] = np.nan  # Avoid division by zero
    
    metadata.update(dtype=rasterio.float32, count=1, nodata=np.nan)
    
    with rasterio.open(output_raster_path, 'w', **metadata) as dst:
        average_rainfall_2d = np.squeeze(average_rainfall)
        dst.write(average_rainfall_2d, 1)

shapefile_path = "./Texas_State_Boundary/State.shp"
start_year_month = "2007.01"
end_year_month = "2007.12"
output_raster_path = "./average_rainfall_texas.tif"

calculate_average_rainfall(shapefile_path, start_year_month, end_year_month, output_raster_path)
print(f"Average Rainfall raster created at: {output_raster_path}")

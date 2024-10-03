# https://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/GAUGE_CONUS/RT/2007/PRCP_CU_GAUGE_V1.0CONUS_0.25deg.lnx.20070101.RT.gz
# https://data.chc.ucsb.edu/products/CHIRPS-2.0/global_pentad/tifs/chirps-v2.0.1981.01.1.tif.gz

import concurrent.futures
import requests
import os

urls = []
download_folder = 'downloaded_data'

if not os.path.exists(download_folder):
    os.makedirs(download_folder)

for year in range(2007, 2022):
    for month in range(1, 13):
        for day in range(1, 32):
            url = f"https://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/GAUGE_CONUS/RT/{year}/PRCP_CU_GAUGE_V1.0CONUS_0.25deg.lnx.{year}{month:02d}{day:02d}.RT.gz"
            urls.append(url)
        for pentad in range(1, 7):
            url = f"https://data.chc.ucsb.edu/products/CHIRPS-2.0/global_pentad/tifs/chirps-v2.0.{year}.{month:02d}.{pentad}.tif.gz"
            urls.append(url)
            
def download_url(url):
    response = requests.get(url)
    file_name = os.path.join(download_folder, url.split('/')[-1])
    with open(file_name, 'wb') as f:
        f.write(response.content)
    print(f"Downloaded {file_name}")

with concurrent.futures.ThreadPoolExecutor() as executor:
    executor.map(download_url, urls)

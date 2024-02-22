import pandas as pd
import json
import os

start_year = 1981

# Ensure to generate this map using the generate-cpc-map.py script
with open('./cpc-map.json') as f:
    cpc_index_map = json.load(f)

# Create the folders and ensure that the Google Earth Engine CHIRPS CSV data are available in the grids directory
grids_directory_path = './grids'
output_directory_path = './grids-transformed'
state = "Texas"


for filename in os.listdir(f"{grids_directory_path}/{state}"):
    chirps = pd.read_csv(f'{grids_directory_path}/{state}/{filename}')

    chirps_code_suffix = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y']
    hist_sum_map = {}
    hist_avg_map = {}

    for index, row in chirps.iterrows():
        cpc_grid_code = int(row['CPC Grid Code'])
        year = int(row['Year'])
        interval = int(row['Interval'])
        precipitation = row['Precipitation (Sum)']
        latitude = row['Latitude']
        longitude = row['Longitude']
        chirps_code = f"{cpc_grid_code}{chirps_code_suffix[index%25]}"

        if f"{chirps_code}:{interval}" not in hist_sum_map:
            hist_sum_map[f"{chirps_code}:{interval}"] = precipitation
        else:
            hist_sum_map[f"{chirps_code}:{interval}"] += precipitation
        
        num_years = (year - start_year) + 1
        chirps_avg = hist_sum_map[f"{chirps_code}:{interval}"] / num_years
        hist_avg_map[f"{chirps_code}:{interval}:{year}"] = chirps_avg

        chirps.loc[index, 'CHIRPS-CPC Code'] = chirps_code
        chirps.loc[index, 'CHIRPS Historical Average'] = chirps_avg

        if year >= 2007:
            chirps.loc[index, "CHIRPS Index"] = round((precipitation/hist_avg_map[f"{chirps_code}:{interval}:{year - 2}"]), 3)
        else:
            chirps.loc[index, "CHIRPS Index"] = ""
        
        if f"{cpc_grid_code}:{year}:{interval}" not in cpc_index_map:
            chirps.loc[index, "CPC Index"] = ""
        else:
            chirps.loc[index, "CPC Index"] = cpc_index_map[f"{cpc_grid_code}:{year}:{interval}"]

    chirps.to_csv(f'{output_directory_path}/{state}/{filename}', index=False)
    
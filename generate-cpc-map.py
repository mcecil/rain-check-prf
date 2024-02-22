import pandas as pd
import json

cpc_index_filename = 'Rainfall_Index_HistoricData2023CY.txt'

df = pd.read_csv(cpc_index_filename, sep='|')

cpc_map = {}

for index, row in df.iterrows():
    cpc_grid_code = int(row['grid_id'])
    year = int(row['Year'])
    interval = int(row['PracticeCode'])
    index = row['ActualIndex']
    print(f"Processing {cpc_grid_code}:{interval}:{year}:{index}")

    if f"{cpc_grid_code}:{year}:{interval}" not in cpc_map:
        cpc_map[f"{cpc_grid_code}:{year}:{interval}"] = index

with open('cpc-map.json', 'w') as f:
    json.dump(cpc_map, f, indent=4)
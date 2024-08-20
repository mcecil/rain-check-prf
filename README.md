# PRF RI Notes.

This repository compares various aspects (rates, payouts, etc) of the PRF_RI insurance program for two different precipitation data sets. The first, is the CPC derived precipitation used in the current model. The second, is finer scale (0.05 degrees) CHIRPS precipitation data. 

## Downloading CHIRPS data

[CHIRPS precip data](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_PENTAD) is downloaded from Google Earth Engine (GEE) and aligned with CPC grids. The data is grouped in pentads (5-days) within each month, although the last "pentad" can vary in length, and represents all days from the 26th to the end of the month. 

This uses the following scripts. The below scripts assume a user has access to a CPC grid asset (like "users/ramaraja/grids") in GEE. Grids shapefile is also available from the CPC [here](https://pubfs-rma.fpac.usda.gov/pub/Miscellaneous_Files/VI_RI_Data/index.html).

- [GEE script](https://code.earthengine.google.com/1134e155755e81a955bebc20df4f9c62) to extract CPC grid IDs by state. Outputs are files like "TX-grids.csv" with a single column containing all grid IDs in the state.

- Jupyter notebook "PRF-RI_CPC_CHIRPS.ipynb" is used to extract CHIRPS values within each CPC grid, for the years (1981-2021) and 2-month intervals used in the PRF-RI program. Outputs are files like 'CHIRPS_precip_TX_1981_625.csv' which contains CHIRPS precip values for all CPC grids in Texas in 1981, for the "625" interval (Jan - Feb). The total # of ouput files per state should equal (11 intervals) x (41 years).

- Jupyter notebook "consolidate_CHIRPS.ipynb" to reshape and consolidate CHIRPS observation outputs (need to create)

## Determining county proportions

PRF-RI statement of business data on enrollment is at the county level. Thus, we need to understand the percent of each county that is within different CPC grid ID's. (similar for CHIRPS) 

- [GEE script](https://code.earthengine.google.com/bb14c742606a6e78d2394e2b79022fb2) to calculate CPC grid areas. Outputs are files like "county-areas-anomaly.csv" that contain a column "Proportion" that is the proportion of the county represented by each CPC grid (sums to 1 for each county).

- [GEE script](https://code.earthengine.google.com/11b9ab34fcaee8ec601e76fc7cb78532) for CHIRPS grid areas. Similar to above, but using CHIRPS grids. Outputs are files like " chirps-county-areas.csv, with columns "Total Area" representing the area of the CPC grid cell within the county, and "Area" representing the area of the CHIRPS pixel within that CPC area (so sum of "Area" should equal "Total Area" for each CPC grid cell.

## Additional data collection

- Historic CPC raw values can be downloaded using the archived [rnoaa package](https://github.com/ropensci/rnoaa). The script "download_cpc.R" downloads CPC data at a daily timestep for all grids, and saves values to a .csv file for each day (e.g. "cpc_2022-12-31.csv"). The script "group_month_cpc.R" groups CPC data into 2-month intervals, calculates interval sum precip for 1948-2022, and calculates CPC index values (current year precip divided by average precip from 1948 to (current year - 2)).

- Historic CPC index values are available [here](https://pubfs-rma.fpac.usda.gov/pub/Miscellaneous_Files/VI_RI_Data/index.html) in files like "Rainfall_Index_HistoricData2022CY.txt". However it is not clear how the index is calculated. For example, the index values for grid 15414, year 2010, interval 627 are slightly different in the "2020CY" (index value 3.483) and "2020CY" (index value 3.366)  files, indicating that a different baseline is used.

  



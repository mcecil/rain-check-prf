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

- [GEE script](https://code.earthengine.google.com/11b9ab34fcaee8ec601e76fc7cb78532) for CHIRPS grid areas. Similar to above, but using CHIRPS grids. Outputs are files like " chirps-county-areas.csv, with columns "Total Area" representing the area of the CPC grid cell within the county, and "Area" representing the area of the CHIRPS pixel within that CPC area (so sum of "Area" should equal "Total Area" for each CPC grid cell. There is a subsequent script "get-chirps-proportions.py" that adds a column for the proportion of each CPC pixel. 

## Additional data collection

- Historic CPC raw values can be downloaded using the archived [rnoaa package](https://github.com/ropensci/rnoaa). The script "download_cpc.R" downloads CPC data at a daily timestep for all grids, and saves values to a .csv file for each day (e.g. "cpc_2022-12-31.csv"). The script "group_month_cpc.R" groups CPC data into 2-month intervals, calculates interval sum precip for 1948-2022, and calculates CPC index values (current year precip divided by average precip from 1948 to (current year - 2)).

- Historic CPC index values are also available [here](https://pubfs-rma.fpac.usda.gov/pub/Miscellaneous_Files/VI_RI_Data/index.html) in files like "Rainfall_Index_HistoricData2022CY.txt". However it is not clear how the index is calculated. For example, the index values for grid 15414, year 2010, interval 627 are slightly different in the "2020CY" (index value 3.483) and "2020CY" (index value 3.366)  files, indicating that a different baseline is used.

- Summary of business data is available [here](https://www.rma.usda.gov/Information-Tools/Summary-of-Business/State-County-Crop-Summary-of-Business). We use the type/practice/unit files like "SOBSCCTPU21.TXT".
	The files contain historical details about the payouts, premium paid, area covered, total liability, etc., on a county level.

- Premium and county base value rates are downloaded from the USDA RMA API using the "extract-rates.py" script. The script extracts the data for all the counties for a given state for all the intended uses (5) and all the coverage levels (5) across the years 2007-2021 (15). Data are saved to "Colorado-2023-grazing-70-rates.csv". Rates vary based on grid cell, interval, and year. I believe the index threshold (e.g. 0.70 or 70) affects the "Premium Rate" column and the irrigation/organic type (e.g. "grazing", "haying irrigated", "haying-non-irrigated-non-organic" etc) affects the "County Base Value" column.  Data has been extracted for TX, VA, CO so far. **Currently the RMA API is not working so we are using already downloaded values for rates and CBV**.

## Data augmentation

- The downloaded daily CPC vlaues are then processed into interval precipitation and interval index values in "group_month_cpc_na_rm.R". The output table is "monthly_averages_na_rm.csv". For the time-being, NA values are discarded and treated as 0 precipitation. (there are only a handful of such values).

- The script "join_grid_cpc.R" is used to join CPC index values to the grid polygons for mapping. 
  
- The script "generate-cpc-map.py" creates a .json file for faster lookup of CPC downloaded index values for grid-interval-year combinations. We could also create this for the CPC calculated index values. The output is saved to "cpc-map.json"

- We calculate the CHIRPS index values using the script "generate-chirps-index.py". This script takes as input the files like "grid-10019.csv" containing CHIRPS precip values and the "cpc-map.json" file containing CPC precip values. The output are files like "grid-10019.csv" containing additional columns for CHIRPS precip data, and saved in the "precipitation-transformed" folder. **the logic generally makes sense but this script needs to be rewritten for the different CPC and CHIRPS data sources**

- Calculate CHIRPS grid proportions using "get-chirps-proportions.py".

## Payout and analysis

- "payout.py" . Loops through years, and counties in state. Extend adds multiple elements to list. calls "calculate_payout", based on year, interval, state, county, and productivity factor. looks up intervals, total acres, subsidy level based on year, state, county code. gets list of CPC grids based on county. gets rates, CPC indices, CPC/CHIRPS proportions based on county.
  - loops over items from SOB, based on coverage level and area. this is county level, so I think it assumes each observation in a county is equally weighted across all CPC/CHIRPS grids in the county (based on proportion). it calculates CPC and CHIRPS payout for this, which includes information (from SOB) on premium, indemnity, liability
  - inputs files outlined well in Ram's explanation. include: summary of business (TPU files), rates info (from RMA API), grids info (I think from "transformed" folder with CHIRPS indices), counties, CHIRPS and CPC proportions.
  - outputs are files like "2011-payouts.csv", that contain one row for each coverage level (e.g. 70, 85, 90) in a county (likely each coverage level that appears in the SOB file). the file contains info on premium (total, subsidy, actual), indemnity and liability. I'm not 100% clear on why the premium and liability differ between CPC and CHIRPS (they are close but slightly different). Is this due to the area used to calculate each? The "area" field is calculated from the sum of all area in the TPU files for the county (both haying and grazing) for the specified coverage level (70 etc)
  - Looks like some slight errors in column names in the code. columns are named "CPC_indemnity_payout" but then the code calls "CPC_indemnity" which results in the colummns not being filled in the output. need to update. 
  - need to look into how this chooses intervals from SOB. it looks like it iterates through the SOB data based on year and county and extracts the first two non-overlapping intervals (based on "Practice Code" field. do we know if the SOB data is sorted by area? . note - it does not appear the two most common intervals. I tested for 2011, Texas, Falls County, and the Mar-April interval (627) seems most common (both for haying and grazing), but the interals selected are 625 and 635.

- "generate-deviation-count.py"




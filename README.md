# PRF RI Notes.

This repository calculates payouts for the PRF_RI insurance program for two different precipitation data sets, related to this manuscript. The first, is the CPC derived precipitation used in the current model. The second, is finer scale (0.05 degrees) CHIRPS precipitation data. 

## Key files


## Input Data Sources
- [CHIRPS rainfall data](https://umd.box.com/s/9e7tvqgfu8lop17u6kmbp655zl8iuiil) . Downloaded from [Google Earth Engine]((https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_PENTAD)) using [`PRF_RI_CPC_CHIRPS.ipynb`](scripts/python/PRF_RI_CPC_CHIRPS.ipynb)
- [CPC rainfall data](https://umd.box.com/s/c51a4d4bzr036w2zxbr4yc8xoxtyy8ou) . Downloaded using the `rnoaa` package in [`download_cpc.R`](scripts/R/download_cpc.R)
- [CPC grid boundaries](https://umd.box.com/s/9twqpbm77aj58hwpwuy4kbu853fqpe8a) . Used in both GEE and R scripts.
- [PRF Statement of Business](https://umd.box.com/s/tl9rd30bh7m7ocble3hf02r30vdq1kfk) . Downloaded from [PRF records site](https://www.rma.usda.gov/tools-reports/summary-of-business/state-county-crop-summary-business) ('State/County/Crop/Coverage Level 1989 - Present')
- [PRF Type Practice Unit](https://umd.box.com/s/gubd26v9809j6ldk7lh7t34s57suznrs) . Downloaded from [PRF records site](https://www.rma.usda.gov/tools-reports/summary-of-business/state-county-crop-summary-business) ('Type/Practice/Unit Structure Data Files'). Contains more granular data including interval selection.
- [TX Counties](https://umd.box.com/s/bkl1l8zvws2q2mvuxgegw7p03cyr617l) . Downloaded from [Texas Tech](https://www.depts.ttu.edu/geospatial/center/TexasGISData.html) (jurisdictional boundaries)
- [TX rates and County-Base Values](https://umd.box.com/s/qkqsxb4tun0ww54dwsbhysuon2qbg4by) . Downloaded from USDA RMA API in [`extract-rates.py`](scripts/python/extract-rates.py).  **Currently the RMA API is not working so we are using previously downloaded values for rates and CBV**
- [TX County Areas](https://umd.box.com/s/ni2zesuhjz4z7j1pk6wsr4abahpwr0a7) . Table of county proportions belonging to CPC and CHIRPS grid cells. Calculated using GEE scripts for [CPC](https://code.earthengine.google.com/bb14c742606a6e78d2394e2b79022fb2) and [CHIRPS](https://code.earthengine.google.com/11b9ab34fcaee8ec601e76fc7cb78532) .
- [Cropland Data Layer](https://umd.box.com/s/lifkf8gt8c4uz1wjtcay4pqpyum5e0r9). Downloaded from [USDA](https://www.nass.usda.gov/Research_and_Science/Cropland/Release/)
- [Koppen Climate Classification](https://umd.box.com/s/8gw6s3bf4utua85uve1phexmo21it79h) Downloaded from [University of Idaho](https://www.arcgis.com/home/item.html?id=a1209a5383c04ef18addea0e10ab10e5)

Final input data files are available on [Box](https://umd.box.com/s/0z6z6xpikrf7nspof4dtzn8iv2p8ulbr), and should be added to the project folder [`data`]() .

## Output Files
- [`outputs`]() Contains key intermediate and final output files.
- [`outputs\payouts`]() Simulated payout magnitudes for various data assumptions.
- [`outputs\figures`]() Contains intermediate and final figures.
- [`outputs\tables`]() LaTeX formatted tables

## Downloading CHIRPS data

[CHIRPS precip data](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_PENTAD) is downloaded from Google Earth Engine using [`PRF_RI_CPC_CHIRPS.ipynb`](scripts/python/PRF_RI_CPC_CHIRPS.ipynb) and aligned with CPC grids. The data is grouped in pentads (5-days) within each month, although the last "pentad" can vary in length, and represents all days from the 26th to the end of the month. We also use the [GEE script](https://code.earthengine.google.com/1134e155755e81a955bebc20df4f9c62) to extract CPC grid IDs by state. Outputs are files like "TX-grids.csv" with a single column containing all grid IDs in the state.

## Determining county proportions

PRF-RI statement of business data on enrollment is at the county level. Thus, we need to understand the percent of each county that is within different CPC grid ID's. (similar for CHIRPS) 

- [GEE script](https://code.earthengine.google.com/6ed9ba3ec817ea886cd94d499ffb126b) calculates CPC grid areas. Outputs are the file "cpc-county-areas.csv" that contains a column "Proportion" that is the proportion of the county represented by each CPC grid (sums to 1 for each county).

- [GEE script](https://code.earthengine.google.com/11b9ab34fcaee8ec601e76fc7cb78532) for CHIRPS grid areas. Similar to above, but using CHIRPS grids. Outputs are files like " chirps-county-areas.csv, with columns "Total Area" representing the area of the CPC grid cell within the county, and "Area" representing the area of the CHIRPS pixel within that CPC area.

## Additional data collection notes

- Historic CPC raw values can be downloaded using the archived [rnoaa package](https://github.com/ropensci/rnoaa), using the script [`download_cpc.R`](scripts/R/download_cpc.R).

- Premium rates and county base values (CBV) are downloaded from the USDA RMA API using the "extract-rates.py" script. The script extracts the data for all the counties for a given state for all the use types (5, e.g., grazing) and all the coverage levels (5, e.g., 70%) across the year 2023. Data are saved to files like "Texas-2023-grazing-70-rates.csv". The script extracts the data for all the counties for a given state, for all the intended uses (5) and all the coverage levels (5). We make the following assumptions.
  - Extracted premium rates and CBV values do not depend on year. 
  - Intended use type only affects CBV.
  - Coverage level only affects premium rates.
- Rates vary based on grid cell, interval, and year. **Currently the RMA API is not working so we are using previously downloaded values for rates and CBV**.


## Replication
- These steps assume input data sources have already been downloaded (using scripts starting with "0_")
- Copy files from [Box]() to [`data`]() folder.
- Process CPC data into monthly values using [`1_1_group_month_cpc_na_rm.R`]().
- Calculate other rainfall indices using [`1_2_index_calculation.Rmd`]().
- Calculate payouts with [`1_3_payout_calculations.Rmd`]().
- Calculate CDL area weights with [`1_4_cdl_calculations.Rmd`]()
- Create figures and tables with [`2_1_Figures.Rmd`]() through [`2_12_Figures.Rmd`]() .







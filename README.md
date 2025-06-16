# Rain Check PRF RI

This repo calculates payouts for the PRF_RI insurance program for two different precipitation data sets (CPC and CHIRPS), for the ARER manuscript [Benami et al. 2025](). 

All input and output data files, figures, and tables are available on [Zenodo](https://zenodo.org/records/15171495) and should be added beneath the `data` folder for this repository.

## Replication
- These steps assume input data sources have already been downloaded (using scripts starting with "0_")
- Copy files from [Zenodo](https://zenodo.org/records/15171495) to top-level [`data`] folder.
- Process CPC data into monthly values using [`1_1_group_month_cpc_na_rm.R`](scripts/R/1_1_group_month_cpc_na_rm.R).
- Calculate other rainfall indices using [`1_2_index_calculation.Rmd`](scripts/R/1_2_index_calculation.Rmd).
- Calculate payouts with [`1_3_payout_calculations.Rmd`](scripts/R/1_3_payout_calculations.Rmd).
- Calculate CDL area weights with [`1_4_cdl_calculations.Rmd`](scripts/R/1_4_cdl_calculations.Rmd)
- Create figures and tables with [`2_1_Figures.Rmd`](scripts/R/2_1_Figures.Rmd) through [`2_12_Figures.Rmd`](scripts/R/2_12_Figures.Rmd) .

## Input Data Sources
- **CHIRPS rainfall data** . Downloaded from [Google Earth Engine]((https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_PENTAD)) using [`0_2_PRF_RI_CHIRPS_TX.ipynb`](scripts/python/0_2_PRF_RI_CHIRPS_TX.ipynb)
- **CPC rainfall data** . Downloaded using the [`rnoaa`](https://github.com/ropensci/rnoaa) package in [`0_1_download_cpc.R`](scripts/R/0_1_download_cpc.R)
- **CPC grid boundaries** . Used in both GEE and R scripts.
- **PRF Statement of Business** . Downloaded 'State/County/Crop/Coverage Level 1989 - Present' from [PRF records site](https://www.rma.usda.gov/tools-reports/summary-of-business/state-county-crop-summary-business)
- **PRF Type Practice Unit** . Downloaded 'Type/Practice/Unit Structure Data Files' from [PRF records site](https://www.rma.usda.gov/tools-reports/summary-of-business/state-county-crop-summary-business) . Contains more granular data including interval selection.
- **TX Counties** . Downloaded from [Texas Tech](https://www.depts.ttu.edu/geospatial/center/TexasGISData.html) (jurisdictional boundaries)
- **TX rates and County-Base Values** . Downloaded from USDA RMA API in [`extract-rates.py`](scripts/python/extract-rates.py).  **Currently the RMA API is not working so we are using previously downloaded values for rates and CBV**
- **TX County Areas** . Table of county proportions belonging to CPC and CHIRPS grid cells.
- **Cropland Data Layer**. Downloaded from [USDA](https://www.nass.usda.gov/Research_and_Science/Cropland/Release/)
- **Koppen Climate Classification** Downloaded from [University of Idaho](https://www.arcgis.com/home/item.html?id=a1209a5383c04ef18addea0e10ab10e5)

## Output Files
- `data/outputs` Contains key intermediate and final output files.
  - `monthly_averages_na_rm.csv` . Contains CPC monthly averages and rainfall index (RI) values using 1948 start year.
  - `chirps_data_TX_ri.rda` . Contains CHIRPS grid level index calculations for all CPC and CHIRPS derived indices.
  - `chirps_data_TX_region.rda` . Same as above, also contains field for Texas region (1 = West TX, 2 = East TX)
  - `grids_cv_all_years.rda` . Contains coefficient of variation calculations at CPC grid level.
- `data/outputs/payouts` Simulated payout magnitudes for various data spatiotemporal assumptions. Uses RMA TPU level reports as starting point.
- `data/outputs/figures` Contains intermediate and final figures.
- `data/outputs/tables` LaTeX formatted tables

## Downloading CHIRPS data

[CHIRPS precip data](https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_PENTAD) is downloaded from Google Earth Engine (GEE) using [`PRF_RI_CPC_CHIRPS.ipynb`](scripts/python/PRF_RI_CPC_CHIRPS.ipynb) and aligned with CPC grids. The data is grouped in pentads (5-days) within each month, although the last "pentad" can vary in length, and represents all days from the 26th to the end of the month. We also use the [GEE script](https://code.earthengine.google.com/1134e155755e81a955bebc20df4f9c62) to extract CPC grid IDs by state. Outputs are files like "TX-grids.csv" with a single column containing all grid IDs in the state.

## Determining county proportions

PRF-RI statement of business data on enrollment is at the county level. Thus, we need to understand the percent of each county that is within different CPC grid ID's. (similar for CHIRPS) 

- [GEE script](https://code.earthengine.google.com/6ed9ba3ec817ea886cd94d499ffb126b) calculates CPC grid areas within each county. Outputs are the file "cpc-county-areas.csv" that contains a column "Proportion" that is the proportion of the county represented by each CPC grid (sums to 1 for each county).

- [GEE script](https://code.earthengine.google.com/11b9ab34fcaee8ec601e76fc7cb78532) calculates CHIRPS grid areas within each county. Outputs are files like " chirps-county-areas.csv, with columns "Total Area" representing the area of the CPC grid cell within the county, and "Area" representing the area of the CHIRPS pixel within that CPC area.

## Additional data collection notes

- Historic CPC raw values can be downloaded using the archived [rnoaa package](https://github.com/ropensci/rnoaa), using the script [`download_cpc.R`](scripts/R/download_cpc.R).

- Premium rates and county base values (CBV) are downloaded from the USDA RMA API using the [`extract-rates.py`](scripts/python/extract-rates.py) script. The script extracts the data for all the counties for a given state for all the use types (5, e.g., grazing) and all the coverage levels (5, e.g., 70%) across the year 2023. Data are saved to files like "Texas-2023-grazing-70-rates.csv". The script extracts the data for all the counties for a given state, for all the intended uses (5) and all the coverage levels (5). We make the following assumptions.
  - Extracted premium rates and CBV values do not depend on year. 
  - Intended use type only affects CBV.
  - Coverage level only affects premium rates.
- Rates vary based on grid cell, interval, and year. **Currently the RMA API is not functional so we are using previously downloaded values for rates and CBV**.










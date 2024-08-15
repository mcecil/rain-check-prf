# PRF RI Notes.

This repository compares various aspects (rates, payouts, etc) of the PRF_RI insurance program for two different precipitation data sets. The first, is the CPC derived precipitation used in the current model. The second, is finer scale (0.05 degrees) CHIRPS precipitation data. 

## Downloading CHIRPS data

CHIRPS precip data is downloaded from Google Earth Engine (GEE) and aligned with CPC grids. This uses the following scripts. The below scripts assume a user has access to a CPC grid asset (like "users/ramaraja/grids") in GEE. 

- [GEE script](https://code.earthengine.google.com/1134e155755e81a955bebc20df4f9c62) to extract CPC grid IDs by state. Outputs are files like "TX-grids.csv" with a single column containing all grid IDs in the state.

- Jupyter notebook "PRF-RI_CPC_CHIRPS.ipynb" is used to extract CHIRPS values within each CPC grid, for the years (1981-2021) and 2-month intervals used in the PRF-RI program. Outputs are files like 'CHIRPS_precip_TX_1981_625.csv' which contains CHIRPS precip values for all CPC grids in Texas in 1981, for the "625" interval (Jan - Feb). The total # of ouput files per state should equal (11 intervals) x (41 years). 

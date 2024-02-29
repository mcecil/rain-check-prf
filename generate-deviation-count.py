import pandas as pd

tx_grids = pd.read_csv(f"./state-data/texas/cpc-grid-codes.csv")["GRIDCODE"].to_list()
year = 2021

data = []
for interval_code in range(625, 636):

    for gridCode in tx_grids:
        grid_df = pd.read_csv(f"./Texas-transformed/grid-{gridCode}.csv")

        grid_df = grid_df[grid_df["Year"] == year]
        grid_df = grid_df[grid_df["Interval"] == interval_code]

        grid_df["CPC >= 0.7"] = grid_df["CPC Index"] >= 0.7
        grid_df["CHIRPS >= 0.7"] = grid_df["CHIRPS Index"] >= 0.7

        grid_df["CPC >= 0.8"] = grid_df["CPC Index"] >= 0.8
        grid_df["CHIRPS >= 0.8"] = grid_df["CHIRPS Index"] >= 0.8

        grid_df["CPC >= 0.9"] = grid_df["CPC Index"] >= 0.9
        grid_df["CHIRPS >= 0.9"] = grid_df["CHIRPS Index"] >= 0.9

        grid_df["Deviation (0.7)"] = grid_df["CPC >= 0.7"] != grid_df["CHIRPS >= 0.7"]
        grid_df["Deviation (0.8)"] = grid_df["CPC >= 0.8"] != grid_df["CHIRPS >= 0.8"]
        grid_df["Deviation (0.9)"] = grid_df["CPC >= 0.9"] != grid_df["CHIRPS >= 0.9"]

        grid_df["CPC Payout CHIRPS Not (0.7)"] = (
            (grid_df["Deviation (0.7)"] == True)
            & (grid_df["CPC Index"] < 0.7)
            & (grid_df["CHIRPS Index"] >= 0.7)
        )
        grid_df["CPC Payout CHIRPS Not (0.8)"] = (
            (grid_df["Deviation (0.8)"] == True)
            & (grid_df["CPC Index"] < 0.8)
            & (grid_df["CHIRPS Index"] >= 0.8)
        )
        grid_df["CPC Payout CHIRPS Not (0.9)"] = (
            (grid_df["Deviation (0.9)"] == True)
            & (grid_df["CPC Index"] < 0.9)
            & (grid_df["CHIRPS Index"] >= 0.9)
        )

        grid_df["CHIRPS Payout CPC Not (0.7)"] = (
            (grid_df["Deviation (0.7)"] == True)
            & (grid_df["CHIRPS Index"] < 0.7)
            & (grid_df["CPC Index"] >= 0.7)
        )
        grid_df["CHIRPS Payout CPC Not (0.8)"] = (
            (grid_df["Deviation (0.8)"] == True)
            & (grid_df["CHIRPS Index"] < 0.8)
            & (grid_df["CPC Index"] >= 0.8)
        )
        grid_df["CHIRPS Payout CPC Not (0.9)"] = (
            (grid_df["Deviation (0.9)"] == True)
            & (grid_df["CHIRPS Index"] < 0.9)
            & (grid_df["CPC Index"] >= 0.9)
        )

        dev_70_count = 0
        dev_80_count = 0
        dev_90_count = 0
        cpc_payout_70_count = 0
        cpc_payout_80_count = 0
        cpc_payout_90_count = 0
        chirps_payout_70_count = 0
        chirps_payout_80_count = 0
        chirps_payout_90_count = 0

        for _, row in grid_df.iterrows():
            if row["Deviation (0.7)"] == True:
                dev_70_count += 1

            if row["Deviation (0.8)"] == True:
                dev_80_count += 1

            if row["Deviation (0.9)"] == True:
                dev_90_count += 1

            if row["CPC Payout CHIRPS Not (0.7)"] == True:
                cpc_payout_70_count += 1

            if row["CPC Payout CHIRPS Not (0.8)"] == True:
                cpc_payout_80_count += 1

            if row["CPC Payout CHIRPS Not (0.9)"] == True:
                cpc_payout_90_count += 1

            if row["CHIRPS Payout CPC Not (0.7)"] == True:
                chirps_payout_70_count += 1

            if row["CHIRPS Payout CPC Not (0.8)"] == True:
                chirps_payout_80_count += 1

            if row["CHIRPS Payout CPC Not (0.9)"] == True:
                chirps_payout_90_count += 1

        data.append(
            {
                "GRIDCODE": gridCode,
                "interval_code": interval_code,
                "dev_70_count": dev_70_count,
                "dev_80_count": dev_80_count,
                "dev_90_count": dev_90_count,
                "cpc_payout_70_count": cpc_payout_70_count,
                "cpc_payout_80_count": cpc_payout_80_count,
                "cpc_payout_90_count": cpc_payout_90_count,
                "chirps_payout_70_count": chirps_payout_70_count,
                "chirps_payout_80_count": chirps_payout_80_count,
                "chirps_payout_90_count": chirps_payout_90_count,
            }
        )

df = pd.DataFrame(data)
df.to_csv(
    f"./deviation/deviation-count-{year}.csv",
    index=False,
)

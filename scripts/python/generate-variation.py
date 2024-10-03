import pandas as pd

tx_grids = pd.read_csv(f"./state-data/texas/cpc-grid-codes.csv")["GRIDCODE"].to_list()


def get_coeff_var_precipitation(grid_code):
    grid_df = pd.read_csv(f"./Texas-transformed/grid-{grid_code}.csv")
    grid_df = grid_df[grid_df["Year"] >= 2007]

    intervals = [*range(625, 636)]
    years = grid_df["Year"].unique()
    stdevMap = {
        "year": [],
    }
    for interval in intervals:
        stdevMap[interval] = []

    for year in years:
        stdevMap["year"].append(year)
        for interval in intervals:
            stdevMap[interval].append(
                (
                    round(
                        grid_df[
                            (grid_df["Interval"] == interval)
                            & (grid_df["Year"] == year)
                        ]["Precipitation (Sum)"].std(),
                        4,
                    )
                    / round(
                        grid_df[
                            (grid_df["Interval"] == interval)
                            & (grid_df["Year"] == year)
                        ]["Precipitation (Sum)"].mean(),
                        4,
                    )
                )
                * 100
            )

    stdevMap["grid_code"] = [grid_code] * len(stdevMap["year"])
    return stdevMap


data = []
for grid_code in tx_grids:
    stdevMap = get_coeff_var_precipitation(grid_code)
    dict1 = {}
    for key, value in stdevMap.items():

        print(key, value)
    data.append()

coeff_var_df = pd.DataFrame(data)

coeff_var_df.to_csv(
    "/Users/ram/Documents/Projects/VT/prf-ri/precipitation-coeff-var.csv", index=False
)

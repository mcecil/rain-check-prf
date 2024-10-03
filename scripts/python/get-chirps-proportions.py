import pandas as pd

chirps_df = pd.read_csv(f"./chirps-county-areas.csv")

proportion = []
for index, row in chirps_df.iterrows():
    if row["Area"] == 0:
        proportion.append(0)
    else:
        proportion.append(row["Area"]/row["Total Area"])

chirps_df["Proportion"] = proportion

chirps_df.to_csv("./chirps-county-areas.csv",index=False)
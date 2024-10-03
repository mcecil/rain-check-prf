# This script still picks the top 2 intervals but uses the new rates according to intended use.

import json
import pandas as pd


def read_summary_of_business(year, state, county_code):
    state_code = state["state_code"]
    state_name = state["state_name"]
    headers = [
        "Commodity Year",
        "State Code",
        "State Name",
        "State Abbreviation",
        "County Code",
        "County Name",
        "Commodity Code",
        "Commodity Name",
        "Insurance Plan Code",
        "Insurance Plan Abbreviation",
        "Coverage Type Code",
        "Coverage Level Percent",
        "Delivery ID",
        "Type Code",
        "Type Name",
        "Practice Code",
        "Practice Name",
        "Unit Structure Code",
        "Unit Structure Name",
        "Net Reporting Level Amount",
        "Reporting Level Type",
        "Liability Amount",
        "Total Premium Amount",
        "Subsidy Amount",
        "Indemnity Amount",
        "Loss Ratio",
        "Endorsed Commodity Reporting Level Amount",
    ]
    sob_df = pd.read_csv(
        f"./summary-of-business/{state_name.lower()}/SOBSCCTPU{str(year)[-2:]}.TXT",
        sep="|",
        header=None,
        names=headers,
    )
    sob_df = sob_df[
        (sob_df["State Code"] == state_code)
        & (sob_df["County Code"] == county_code)
        & (sob_df["Insurance Plan Code"] == 13)
    ].sort_values(
        by=["Net Reporting Level Amount", "Practice Code"], ascending=[False, True]
    )

    return sob_df


def get_index_intervals(year, state, county_code):
    sob_df = read_summary_of_business(year, state, county_code)

    if sob_df.shape[0] == 0:
        return None

    intervals = []
    for _, row in sob_df.iterrows():
        if len(intervals) == 2:
            break

        interval_code = row["Practice Code"]
        if interval_code not in [
            value for sublist in practices.values() for value in sublist
        ]:
            continue

        # Check that the intervals are not overlapping
        if len(intervals) > 0:
            prev_interval_code = intervals[0]
            if (
                prev_interval_code + 1 == interval_code
                or interval_code + 1 == prev_interval_code
            ):
                continue

        intervals.append(interval_code)

    return intervals


def get_total_acres(year, state, county_code):
    sob_df = read_summary_of_business(year, state, county_code)
    return (
        sob_df.groupby("Coverage Level Percent")["Net Reporting Level Amount"]
        .sum()
        .to_dict()
    )


def get_premium_rate(year, state, county_code, grid_code, interval_code):
    state_code = state["state_code"]
    state_name = state["state_name"]
    premium_rates = {}
    for i in range(70, 95, 5):
        rates_df = pd.read_csv(
            f"./rates/{state_name.lower()}/{state_name}-{year}-{coverage_level_intended_use_mapping[i]}-{i}-rates.csv"
        )
        premium_rate = rates_df[
            (rates_df["State Code"] == state_code)
            & (rates_df["County Code"] == county_code)
            & (rates_df["CPC Grid Code"] == grid_code)
            & (rates_df["Interval Code"] == adjusted_interval_codes[interval_code])
        ]["Premium Rate"].iloc[0]
        premium_rates[i] = premium_rate

    premium_rates[60] = premium_rates[70]
    return premium_rates


def get_rates(year, state, county_code, grid_code, interval_codes):
    state_code = state["state_code"]
    state_name = state["state_name"]

    interval_rates = {}
    for interval_code in interval_codes:

        intended_use = ""
        if interval_code in practices["grazing"]:
            intended_use = "grazing"
        elif interval_code in practices["haying-irrigated"]:
            intended_use = "haying-irrigated"
        elif interval_code in practices["haying-non-irrigated-non-organic"]:
            intended_use = "haying-non-irrigated-non-organic"
        elif interval_code in practices["haying-non-irrigated-certified"]:
            intended_use = "haying-non-irrigated-certified"
        elif interval_code in practices["haying-non-irrigated-transitional"]:
            intended_use = "haying-non-irrigated-transitional"

        rates_df = pd.read_csv(
            f"./rates/{state_name.lower()}/{state_name}-{year}-{intended_use}-{intended_use_coverage_level_mapping[intended_use]}-rates.csv"
        )
        rates_df = rates_df[
            (rates_df["State Code"] == state_code)
            & (rates_df["County Code"] == county_code)
            & (rates_df["CPC Grid Code"] == grid_code)
        ]

        interval_rates[interval_code] = {
            "premium_rate": get_premium_rate(
                year, state, county_code, grid_code, interval_code
            ),
            "county_base": rates_df.iloc[0]["County Base Value"],
            "subsidy_level": rates_df.iloc[0]["Subsidy Level"],
            "max_interval_percent": rates_df.iloc[0]["Maximum Interval Percent"],
        }

    return interval_rates


def get_subsidy(year, state, county_code):
    state_code = state["state_code"]
    state_name = state["state_name"]
    rates_df = pd.read_csv(
        f"./rates/{state_name.lower()}/{state_name}-{year}-grazing-70-rates.csv"
    )
    rates_df = rates_df[
        (rates_df["State Code"] == state_code)
        & (rates_df["County Code"] == county_code)
    ]
    return rates_df.iloc[0]["Subsidy Level"]


def get_indices(year, grid_code, interval_codes, state_name):
    grid_df = pd.read_csv(f"./grids/{state_name.lower()}/grid-{grid_code}.csv")

    grid_df = grid_df[grid_df["Year"] == year]

    interval_indices = {}
    for interval_code in interval_codes:

        interval_indices[interval_code] = {
            "CPC_index": grid_df[
                grid_df["Interval"] == adjusted_interval_codes[interval_code]
            ].iloc[0]["CPC Index"],
            "CHIRPS_indices": grid_df[
                grid_df["Interval"] == adjusted_interval_codes[interval_code]
            ]["CHIRPS Index"].to_list(),
        }
    return interval_indices


def get_CPC_grid_proportions(state, county_code, grid_code):
    state_code = state["state_code"]
    state_name = state["state_name"]
    grid_df = pd.read_csv(
        f"./state-data/{state_name.lower()}/areas/cpc-county-areas.csv"
    )
    grid_df = grid_df[
        (grid_df["State Code"] == state_code)
        & (grid_df["County Code"] == county_code)
        & (grid_df["CPC Grid Code"] == grid_code)
    ]
    return grid_df["Proportion"].iloc[0]


def get_CHIRPS_grid_proportions(state, county_code, grid_code):
    state_code = state["state_code"]
    state_name = state["state_name"]
    CHIRPS_county_df = pd.read_csv(
        f"./state-data/{state_name.lower()}/areas/chirps-county-areas.csv"
    )
    CHIRPS_county_df = CHIRPS_county_df[
        (CHIRPS_county_df["State Code"] == state_code)
        & (CHIRPS_county_df["County Code"] == county_code)
        & (CHIRPS_county_df["CPC Grid Code"] == grid_code)
    ]

    CPC_grid_area = CHIRPS_county_df.iloc[0]["Total Area"]
    proportions = CHIRPS_county_df["Proportion"].to_list()

    CPC_county_df = pd.read_csv(
        f"./state-data/{state_name.lower()}/areas/cpc-county-areas.csv"
    )
    county_area = CPC_county_df[
        (CPC_county_df["State Code"] == state_code)
        & (CPC_county_df["County Code"] == county_code)
    ]["Area"].sum()

    CHIRPS_county_proportions = []
    for proportion in proportions:
        CHIRPS_county_proportions.append((proportion * CPC_grid_area) / county_area)

    return CHIRPS_county_proportions


def get_CPC_payout(
    coverage_level,
    area,
    grid_info,
    intervals,
    productivity_factor,
    county_grids,
    subsidy_level,
):
    print(f"CPC: Coverage Level: {coverage_level}")
    if coverage_level == 0.65:
        coverage_level = 0.7

    policy_protection = {}
    total_liability = 0
    for grid_code in county_grids:
        CPC_grid_proportion = grid_info[grid_code]["CPC_grid_proportion"]
        CPC_county_area = area * CPC_grid_proportion

        policy_protection[grid_code] = {}
        for interval_code in intervals:
            county_base = grid_info[grid_code]["rates"][interval_code]["county_base"]
            dollar_protection = county_base * coverage_level * productivity_factor
            policy_protection[grid_code][interval_code] = (
                dollar_protection * CPC_county_area * 0.5
            )
            total_liability += policy_protection[grid_code][interval_code]

    total_policy_premium = 0
    for grid_code in county_grids:
        CPC_grid_proportion = grid_info[grid_code]["CPC_grid_proportion"]
        CPC_county_area = area * CPC_grid_proportion

        for interval_code in intervals:
            interval_premium = grid_info[grid_code]["rates"][interval_code][
                "premium_rate"
            ][coverage_level * 100]
            county_base = grid_info[grid_code]["rates"][interval_code]["county_base"]
            dollar_protection = county_base * coverage_level * productivity_factor
            total_policy_premium += (
                dollar_protection * interval_premium * CPC_county_area * 0.5
            )

    premium_subsidy = total_policy_premium * subsidy_level
    actual_premium = total_policy_premium - premium_subsidy

    indemnity_payout = 0
    for grid_code in county_grids:
        for interval_code in intervals:
            CPC_index = grid_info[grid_code]["indices"][interval_code]["CPC_index"]
            if CPC_index < coverage_level:
                payment_calculcation_factor = (
                    coverage_level - CPC_index
                ) / coverage_level
                indemnity_payout += (
                    payment_calculcation_factor
                    * policy_protection[grid_code][interval_code]
                )
            else:
                continue

    print(round(indemnity_payout, 2))

    return {
        "total_premium": round(total_policy_premium, 2),
        "premium_subsidy": round(premium_subsidy, 2),
        "actual_premium": round(actual_premium, 2),
        "indemnity_payout": round(indemnity_payout, 2),
        "total_liability": round(total_liability, 2),
    }


def get_CHIRPS_payout(
    coverage_level,
    area,
    grid_info,
    intervals,
    productivity_factor,
    county_grids,
    subsidy_level,
):
    print(f"CHIRPS: Coverage Level: {coverage_level}")

    if coverage_level == 0.65:
        coverage_level = 0.7

    policy_protection = {}
    total_liability = 0
    for grid_code in county_grids:
        CHIRPS_grid_proportions = grid_info[grid_code]["CHIRPS_grid_proportions"]
        policy_protection[grid_code] = {}

        for CHIRPS_grid_proportion in CHIRPS_grid_proportions:
            CHIRPS_county_area = area * CHIRPS_grid_proportion

            for interval_code in intervals:
                if interval_code not in policy_protection[grid_code]:
                    policy_protection[grid_code][interval_code] = []

                county_base = grid_info[grid_code]["rates"][interval_code][
                    "county_base"
                ]
                dollar_protection = county_base * coverage_level * productivity_factor

                policy_protection[grid_code][interval_code].append(
                    dollar_protection * CHIRPS_county_area * 0.5
                )
                total_liability += dollar_protection * CHIRPS_county_area * 0.5

    total_policy_premium = 0
    for grid_code in county_grids:
        CHIRPS_grid_proportions = grid_info[grid_code]["CHIRPS_grid_proportions"]

        for CHIRPS_grid_proportion in CHIRPS_grid_proportions:
            CHIRPS_county_area = area * CHIRPS_grid_proportion

            for interval_code in intervals:
                interval_premium = grid_info[grid_code]["rates"][interval_code][
                    "premium_rate"
                ][coverage_level * 100]
                county_base = grid_info[grid_code]["rates"][interval_code][
                    "county_base"
                ]
                dollar_protection = county_base * coverage_level * productivity_factor
                total_policy_premium += (
                    dollar_protection * interval_premium * CHIRPS_county_area * 0.5
                )

    premium_subsidy = total_policy_premium * subsidy_level
    actual_premium = total_policy_premium - premium_subsidy

    indemnity_payout = 0
    for grid_code in county_grids:
        for interval_code in intervals:
            CHIRPS_indices = grid_info[grid_code]["indices"][interval_code][
                "CHIRPS_indices"
            ]

            for index, CHIRPS_index in enumerate(CHIRPS_indices):
                if CHIRPS_index < coverage_level:
                    payment_calculcation_factor = (
                        coverage_level - CHIRPS_index
                    ) / coverage_level
                    indemnity_payout += (
                        payment_calculcation_factor
                        * policy_protection[grid_code][interval_code][index]
                    )
                else:
                    continue

    print(round(indemnity_payout, 2))

    return {
        "total_premium": round(total_policy_premium, 2),
        "premium_subsidy": round(premium_subsidy, 2),
        "actual_premium": round(actual_premium, 2),
        "indemnity_payout": round(indemnity_payout, 2),
        "total_liability": round(total_liability, 2),
    }


def calculate_payout(year, state, county, productivity_factor):
    county_code = int(county["county_code"])
    state_code = state["state_code"]
    state_name = state["state_name"]
    intervals = get_index_intervals(year, state, county_code)
    if intervals is None:
        return [
            {
                "year": year,
                "state_code": state_code,
                "state_name": state_name,
                "county_code": county_code,
                "county_name": county["county_name"],
                "intervals": "",
                "coverage_level": "",
                "area": "",
                "CPC_total_premium": "",
                "CPC_premium_subsidy": "",
                "CPC_actual_premium": "",
                "CPC_indemnity_payout": "",
                "CHIRPS_total_premium": "",
                "CHIRPS_premium_subsidy": "",
                "CHIRPS_actual_premium": "",
                "CHIRPS_indemnity_payout": "",
                "relative_difference": "",
            }
        ]

    total_acres = get_total_acres(year, state, county_code)
    subsidy_level = get_subsidy(year, state, county_code)
    county_grids = county["grids"]

    grid_info = {}
    for grid_code in county_grids:
        rates = get_rates(year, state, county_code, grid_code, intervals)
        indices = get_indices(year, grid_code, intervals, state_name)
        CPC_grid_proportion = get_CPC_grid_proportions(state, county_code, grid_code)
        CHIRPS_grid_proportions = get_CHIRPS_grid_proportions(
            state, county_code, grid_code
        )

        grid_info[grid_code] = {
            "rates": rates,
            "indices": indices,
            "CPC_grid_proportion": CPC_grid_proportion,
            "CHIRPS_grid_proportions": CHIRPS_grid_proportions,
        }

    data = []
    for coverage_level, area in total_acres.items():
        CPC_payout = get_CPC_payout(
            coverage_level,
            area,
            grid_info,
            intervals,
            productivity_factor,
            county_grids,
            subsidy_level,
        )
        CHIRPS_payout = get_CHIRPS_payout(
            coverage_level,
            area,
            grid_info,
            intervals,
            productivity_factor,
            county_grids,
            subsidy_level,
        )

        data.append(
            {
                "year": year,
                "state_code": state_code,
                "state_name": state_name,
                "county_code": county_code,
                "county_name": county["county_name"],
                "intervals": ",".join(str(num) for num in intervals),
                "coverage_level": coverage_level,
                "area": area,
                "CPC_total_premium": CPC_payout["total_premium"],
                "CPC_premium_subsidy": CPC_payout["premium_subsidy"],
                "CPC_actual_premium": CPC_payout["actual_premium"],
                "CPC_indemnity": CPC_payout["indemnity_payout"],
                "CPC_total_liability": CPC_payout["total_liability"],
                "CHIRPS_total_premium": CHIRPS_payout["total_premium"],
                "CHIRPS_premium_subsidy": CHIRPS_payout["premium_subsidy"],
                "CHIRPS_actual_premium": CHIRPS_payout["actual_premium"],
                "CHIRPS_indemnity": CHIRPS_payout["indemnity_payout"],
                "CHIRPS_total_liability": CHIRPS_payout["total_liability"],
                "relative_difference": (
                    0
                    if (
                        CPC_payout["indemnity_payout"]
                        + CHIRPS_payout["indemnity_payout"]
                    )
                    == 0
                    else (
                        CPC_payout["indemnity_payout"]
                        - CHIRPS_payout["indemnity_payout"]
                    )
                    / (
                        (
                            CPC_payout["indemnity_payout"]
                            + CHIRPS_payout["indemnity_payout"]
                        )
                        / 2
                    )
                ),
            }
        )

    return data


def get_counties(state_name):
    with open(
        f"./state-data/{state_name.lower()}/counties.json", encoding="utf-8"
    ) as file:
        county_data = json.load(file)
    return county_data


adjusted_interval_codes = {
    525: 625,
    526: 626,
    527: 627,
    528: 628,
    529: 629,
    530: 630,
    531: 631,
    532: 632,
    533: 633,
    534: 634,
    535: 635,
    565: 625,
    566: 626,
    567: 627,
    568: 628,
    569: 629,
    570: 630,
    571: 631,
    572: 632,
    573: 633,
    574: 634,
    575: 635,
    585: 625,
    586: 626,
    587: 627,
    588: 628,
    589: 629,
    590: 630,
    591: 631,
    592: 632,
    593: 633,
    594: 634,
    595: 635,
    425: 625,
    426: 626,
    427: 627,
    428: 628,
    429: 629,
    430: 630,
    431: 631,
    432: 632,
    433: 633,
    434: 634,
    435: 635,
    625: 625,
    626: 626,
    627: 627,
    628: 628,
    629: 629,
    630: 630,
    631: 631,
    632: 632,
    633: 633,
    634: 634,
    635: 635,
    # 0: 'No Practice Specified',
    655: 633,
    656: 633,
    657: 634,
    658: 634,
    659: 635,
    # 660: "GS-1 Dec - Jan Index Interval",
    # 661: "GS-2 Dec - Jan Index Interval",
    662: 625,
    663: 625,
    664: 626,
    665: 626,
    666: 627,
    667: 627,
    668: 628,
    669: 628,
    670: 629,
    671: 629,
    672: 630,
    673: 630,
    674: 631,
    675: 631,
    676: 632,
    677: 632,
    # 678: "GS-1 Sep - Mar Index Interval",
    # 679: "GS-2 Dec - Jun Index Interval",
    # 680: "GS-3 Mar - Sep Index Interval",
    # 681: "GS-4 Jun - Nov Index Interval"
}

practices = {
    "grazing": [625, 626, 627, 628, 629, 630, 631, 632, 633, 634, 635],
    "haying-irrigated": [425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435],
    "haying-non-irrigated-non-organic": [
        525,
        526,
        527,
        528,
        529,
        530,
        531,
        532,
        533,
        534,
        535,
    ],
    "haying-non-irrigated-certified": [
        565,
        566,
        567,
        568,
        569,
        570,
        571,
        572,
        573,
        574,
        575,
    ],
    "haying-non-irrigated-transitional": [
        585,
        586,
        587,
        588,
        589,
        590,
        591,
        592,
        593,
        594,
        595,
    ],
}

coverage_level_intended_use_mapping = {
    70: "grazing",
    75: "haying-irrigated",
    80: "haying-non-irrigated-non-organic",
    85: "haying-non-irrigated-certified",
    90: "haying-non-irrigated-transitional",
}

intended_use_coverage_level_mapping = {
    "grazing": 70,
    "haying-irrigated": 75,
    "haying-non-irrigated-non-organic": 80,
    "haying-non-irrigated-certified": 85,
    "haying-non-irrigated-transitional": 90,
}


def get_state_name(state_code):
    with open("./state-data/states.json", encoding="utf-8") as file:
        state_data = json.load(file)
    return state_data[str(state_code)]["name"]


start_year = 2011
end_year = 2021
state_code = 48
productivity_factor = 1

state = {"state_code": state_code, "state_name": get_state_name(state_code)}

counties = get_counties(state["state_name"])

for year in range(start_year, end_year + 1):
    print("Year: ", year)
    payouts = []
    for county in counties:
        print(county["county_name"])
        payouts.extend(calculate_payout(year, state, county, productivity_factor))

    payouts_df = pd.DataFrame(payouts)
    payouts_df.to_csv(
        f'./payouts/{state["state_name"].lower()}/{year}-payouts.csv', index=False
    )

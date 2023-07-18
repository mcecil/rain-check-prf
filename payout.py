import pandas as pd

def read_summary_of_business(year, state_code, county_code):
    headers = ["Commodity Year", "State Code", "State Name", "State Abbreviation", "County Code", "County Name", "Commodity Code", "Commodity Name", 
           "Insurance Plan Code", "Insurance Plan Abbreviation", "Coverage Type Code", "Coverage Level Percent", "Delivery ID", "Type Code", "Type Name",
           "Practice Code", "Practice Name", "Unit Structure Code", "Unit Structure Name", "Net Reporting Level Amount", "Reporting Level Type",
           "Liability Amount", "Total Premium Amount", "Subsidy Amount", "Indemnity Amount", "Loss Ratio", "Endorsed Commodity Reporting Level Amount"]
    sob_df = pd.read_csv(f'./summary-of-business/SOBSCCTPU{year % 100}.TXT', sep='|', header=None, names = headers)
    sob_df = sob_df[(sob_df["State Code"]==state_code)&(sob_df["County Code"]==county_code)&(sob_df["Insurance Plan Abbreviation"]=="RI")]\
            .sort_values(by=['Net Reporting Level Amount', "Practice Code"], ascending=[False, True])
    
    return sob_df


def get_index_intervals(year, state_code, county_code):
    sob_df = read_summary_of_business(year, state_code, county_code)

    if sob_df.shape[0] == 0:
        return None
    
    intervals = []
    for _, row in sob_df.iterrows():
        if len(intervals) == 2:
            break

        interval_code = row["Practice Code"]
        if interval_code > 635:
            continue
        
        intervals.append(interval_code)

    return intervals


def get_total_acres(year, state_code, county_code):
      sob_df = read_summary_of_business(year, state_code, county_code)
      return sob_df.groupby('Coverage Level Percent')['Net Reporting Level Amount'].sum().to_dict()


def get_county_grids(state_code, county_code):
    # create a county grid code csv
    rates_df = pd.read_csv(f'./rates/2022-rates.csv')
    rates_df = rates_df[(rates_df["State Code"]==state_code)&(rates_df["County Code"]==county_code)]
    return rates_df["CPC Grid Code"].unique().tolist()
    

def get_rates(year, state_code, county_code, grid_code, interval_codes):
    print(f"Year: {year}, State Code: {state_code}, County Code: {county_code}, Grid Code: {grid_code}, Interval Codes: {interval_codes}")
    rates_df = pd.read_csv(f'./rates/{year}-rates.csv')
    rates_df = rates_df[(rates_df["State Code"]==state_code)&(rates_df["County Code"]==county_code)&\
                        (rates_df["CPC Grid Code"]==grid_code)]
    rates = {
        "county_base": rates_df.iloc[0]["County Base Value"],
        "subsidy_level": rates_df.iloc[0]["Subsidy Level"],
        "max_interval_percent": rates_df.iloc[0]["Maximum Interval Percent"],
    }

    interval_rates = {}
    for interval_code in interval_codes:
        adjusted_interval_code = interval_code
        if  interval_code < 625:
            adjusted_interval_code = interval_code + 100

        interval_rates[interval_code] = {
            "premium_rate": rates_df[rates_df["Interval Code"]==adjusted_interval_code].iloc[0]["Premium Rate"]
        }

    rates["interval_premium"] = interval_rates
    return rates

def get_indices(year, grid_code, interval_codes):
    grid_df = pd.read_csv(f'./grid-data/grid-{grid_code}.csv')

    grid_df = grid_df[grid_df["Year"]==year]

    interval_indices = {}
    for interval_code in interval_codes:
        adjusted_interval_code = interval_code
        if  interval_code < 625:
            adjusted_interval_code = interval_code + 100

        interval_indices[interval_code]= {
            "CPC_index": grid_df[grid_df["Interval"]==adjusted_interval_code].iloc[0]["CPC Index"],
            "CHIRPS_indices": grid_df[grid_df["Interval"]==adjusted_interval_code]["CHIRPS Index"].to_list()
        }
    return interval_indices

def get_CPC_grid_proportions(state_code, county_code, grid_code):
    grid_df = pd.read_csv(f'./cpc-county-areas.csv')
    grid_df = grid_df[(grid_df["State Code"]==state_code)&(grid_df["County Code"]==county_code)&(grid_df["CPC Grid Code"]==grid_code)]
    return grid_df["Proportion"].iloc[0]

def get_CHIRPS_grid_proportions(state_code, county_code, grid_code):
    CHIRPS_county_df = pd.read_csv(f'./chirps-county-areas.csv')
    CHIRPS_county_df = CHIRPS_county_df[(CHIRPS_county_df["State Code"]==state_code)&\
                                        (CHIRPS_county_df["County Code"]==county_code)&\
                                        (CHIRPS_county_df["CPC Grid Code"]==grid_code)]
    
    CPC_grid_area = CHIRPS_county_df.iloc[0]["Total Area"]
    proportions = CHIRPS_county_df["Proportion"].to_list()

    CPC_county_df = pd.read_csv(f'./cpc-county-areas.csv')
    county_area = CPC_county_df[(CPC_county_df["State Code"]==state_code)&\
                                  (CPC_county_df["County Code"]==county_code)]["Area"].sum()

    CHIRPS_county_proportions = []
    for proportion in proportions:
        CHIRPS_county_proportions.append((proportion * CPC_grid_area) / county_area)

    return CHIRPS_county_proportions

def get_CPC_payout(coverage_level, area, grid_info, intervals, productivity_factor, county_grids):
    print(f"Coverage Level: {coverage_level}")
    rates = grid_info[next(iter(grid_info))]["rates"]
    dollar_protection = rates["county_base"] * coverage_level * productivity_factor

    policy_protection = {}
    for grid_code in county_grids:
        CPC_grid_proportion = grid_info[grid_code]["CPC_grid_proportion"]
        CPC_county_area = area * CPC_grid_proportion
        policy_protection[grid_code] = dollar_protection * CPC_county_area * 0.5

    total_policy_premium = 0
    for grid_code in county_grids:
        CPC_grid_proportion = grid_info[grid_code]["CPC_grid_proportion"]
        CPC_county_area = area * CPC_grid_proportion

        for interval_code in intervals:
            interval_premium = grid_info[grid_code]["rates"]["interval_premium"][interval_code]["premium_rate"]
            total_policy_premium += dollar_protection * interval_premium * CPC_county_area * 0.5
    
    premium_subsidy = total_policy_premium * rates["subsidy_level"]
    actual_premium = total_policy_premium - premium_subsidy
    
    indemnity_payout = 0
    for grid_code in county_grids:
        for interval_code in intervals:
            CPC_index = grid_info[grid_code]["indices"][interval_code]["CPC_index"]
            if CPC_index < coverage_level:
                payment_calculcation_factor = (coverage_level - CPC_index)/ coverage_level
                indemnity_payout += payment_calculcation_factor * policy_protection[grid_code]
            else:
                continue
        
    print(round(indemnity_payout, 2))

    return {
        "total_premium": round(total_policy_premium, 2),
        "premium_subsidy": round(premium_subsidy, 2),
        "actual_premium": round(actual_premium, 2),
        "indemnity_payout": round(indemnity_payout, 2),
    }


def get_CHIRPS_payout(coverage_level, area, grid_info, rates, intervals, productivity_factor, county_grids):
    dollar_protection = rates["county_base"] * coverage_level * productivity_factor

    policy_protection = {}
    for grid_code in county_grids:
        CPC_grid_proportions = grid_info[grid_code]["CHIRPS_grid_proportions"]

        CHIRPS_policy_protection = []
        for CHIRPS_grid_proportion in CPC_grid_proportions:
            CHIRPS_county_area = area * CHIRPS_grid_proportion
            CHIRPS_policy_protection.append(dollar_protection * CHIRPS_county_area * 0.5)
        
        policy_protection[grid_code] = CHIRPS_policy_protection

    total_policy_premium = 0
    for grid_code in county_grids:
        CPC_grid_proportions = grid_info[grid_code]["CHIRPS_grid_proportions"]
        
        CHIRPS_policy_protection = 0
        for CHIRPS_grid_proportion in CPC_grid_proportions:
            CHIRPS_county_area = area * CHIRPS_grid_proportion

            for interval_code in intervals:
                interval_premium = grid_info[grid_code]["rates"]["interval_premium"][interval_code]["premium_rate"]
                total_policy_premium += dollar_protection * interval_premium * CHIRPS_county_area * 0.5

    premium_subsidy = total_policy_premium * rates["subsidy_level"]
    actual_premium = total_policy_premium - premium_subsidy

    indemnity_payout = 0
    for grid_code in county_grids:
        for interval_code in intervals:
            CHIRPS_indices = grid_info[grid_code]["indices"][interval_code]["CHIRPS_indices"]
            
            for index, CHIRPS_index in enumerate(CHIRPS_indices):
                if CHIRPS_index < coverage_level:
                    payment_calculcation_factor = (coverage_level - CHIRPS_index)/ coverage_level
                    indemnity_payout += payment_calculcation_factor * policy_protection[grid_code][index]
                else:
                    continue
        
    print(round(indemnity_payout, 2))

    return {
        "total_premium": round(total_policy_premium, 2),
        "premium_subsidy": round(premium_subsidy, 2),
        "actual_premium": round(actual_premium, 2),
        "indemnity_payout": round(indemnity_payout, 2),
    }


def calculate_payout(year, state_code, county, productivity_factor):
    county_code = county["County Code"]
    intervals = get_index_intervals(year, state_code, county_code)
    if intervals is None:
        return [{
                "year": year,
                "state_code": state_code,
                "state_name": "Texas",
                "county_code": county_code,
                "county_name": county["County Name"],
                "intervals": '',
                "coverage_level": '',
                "area": '',
                "CPC_total_premium": '',
                "CPC_premium_subsidy": '',
                "CPC_actual_premium": '',
                "CPC_indemnity_payout": '',
                "CHIRPS_total_premium": '',
                "CHIRPS_premium_subsidy": '',
                "CHIRPS_actual_premium": '',
                "CHIRPS_indemnity_payout": '',
                "relative_difference": ''
            }]

    total_acres = get_total_acres(year, state_code, county_code)
    county_grids = get_county_grids(state_code, county_code)

    grid_info = {}
    for grid_code in county_grids:
        rates = get_rates(year, state_code, county_code, grid_code, intervals)
        indices = get_indices(year, grid_code, intervals)
        CPC_grid_proportion = get_CPC_grid_proportions(state_code, county_code, grid_code)
        CHIRPS_grid_proportions = get_CHIRPS_grid_proportions(state_code, county_code, grid_code)

        grid_info[grid_code] = {
            "rates": rates,
            "indices": indices,
            "CPC_grid_proportion": CPC_grid_proportion,
            "CHIRPS_grid_proportions": CHIRPS_grid_proportions
        }

    data = []
    for coverage_level, area in total_acres.items():
        CPC_payout = get_CPC_payout(coverage_level, area, grid_info, intervals, productivity_factor, county_grids)
        CHIRPS_payout = get_CHIRPS_payout(coverage_level, area, grid_info, rates, intervals, productivity_factor, county_grids)

        data.append({
                "year": year,
                "state_code": state_code,
                "state_name": "Texas",
                "county_code": county_code,
                "county_name": county["County Name"],
                "intervals": ','.join(str(num) for num in intervals),
                "coverage_level": coverage_level,
                "area": area,
                "CPC_total_premium": CPC_payout["total_premium"],
                "CPC_premium_subsidy": CPC_payout["premium_subsidy"],
                "CPC_actual_premium": CPC_payout["actual_premium"],
                "CPC_indemnity_payout": CPC_payout["indemnity_payout"],
                "CHIRPS_total_premium": CHIRPS_payout["total_premium"],
                "CHIRPS_premium_subsidy": CHIRPS_payout["premium_subsidy"],
                "CHIRPS_actual_premium": CHIRPS_payout["actual_premium"],
                "CHIRPS_indemnity_payout": CHIRPS_payout["indemnity_payout"],
                "relative_difference": 0 if (CPC_payout["indemnity_payout"] + CHIRPS_payout["indemnity_payout"]) == 0 else (CPC_payout["indemnity_payout"] - CHIRPS_payout["indemnity_payout"])/((CPC_payout["indemnity_payout"] + CHIRPS_payout["indemnity_payout"])/2)
            })

    return data

def get_counties(state_code):
    county_df = pd.read_csv(f'./rates/2022-rates.csv')
    county_df = county_df[county_df["State Code"] == state_code][["County Name","County Code"]].drop_duplicates()
    return county_df.to_dict('records')



interval_codes = {
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

year = 2021
state_code = 48
productivity_factor = 1

counties = get_counties(state_code)

payouts = []
for county in counties:
    print(county["County Name"])
    payouts.extend(calculate_payout(year, state_code, county, productivity_factor))

payouts_df = pd.DataFrame(payouts)
payouts_df.to_csv(f'./payouts/{year}-payouts-{productivity_factor}.csv', index=False)
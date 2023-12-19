import requests
import pandas as pd
import os
import time

states = {
    "Texas": 48
}

MAX_RETRIES = 9

webhook_url = os.getenv('DISCORD_WEBHOOK_URL')
if webhook_url is None:
    raise ValueError("DISCORD_WEBHOOK_URL environment variable not set")

def send_discord_alert(message):
    data = {"content": message}
    response = requests.post(webhook_url, json=data)
    response.raise_for_status()

def request_with_retry(api_url, timeout=10):
    for retry in range(MAX_RETRIES):
        try:
            response = requests.get(api_url, timeout=timeout)
            response.raise_for_status() # This will raise an exception for 4xx and 5xx responses

            # Check for 500 HTTP error
            if response.status_code != 500:
                return response.json()
            else:
                raise Exception("500 HTTP error")
        except (requests.Timeout, requests.ConnectionError, requests.RequestException) as e:
            print(f"Error occurred: {e}. Retrying in {2**retry} seconds...")
            time.sleep(2**retry)
    raise Exception(f"Failed after {MAX_RETRIES} retries.")

# Update the existing functions to use the request_with_retry function
def get_counties(state_code):
    api_url = f"https://public-rma.fpac.usda.gov/apps/PrfWebApi/PrfExternalStates/GetCountiesByState?stateCode={state_code}"
    response = request_with_retry(api_url)
    return response["counties"]

def get_grids(state_code, county_code):
    api_url = f"https://public-rma.fpac.usda.gov/apps/PrfWebApi/PrfExternalStates/GetSubCountiesByCountyAndState?stateCode={state_code}&countyCode={county_code}"
    response = request_with_retry(api_url)
    return response["subCounties"]

def get_rates(state_code, state_name, county_code, county_name, grid_code, year, irrigationTypeInfo, coverage_level):
    api_url = f'https://public-rma.fpac.usda.gov/apps/PrfWebApi/PrfExternalPricingRates/GetPricingRates?intervalType=BiMonthly&irrigationPracticeCode={irrigationTypeInfo["irrigationPracticeCode"]}&organicPracticeCode={irrigationTypeInfo["organicPracticeCode"]}&intendedUseCode={irrigationTypeInfo["intendedUseCode"]}&stateCode={state_code}&countyCode={county_code}&productivityFactor=100&insurableInterest=100&insuredAcres=100&sampleYear={year}&intervalPercentOfValues=%5B50%2C0%2C50%2C0%2C0%2C0%2C0%2C0%2C0%2C0%2C0%5D&coverageLevelPercent={coverage_level}&gridId={grid_code}'
    response = request_with_retry(api_url, timeout=60)
    pricing_rates = response["returnData"]["PricingRateRows"]
    rate_summary = response["returnData"]["PricingRateSummary"]

    data = []
    for pricing_rate in pricing_rates:
        interval_code = pricing_rate["IntervalCode"]
        premium_rate = pricing_rate["PremiumRate"]
        rainfall_index = pricing_rate["PercentOfNormal"]
        interval_measurement = pricing_rate["IntervalMeasurement"]
        avg_interval_measurement = pricing_rate["AverageIntervalMeasurement"]
        base_value = rate_summary["CountyBaseValue"]
        subsidy_level = rate_summary["SubsidyLevel"]
        max_acre_percent = rate_summary["MaximumAcrePercent"]

        data.append({
            "State Name": state_name,
            "State Code": state_code,
            "County Name": county_name,
            "County Code": county_code,
            "CPC Grid Code": grid_code,
            "Interval Code": interval_code,
            "Premium Rate": premium_rate,
            "County Base Value": base_value,
            "Subsidy Level": subsidy_level,
            "Maximum Interval Percent": max_acre_percent,
            "CPC Rainfall Index": rainfall_index,
            "CPC Interval Rainfall": interval_measurement,
            "CPC Interval Historical Average Rainfall": avg_interval_measurement
        })

    return data

# if len(sys.argv) > 1:
#         year = int(sys.argv[1])
# if len(sys.argv) > 2:
#         irrigationType = sys.argv[2]
# if len(sys.argv) > 3:
#         last_county = sys.argv[3]


irrigationTypes = {
    "grazing": {
        "irrigationPracticeCode": 997,
        "organicPracticeCode": 997,
        "intendedUseCode": "{:03d}".format(7)
    },
    "haying-irrigated": {
        "irrigationPracticeCode": "{:03d}".format(2),
        "organicPracticeCode": 997,
        "intendedUseCode": "{:03d}".format(30)
    },
    "haying-non-irrigated-non-organic": {
        "irrigationPracticeCode": "{:03d}".format(3),
        "organicPracticeCode": 997,
        "intendedUseCode": "{:03d}".format(30)
    },
    "haying-non-irrigated-certified": {
        "irrigationPracticeCode": "{:03d}".format(3),
        "organicPracticeCode": "{:03d}".format(1),
        "intendedUseCode": "{:03d}".format(30)
    },
    "haying-non-irrigated-transitional": {
        "irrigationPracticeCode": "{:03d}".format(3),
        "organicPracticeCode": "{:03d}".format(2),
        "intendedUseCode": "{:03d}".format(30)
    }
}

mapping = {
    70: "grazing",
    75: "haying-irrigated",
    80: "haying-non-irrigated-non-organic",
    85: "haying-non-irrigated-certified",
    90: "haying-non-irrigated-transitional"
}

errors= []
for coverage_level in range(70, 95, 5):
    for year in range(2007, 2022):
        last_county = ""
        irrigationType = mapping[coverage_level]

        for state_name, state_code in states.items():
            print("Year", year)
            print("State", state_name)
            print("Irrigation Type", irrigationType)
            print("Coverage Level", coverage_level)

            if os.path.isfile(f"./{state_name}-{year}-{irrigationType}-{coverage_level}-rates.csv"):
                df = pd.read_csv(f"./{state_name}-{year}-{irrigationType}-{coverage_level}-rates.csv")
                last_county = df["County Name"].iloc[-1]
                if state_code == 48 and last_county == "Zavala":
                    print("Skipping...")
                    continue
            try:
                counties = get_counties(state_code)

                skip = False
                if last_county != "":
                    skip = True
                    
                for county_info in counties:
                    data = []
                    county_name = county_info["Name"]
                    if skip:
                        greaterString = sorted([last_county, county_name], key=str.lower)[0] 
                        if greaterString != last_county:
                            continue
                        else:
                            skip = False
                            continue
                    county_code =  county_info["Code"]
                    print("County", county_name)
                    print("County Code", county_code)
                    grids = get_grids(state_code, county_code)

                    for grid_code in grids:
                        print("Grid", grid_code)
                        rates = get_rates(state_code, state_name, county_code, county_name, grid_code, year, irrigationTypes[irrigationType], coverage_level)
                        data += rates

                    rates_df = pd.DataFrame(data)
                    rates_df = rates_df[["State Name", "State Code", "County Name", "County Code", "CPC Grid Code", "Interval Code", "Premium Rate",
                                        "County Base Value", "Subsidy Level", "Maximum Interval Percent", "CPC Rainfall Index", "CPC Interval Rainfall",
                                        "CPC Interval Historical Average Rainfall"
                    ]]
                    rates_df.to_csv(f"./{state_name}-{year}-{irrigationType}-{coverage_level}-rates.csv", mode='a', header=False, index=False)
            except Exception as e:
                print(f"Error occurred: {e}")
                print("Year", year)
                print("State", state_name)
                print("County", county_name)
                print("Irrigation Type", irrigationType)
                print("Coverage Level", coverage_level)
                send_discord_alert(f"Error occurred: {e} \n Year: {year} \n State: {state_name} \n County: {county_name} \n Irrigation Type: {irrigationType} \
                                   \n Coverage Level: {coverage_level}")
                errors.append(f"./{state_name}-{year}-{irrigationType}-{coverage_level}-rates.csv")
                print("Sleeping for 5 minutes...")
                time.sleep(300)

print("Errors")
print(errors)
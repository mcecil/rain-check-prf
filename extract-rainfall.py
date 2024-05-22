import requests
import pandas as pd
import os
import time
import csv

states = {
    "Virginia": "51",
}

MAX_RETRIES = 9

# webhook_url = "https://discord.com/api/webhooks/1186517220541603924/J0LBUenq4mHCFaYRVe40s-XuuyhP1K_vrqjsErGPfA3is8baFYxjG2l2Rg2LRe2N8rAe"


# def send_discord_alert(message):
#     data = {"content": message}
#     response = requests.post(webhook_url, json=data)
#     response.raise_for_status()


def request_with_retry(api_url, timeout=10):
    for retry in range(MAX_RETRIES):
        try:
            response = requests.get(api_url, timeout=timeout)
            response.raise_for_status()  # This will raise an exception for 4xx and 5xx responses

            # Check for 500 HTTP error
            if response.status_code != 500:
                return response.json()
            else:
                raise Exception("500 HTTP error")
        except (
            requests.Timeout,
            requests.ConnectionError,
            requests.RequestException,
        ) as e:
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


def get_rainfall(state_code, state_name, county_code, county_name, grid_code):
    api_url = f"https://public-rma.fpac.usda.gov/apps/PrfWebApi/PrfExternalIndexes/GetIndexValues?intervalType=BiMonthly&sampleYearMinimum=1948&sampleYearMaximum=2023&gridId={grid_code}"
    response = request_with_retry(api_url, timeout=60)

    data = []
    for row in response["HistoricalIndexRows"]:
        year = row["Year"]
        for index in row["HistoricalIndexDataColumns"]:
            rainfall_index = index["PercentOfNormal"]
            interval_measurement = index["IntervalMeasurement"]
            avg_interval_measurement = index["AverageIntervalMeasurement"]
            interval_code = index["IntervalCode"]

            data.append(
                {
                    "Year": year,
                    "State Name": state_name,
                    "State Code": state_code,
                    "County Name": county_name,
                    "County Code": county_code,
                    "CPC Grid Code": grid_code,
                    "Interval Code": interval_code,
                    "CPC Rainfall Index": rainfall_index,
                    "CPC Interval Rainfall": interval_measurement,
                    "CPC Interval Historical Average Rainfall": avg_interval_measurement,
                }
            )

    return data


for state_name, state_code in states.items():
    print("State", state_name)

    try:
        counties = get_counties(state_code)

        headers = [
            "Year",
            "State Name",
            "State Code",
            "County Name",
            "County Code",
            "CPC Grid Code",
            "Interval Code",
            "CPC Rainfall Index",
            "CPC Interval Rainfall",
            "CPC Interval Historical Average Rainfall",
        ]

        filename = f"./{state_name}-rainfall.csv"

        # Check if the file exists
        if os.path.exists(filename):
            # If the file exists, read the first line and check if it matches the headers
            with open(filename, "r") as f:
                reader = csv.reader(f)
                first_line = next(reader)
                if first_line != headers:
                    # If the first line doesn't match the headers, read the rest of the file
                    rest_of_file = list(reader)
                    # Then write the headers and the rest of the file
                    with open(filename, "w", newline="") as f:
                        writer = csv.writer(f)
                        writer.writerow(headers)
                        writer.writerows(rest_of_file)
        else:
            # If the file doesn't exist, write the headers
            with open(filename, "w", newline="") as f:
                writer = csv.writer(f)
                writer.writerow(headers)

        if os.path.isfile(filename):
            df = pd.read_csv(filename)
            if df.empty:
                last_county = ""
            else:
                last_county = df["County Name"].iloc[-1]
                if last_county == counties[-1]["Name"]:
                    print("Skipping...")
                    continue

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
            county_code = county_info["Code"]
            print("County", county_name)
            print("County Code", county_code)
            grids = get_grids(state_code, county_code)

            for grid_code in grids:
                print("Grid", grid_code)
                rates = get_rainfall(
                    state_code, state_name, county_code, county_name, grid_code
                )
                data += rates

            rates_df = pd.DataFrame(data)

            # Now append the data to the file
            rates_df = rates_df[headers]
            rates_df.to_csv(filename, mode="a", header=False, index=False)
    except Exception as e:
        print(f"Error occurred: {e}")
        print("State", state_name)
        print("County", county_name)

        print("Sleeping for 5 minutes...")
        time.sleep(300)

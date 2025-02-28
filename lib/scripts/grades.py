import sys
sys.path.append('../dependencies')

import requests
import csv
import time
import os

# Define the URL
URL = "https://anex.us/grades/getData/"

# Define the headers
HEADERS = {
    "accept": "*/*",
    "accept-encoding": "gzip, deflate, br, zstd",
    "accept-language": "en-US,en;q=0.9",
    "connection": "keep-alive",
    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
    "origin": "https://anex.us",
    "referer": "https://anex.us/grades/?dept=CSCE&number=121",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
    "x-requested-with": "XMLHttpRequest"
}

# List of department-number pairs to query
# Omitting 285, 289, 291, 305, 413, 416, 426, 429 399, 481, 482, 485, 489, 491
COURSES = [
    {"dept": "CSCE", "number": "110"},
    {"dept": "CSCE", "number": "111"},
    {"dept": "CSCE", "number": "120"},
    {"dept": "CSCE", "number": "121"},
    {"dept": "CSCE", "number": "181"},
    {"dept": "CSCE", "number": "201"},
    {"dept": "CSCE", "number": "206"},
    {"dept": "CSCE", "number": "221"},
    {"dept": "CSCE", "number": "222"},
    {"dept": "CSCE", "number": "310"},
    {"dept": "CSCE", "number": "312"},
    {"dept": "CSCE", "number": "313"},
    {"dept": "CSCE", "number": "314"},
    {"dept": "CSCE", "number": "315"},
    {"dept": "CSCE", "number": "320"},
    {"dept": "CSCE", "number": "331"},
    {"dept": "CSCE", "number": "350"},
    {"dept": "CSCE", "number": "402"},
    {"dept": "CSCE", "number": "410"},
    {"dept": "CSCE", "number": "411"},
    {"dept": "CSCE", "number": "412"},
    {"dept": "CSCE", "number": "420"},
    {"dept": "CSCE", "number": "421"},
    {"dept": "CSCE", "number": "430"},
    {"dept": "CSCE", "number": "431"},
    {"dept": "CSCE", "number": "432"},
    {"dept": "CSCE", "number": "433"},
    {"dept": "CSCE", "number": "434"},
    {"dept": "CSCE", "number": "435"},
    {"dept": "CSCE", "number": "436"},
    {"dept": "CSCE", "number": "438"},
    {"dept": "CSCE", "number": "439"},
    {"dept": "CSCE", "number": "440"},
    {"dept": "CSCE", "number": "441"},
    {"dept": "CSCE", "number": "442"},
    {"dept": "CSCE", "number": "443"},
    {"dept": "CSCE", "number": "444"},
    {"dept": "CSCE", "number": "445"},
    {"dept": "CSCE", "number": "446"},
    {"dept": "CSCE", "number": "447"},
    {"dept": "CSCE", "number": "448"},
    {"dept": "CSCE", "number": "449"},
    {"dept": "CSCE", "number": "450"},
    {"dept": "CSCE", "number": "451"},
    {"dept": "CSCE", "number": "452"},
    {"dept": "CSCE", "number": "461"},
    {"dept": "CSCE", "number": "462"},
    {"dept": "CSCE", "number": "463"},
    {"dept": "CSCE", "number": "464"},
    {"dept": "CSCE", "number": "465"},
    {"dept": "CSCE", "number": "469"},
    {"dept": "CSCE", "number": "470"},
    {"dept": "CSCE", "number": "477"},
    {"dept": "CSCE", "number": "483"}
]

# CSV file name
CSV_FILE = "../data/grades.csv"

os.makedirs(os.path.dirname(CSV_FILE), exist_ok=True)

# Function to fetch data
def fetch_data(dept, number):
    response = requests.post(URL, headers=HEADERS, data={"dept": dept, "number": number})
    
    if response.status_code == 200:
        try:
            return response.json().get("classes", [])
        except ValueError:
            print(f"Error: Failed to decode JSON for {dept} {number}")
            return []
    else:
        print(f"Error: Failed to fetch {dept} {number}, Status Code: {response.status_code}")
        return []

# Function to write to CSV
def save_to_csv(data):
    if not data:
        print("No data to save.")
        return

    # Define CSV headers based on keys in data
    headers = data[0].keys()

    with open(CSV_FILE, mode="w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=headers)
        writer.writeheader()
        writer.writerows(data)

# Main function
def main():
    all_data = []
    
    for course in COURSES:
        print(f"Fetching data for {course['dept']} {course['number']}...")
        data = fetch_data(course["dept"], course["number"])
        all_data.extend(data)
        time.sleep(1)  # To avoid overwhelming the server

    if all_data:
        save_to_csv(all_data)
        print(f"Data saved to {CSV_FILE}")
    else:
        print("No data retrieved.")

if __name__ == "__main__":
    main()

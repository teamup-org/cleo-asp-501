import sys
sys.path.append('../dependencies')

import pandas as pd
import os

# Define GPA weight mapping
GPA_WEIGHTS = {"A": 4, "B": 3, "C": 2, "D": 1, "F": 0}

CSV_FILE = "../data/gpa.csv"

os.makedirs(os.path.dirname(CSV_FILE), exist_ok=True)

# Read CSV file
df = pd.read_csv("gpa.csv")

# Convert all relevant columns to integers (ignoring non-numeric columns)
grade_columns = ["A", "B", "C", "D", "F", "Q"]
df[grade_columns] = df[grade_columns].apply(pd.to_numeric)

# Group by dept, number, prof, year, and semester
grouped = df.groupby(["dept", "number", "prof", "year", "semester"]).sum().reset_index()

# Calculate new GPA
def calculate_gpa(row):
    total_students = sum(row[col] for col in GPA_WEIGHTS)  # Only count A, B, C, D, F
    total_points = sum(row[col] * GPA_WEIGHTS[col] for col in GPA_WEIGHTS)
    
    if total_students == 0:
        return None  # Avoid division by zero
    return round(total_points / total_students, 3)

# Apply the GPA calculation
grouped["gpa"] = grouped.apply(calculate_gpa, axis=1)

# Save the cleaned data
grouped.to_csv(CSV_FILE, index=False)

print("Aggregated data saved to gpa.csv")

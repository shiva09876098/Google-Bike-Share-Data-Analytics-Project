import pandas as pd
import numpy as np
from datetime import datetime
import sqlite

# List of file names (Replace with actual file paths if needed)
file_names = [
    "202008-divvy-tripdata.csv", "202009-divvy-tripdata.csv", "202010-divvy-tripdata.csv",
    "202011-divvy-tripdata.csv", "202012-divvy-tripdata.csv", "202101-divvy-tripdata.csv",
    "202102-divvy-tripdata.csv", "202103-divvy-tripdata.csv", "202104-divvy-tripdata.csv",
    "202105-divvy-tripdata.csv", "202106-divvy-tripdata.csv", "202107-divvy-tripdata.csv"
]

# Load and concatenate all CSV files into a single DataFrame
cyclistic_df = pd.concat([pd.read_csv(file) for file in file_names], ignore_index=True)

# Convert datetime columns
cyclistic_df['started_at'] = pd.to_datetime(cyclistic_df['started_at'])
cyclistic_df['ended_at'] = pd.to_datetime(cyclistic_df['ended_at'])

# Compute ride length in minutes
cyclistic_df['ride_length'] = (cyclistic_df['ended_at'] - cyclistic_df['started_at']).dt.total_seconds() / 60
cyclistic_df['ride_length'] = cyclistic_df['ride_length'].round(1)

# Extract date-related features
cyclistic_df['date'] = cyclistic_df['started_at'].dt.date
cyclistic_df['day_of_week'] = cyclistic_df['started_at'].dt.strftime('%A')
cyclistic_df['month'] = cyclistic_df['started_at'].dt.strftime('%B')
cyclistic_df['day'] = cyclistic_df['started_at'].dt.day
cyclistic_df['year'] = cyclistic_df['started_at'].dt.year
cyclistic_df['hour'] = cyclistic_df['started_at'].dt.hour

# Define seasons
seasons = {
    'Spring': [3, 4, 5], 'Summer': [6, 7, 8], 'Fall': [9, 10, 11], 'Winter': [12, 1, 2]
}
cyclistic_df['season'] = cyclistic_df['started_at'].dt.month.map(lambda x: next(k for k, v in seasons.items() if x in v))

# Define time of day
time_of_day = {
    'Night': range(0, 6), 'Morning': range(6, 12), 'Afternoon': range(12, 18), 'Evening': range(18, 24)
}
cyclistic_df['time_of_day'] = cyclistic_df['hour'].map(lambda x: next(k for k, v in time_of_day.items() if x in v))

# Drop unnecessary columns
columns_to_drop = ['ride_id', 'start_station_id', 'end_station_id', 'start_lat', 'start_lng', 'end_lat', 'end_lng']
cyclistic_df = cyclistic_df.drop(columns=columns_to_drop)

# Remove null values and duplicates
cyclistic_df = cyclistic_df.dropna().drop_duplicates()

# Remove invalid ride lengths
cyclistic_df = cyclistic_df[cyclistic_df['ride_length'] > 0]

# Save to SQLite database for SQL queries
conn = sqlite3.connect("cyclistic_data.db")
cyclistic_df.to_sql("cyclistic", conn, if_exists="replace", index=False)

# SQL query to retrieve the cleaned dataset
query = """
    SELECT date, day_of_week, month, day, year, hour, season, time_of_day, ride_length
    FROM cyclistic
"""
cyclistic_tableau = pd.read_sql(query, conn)

# Save final dataset to CSV
cyclistic_tableau.to_csv("cyclistic_data.csv", index=False)

# Close the database connection
conn.close()

print("CSV file 'cyclistic_data.csv' created successfully!")

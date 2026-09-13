import sqlite3
import pandas as pd

# Load the CSV
df = pd.read_csv("ecommerce_funnel_data.csv")

# Connect to SQLite database
conn = sqlite3.connect("ecommerce_funnel.db")

# Store the CSV as a table
df.to_sql("funnel_events", conn, if_exists="replace", index=False)

# Check that everything loaded correctly
count = pd.read_sql_query(
    "SELECT COUNT(*) AS total_sessions FROM funnel_events",
    conn
)

print("Database created successfully!")
print(count)

conn.close()
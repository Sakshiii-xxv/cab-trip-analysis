import csv
import random
from datetime import datetime, timedelta
import os

random.seed(42)
NUM_TRIPS = 1200
OUTPUT_DIR = "data/raw/"
os.makedirs(OUTPUT_DIR, exist_ok=True)

#DATA POOLS
cities_data = [
    (1, "Mumbai",    "Metro",  "Maharashtra", True),
    (2, "Delhi",     "Metro",  "Delhi",       True),
    (3, "Bengaluru", "Metro",  "Karnataka",   True),
    (4, "Hyderabad", "Metro",  "Telangana",   True),
    (5, "Pune",      "Tier-2", "Maharashtra", False),
    (6, "Jaipur",    "Tier-2", "Rajasthan",   False),
    (7, "Lucknow",   "Tier-2", "UP",          False),
    (8, "Surat",     "Tier-2", "Gujarat",     False),
]

vehicle_types   = ["Mini", "Mini", "Sedan", "Sedan", "SUV", "Auto"]
payment_methods = ["Cash", "Card", "Wallet", "Wallet", "Card"]
pickup_areas    = [
    "Airport", "Railway Station", "City Mall", "Suburb",
    "IT Park", "Hospital", "Hotel", "College", "Bus Stand", "Market"
]
cancel_reasons_driver = [
    "Passenger unreachable", "Wrong location entered",
    "Vehicle breakdown",     "Personal emergency"
]
cancel_reasons_passenger = [
    "Changed plans",    "Found alternative",
    "Driver rated poorly", "Price too high", "Long wait time"
]
surge_reasons = [
    "Peak hours", "Heavy rain", "Local event",
    "Weekend night", "Public holiday"
]
first_names = [
    "Ramesh","Sunil","Priya","Amit","Deepak","Kavita","Mohan",
    "Anita","Rajesh","Sanjay","Pooja","Vikas","Neha","Arjun",
    "Sunita","Ravi","Meena","Ajay","Sneha","Kiran"
]
last_names = [
    "Kumar","Singh","Sharma","Verma","Patel","Yadav","Gupta",
    "Joshi","Nair","Reddy","Mishra","Mehta","Kaur","Chauhan","Das"
]

#1. CITIES
with open(OUTPUT_DIR + "cities.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["city_id","city_name","zone","state","is_metro"])
    w.writerows(cities_data)
print("cities.csv — 8 rows")

#2. DRIVERS
drivers_data = []
for i in range(1, 51):
    city_id  = random.randint(1, 8)
    is_metro = cities_data[city_id - 1][4]
    rating   = round(
        random.uniform(3.6, 4.95) if is_metro
        else random.uniform(3.2, 4.80), 2)
    joined   = datetime(2021, 1, 1) + timedelta(days=random.randint(0, 900))
    name     = f"{random.choice(first_names)} {random.choice(last_names)}"
    drivers_data.append((
        i, name, city_id,
        random.choice(vehicle_types),
        rating,
        joined.strftime("%Y-%m-%d"),
        random.random() > 0.08
    ))

with open(OUTPUT_DIR + "drivers.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["driver_id","driver_name","city_id","vehicle_type",
                "rating","joined_date","is_active"])
    w.writerows(drivers_data)
print("drivers.csv — 50 rows")

#3. TRIPS
trips_data   = []
base_date    = datetime(2024, 1, 1)
hour_weights = [1,1,1,1,1,1,3,7,9,6,4,4,5,4,4,5,7,10,9,7,5,4,3,2]

for i in range(1, NUM_TRIPS + 1):
    driver     = random.choice(drivers_data)
    city_id    = driver[2]
    pickup_dt  = base_date + timedelta(
                     days    = random.randint(0, 364),
                     hours   = random.choices(range(24),
                                              weights=hour_weights)[0],
                     minutes = random.randint(0, 59))
    is_peak    = (pickup_dt.hour in range(7, 10) or
                  pickup_dt.hour in range(17, 21))
    is_weekend = pickup_dt.weekday() >= 5
    dist       = round(random.uniform(1.5, 45.0), 2)
    base_fare  = round(dist * random.uniform(11, 19), 2)
    use_surge  = (is_peak or is_weekend) and random.random() < 0.35
    surge_mult = round(random.uniform(1.3, 2.8), 2) if use_surge else 1.00
    final_fare = round(base_fare * surge_mult, 2)
    dropoff_dt = pickup_dt + timedelta(
                     minutes=int(dist * random.uniform(3.5, 7.0)))
    status     = random.choices(
                     ["Completed", "Cancelled", "No-show"],
                     weights=[75, 20, 5])[0]
    p_rating   = random.randint(3, 5) if status == "Completed" else ""

    trips_data.append((
        i, driver[0], city_id,
        random.choice(pickup_areas),
        random.choice(pickup_areas),
        pickup_dt.strftime("%Y-%m-%d %H:%M:%S"),
        dropoff_dt.strftime("%Y-%m-%d %H:%M:%S"),
        dist, base_fare, surge_mult, final_fare,
        random.choice(payment_methods),
        status, p_rating
    ))

with open(OUTPUT_DIR + "trips.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow([
        "trip_id","driver_id","city_id","pickup_area","dropoff_area",
        "pickup_time","dropoff_time","distance_km","base_fare",
        "surge_multiplier","final_fare","payment_method",
        "trip_status","passenger_rating"
    ])
    w.writerows(trips_data)
print(f"trips.csv — {NUM_TRIPS} rows")

#CANCELLATIONS
cancelled   = [t for t in trips_data if t[12] in ("Cancelled", "No-show")]
cancel_rows = []
for idx, t in enumerate(cancelled, 1):
    pdt      = datetime.strptime(t[5], "%Y-%m-%d %H:%M:%S")
    wait     = random.randint(1, 18)
    by       = random.choices(["Driver","Passenger"], weights=[40,60])[0]
    reason   = (random.choice(cancel_reasons_driver) if by == "Driver"
                else random.choice(cancel_reasons_passenger))
    cancel_rows.append((
        idx, t[0], by, reason,
        (pdt + timedelta(minutes=wait)).strftime("%Y-%m-%d %H:%M:%S"),
        wait
    ))

with open(OUTPUT_DIR + "cancellations.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["cancel_id","trip_id","cancelled_by","reason",
                "cancel_time","wait_minutes"])
    w.writerows(cancel_rows)
print(f"cancellations.csv — {len(cancel_rows)} rows")

#5. SURGE PRICING
surge_rows = []
sid = 1
days  = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
hours = [7, 8, 9, 17, 18, 19, 20, 23]

for city in cities_data:
    for day in days:
        for hour in hours:
            is_wknd = day in ["Saturday", "Sunday"]
            mult    = round(
                random.uniform(1.4, 2.8) if is_wknd or hour in [8,18,19]
                else random.uniform(1.1, 1.6), 2)
            surge_rows.append((
                sid, city[0], day, hour, mult,
                random.choice(surge_reasons)
            ))
            sid += 1

with open(OUTPUT_DIR + "surge_pricing.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["surge_id","city_id","day_of_week","hour_slot",
                "multiplier","reason"])
    w.writerows(surge_rows)
print(f"surge_pricing.csv — {len(surge_rows)} rows")
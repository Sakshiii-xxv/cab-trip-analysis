DROP TABLE IF EXISTS cancellations  CASCADE;
DROP TABLE IF EXISTS surge_pricing  CASCADE;
DROP TABLE IF EXISTS trips          CASCADE;
DROP TABLE IF EXISTS drivers        CASCADE;
DROP TABLE IF EXISTS cities         CASCADE;

-- TABLE 1: Cities
CREATE TABLE cities (
    city_id    SERIAL PRIMARY KEY,
    city_name  VARCHAR(50)  NOT NULL,
    zone       VARCHAR(30),
    state      VARCHAR(50),
    is_metro   BOOLEAN DEFAULT FALSE
);

-- TABLE 2: Drivers
CREATE TABLE drivers (
    driver_id    SERIAL PRIMARY KEY,
    driver_name  VARCHAR(100) NOT NULL,
    city_id      INT REFERENCES cities(city_id),
    vehicle_type VARCHAR(30),
    rating       NUMERIC(3,2),
    joined_date  DATE,
    is_active    BOOLEAN DEFAULT TRUE
);

-- TABLE 3: Trips (main fact table — sabse important)
CREATE TABLE trips (
    trip_id          SERIAL PRIMARY KEY,
    driver_id        INT REFERENCES drivers(driver_id),
    city_id          INT REFERENCES cities(city_id),
    pickup_area      VARCHAR(50),
    dropoff_area     VARCHAR(50),
    pickup_time      TIMESTAMP,
    dropoff_time     TIMESTAMP,
    distance_km      NUMERIC(6,2),
    base_fare        NUMERIC(8,2),
    surge_multiplier NUMERIC(4,2) DEFAULT 1.00,
    final_fare       NUMERIC(8,2),
    payment_method   VARCHAR(20),
    trip_status      VARCHAR(20),
    passenger_rating INT
);

-- TABLE 4: Surge Pricing
CREATE TABLE surge_pricing (
    surge_id    SERIAL PRIMARY KEY,
    city_id     INT REFERENCES cities(city_id),
    day_of_week VARCHAR(15),
    hour_slot   INT,
    multiplier  NUMERIC(4,2),
    reason      VARCHAR(60)
);

-- TABLE 5: Cancellations
CREATE TABLE cancellations (
    cancel_id    SERIAL PRIMARY KEY,
    trip_id      INT UNIQUE REFERENCES trips(trip_id),
    cancelled_by VARCHAR(20),
    reason       VARCHAR(120),
    cancel_time  TIMESTAMP,
    wait_minutes INT
);

-- Performance indexes
CREATE INDEX idx_trips_city    ON trips(city_id);
CREATE INDEX idx_trips_driver  ON trips(driver_id);
CREATE INDEX idx_trips_pickup  ON trips(pickup_time);
CREATE INDEX idx_trips_status  ON trips(trip_status);
CREATE INDEX idx_trips_surge   ON trips(surge_multiplier);

SELECT 'Tables + indexes successfully created!' AS status;
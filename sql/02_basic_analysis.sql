-- QUERY 1: Total trips aur revenue by city
SELECT
    c.city_name,
    c.zone,
    COUNT(t.trip_id) AS total_trips,
    COUNT(CASE WHEN t.trip_status = 'Completed' THEN 1 END) AS completed_trips,
    ROUND(SUM(t.final_fare), 2) AS total_revenue,
    ROUND(AVG(t.final_fare), 2) AS avg_fare_per_trip
FROM trips t
JOIN cities c ON t.city_id = c.city_id
GROUP BY c.city_name, c.zone
ORDER BY total_revenue DESC;

-- QUERY 2: Cancellation rate by city
WITH city_stats AS( 
	SELECT
	c.city_name,
	COUNT(t.trip_id) AS total_trips,
	COUNT(CASE WHEN t.trip_status = 'Cancelled' THEN 1 END) AS cancelled_trips,
	COUNT(CASE WHEN t.trip_status = 'No-show'   THEN 1 END) AS noshow_trips,
	ROUND(
		100.0 * COUNT(CASE WHEN t.trip_status IN ('Cancelled','No-show') THEN 1 END)
	    / COUNT(t.trip_id), 2
	    ) AS cancellation_rate_pct
	FROM trips t
	JOIN cities c ON t.city_id = c.city_id
	GROUP BY c.city_name
)
SELECT *
FROM city_stats 
WHERE cancellation_rate_pct > 20
ORDER BY cancellation_rate_pct DESC;

-- QUERY 3: Revenue by hour of day
SELECT
    EXTRACT(HOUR FROM pickup_time)  AS hour_of_day,
    COUNT(trip_id)                  AS total_trips,
    ROUND(SUM(final_fare), 2)       AS total_revenue,
    ROUND(AVG(final_fare), 2)       AS avg_fare
FROM trips
WHERE trip_status = 'Completed'
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- QUERY 4: Trips per driver + earnings
SELECT
    d.driver_name,
    d.vehicle_type,
    d.rating AS driver_rating,
    COUNT(t.trip_id) AS total_trips,
    COUNT(CASE WHEN t.trip_status = 'Completed' THEN 1 END) AS completed,
    ROUND(SUM(
        CASE WHEN t.trip_status = 'Completed' THEN t.final_fare ELSE 0 END
    ), 2) AS total_earnings
FROM drivers d
LEFT JOIN trips t ON d.driver_id = t.driver_id
GROUP BY d.driver_name, d.vehicle_type, d.rating
ORDER BY total_earnings DESC
LIMIT 20;

-- QUERY 5: Payment method breakdown
SELECT
    payment_method,
    COUNT(trip_id) AS total_trips,
    ROUND(SUM(final_fare), 2) AS total_revenue,
    ROUND(100.0 * COUNT(trip_id) / SUM(COUNT(trip_id)) OVER (), 2) AS pct_of_total
FROM trips
WHERE trip_status = 'Completed'
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- QUERY 6: Weekend vs Weekday comparison
SELECT
    CASE
        WHEN EXTRACT(DOW FROM pickup_time) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(trip_id) AS total_trips,
    ROUND(AVG(final_fare), 2) AS avg_fare,
    ROUND(AVG(distance_km), 2) AS avg_distance_km,
    ROUND(AVG(surge_multiplier), 2) AS avg_surge
FROM trips
WHERE trip_status = 'Completed'
GROUP BY day_type;
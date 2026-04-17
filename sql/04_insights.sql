-- INSIGHT 1: Best revenue hours (for operations team)
SELECT
    EXTRACT(HOUR FROM pickup_time) AS hour_slot,
    COUNT(trip_id) AS trips,
    ROUND(SUM(final_fare), 2) AS revenue,
    ROUND(AVG(surge_multiplier), 2) AS avg_surge
FROM trips
WHERE trip_status = 'Completed'
GROUP BY hour_slot
ORDER BY revenue DESC
LIMIT 5;

-- INSIGHT 2: Worst performing city (cancellation + low revenue)
SELECT
    c.city_name,
    COUNT(t.trip_id) AS total_trips,
    ROUND(SUM(
        CASE WHEN t.trip_status = 'Completed' THEN t.final_fare ELSE 0 END
    ), 2) AS actual_revenue,
    ROUND(SUM(t.final_fare), 2) AS potential_revenue,
    ROUND(
        100.0 * COUNT(CASE WHEN t.trip_status IN ('Cancelled','No-show') THEN 1 END)
        / COUNT(t.trip_id), 2
    ) AS cancellation_pct,
    ROUND(
        SUM(t.final_fare) - SUM(
            CASE WHEN t.trip_status = 'Completed' THEN t.final_fare ELSE 0 END
        ), 2
    ) AS revenue_lost_to_cancellations
FROM trips t
JOIN cities c ON t.city_id = c.city_id
GROUP BY c.city_name
ORDER BY revenue_lost_to_cancellations DESC;

-- INSIGHT 3: Vehicle type performance
SELECT
    d.vehicle_type,
    COUNT(t.trip_id) AS total_trips,
    ROUND(AVG(t.final_fare), 2) AS avg_fare,
    ROUND(AVG(t.distance_km), 2) AS avg_distance,
    ROUND(AVG(d.rating), 2) AS avg_driver_rating,
    ROUND(
        100.0 * COUNT(CASE WHEN t.trip_status IN ('Cancelled','No-show') THEN 1 END)
        / COUNT(t.trip_id), 2
    ) AS cancel_rate_pct
FROM trips t
JOIN drivers d ON t.driver_id = d.driver_id
GROUP BY d.vehicle_type
ORDER BY avg_fare DESC;

-- INSIGHT 4: Time-of-day surge demand heatmap data
SELECT
    TO_CHAR(pickup_time, 'Day') AS day_name,
    EXTRACT(HOUR FROM pickup_time) AS hour_slot,
    COUNT(trip_id) AS trip_volume,
    ROUND(AVG(surge_multiplier), 2) AS avg_surge
FROM trips
WHERE trip_status = 'Completed'
GROUP BY day_name, hour_slot
ORDER BY avg_surge DESC
LIMIT 20;

-- INSIGHT 5: Metro vs Tier-2 city comparison
SELECT
    c.zone,
    COUNT(DISTINCT c.city_id) AS cities,
    COUNT(t.trip_id) AS total_trips,
    ROUND(AVG(t.final_fare), 2) AS avg_fare,
    ROUND(AVG(t.distance_km), 2) AS avg_distance,
    ROUND(AVG(t.surge_multiplier), 2) AS avg_surge,
    ROUND(
        100.0 * COUNT(CASE WHEN t.trip_status IN ('Cancelled','No-show') THEN 1 END)
        / COUNT(t.trip_id), 2
    ) AS cancel_rate
FROM trips t
JOIN cities c ON t.city_id = c.city_id
GROUP BY c.zone;
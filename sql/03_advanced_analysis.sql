-- QUERY 1: Driver Revenue Ranking (RANK + WINDOW)
SELECT
    d.driver_name,
    c.city_name,
    d.vehicle_type,
    d.rating,
    ROUND(SUM(t.final_fare), 2) AS total_revenue,
    COUNT(t.trip_id) AS total_trips,
    RANK() OVER (
        PARTITION BY c.city_name
        ORDER BY SUM(t.final_fare) DESC
    ) AS revenue_rank_in_city,
    DENSE_RANK() OVER (
        ORDER BY SUM(t.final_fare) DESC
    ) AS overall_revenue_rank
FROM trips t
JOIN drivers d ON t.driver_id = d.driver_id
JOIN cities c  ON t.city_id   = c.city_id
WHERE t.trip_status = 'Completed'
GROUP BY d.driver_name, c.city_name, d.vehicle_type, d.rating
ORDER BY c.city_name, revenue_rank_in_city;

-- QUERY 2: Monthly Revenue Trend + LAG comparison
WITH monthly_revenue AS (
    SELECT
        c.city_name,
        DATE_TRUNC('month', t.pickup_time) AS month,
        ROUND(SUM(t.final_fare), 2) AS revenue
    FROM trips t
    JOIN cities c ON t.city_id = c.city_id
    WHERE t.trip_status = 'Completed'
    GROUP BY c.city_name, DATE_TRUNC('month', t.pickup_time)
)
SELECT
    city_name,
    TO_CHAR(month, 'Mon YYYY') AS month_label,
    revenue AS current_revenue,
    LAG(revenue) OVER (
        PARTITION BY city_name
        ORDER BY month
    ) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (
            PARTITION BY city_name ORDER BY month
        )) / NULLIF(LAG(revenue) OVER (
            PARTITION BY city_name ORDER BY month
        ), 0), 2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY city_name, month;

-- QUERY 3: Top 10% Drivers Revenue Contribution
WITH driver_earnings AS (
    SELECT
        d.driver_id,
        d.driver_name,
        ROUND(SUM(t.final_fare), 2) AS earnings
    FROM trips t
    JOIN drivers d ON t.driver_id = d.driver_id
    WHERE t.trip_status = 'Completed'
    GROUP BY d.driver_id, d.driver_name
),
ranked_drivers AS (
    SELECT *,
        NTILE(10) OVER (ORDER BY earnings DESC) AS decile
    FROM driver_earnings
)
SELECT
    CASE WHEN decile = 1 THEN 'Top 10%' ELSE 'Bottom 90%' END AS driver_segment,
    COUNT(*) AS driver_count,
    ROUND(SUM(earnings), 2) AS segment_revenue,
    ROUND(
        100.0 * SUM(earnings) / SUM(SUM(earnings)) OVER (), 2
    ) AS revenue_share_pct
FROM ranked_drivers
GROUP BY CASE WHEN decile = 1 THEN 'Top 10%' ELSE 'Bottom 90%' END;

-- QUERY 4: Surge Pricing Revenue Impact
SELECT
    CASE
        WHEN surge_multiplier = 1.00 THEN 'Normal Fare'
        WHEN surge_multiplier < 1.5  THEN 'Low Surge (1.0–1.5x)'
        WHEN surge_multiplier < 2.0  THEN 'Medium Surge (1.5–2.0x)'
        ELSE 'High Surge (2.0x+)'
    END AS surge_category,
    COUNT(trip_id) AS trips,
    ROUND(SUM(final_fare), 2) AS revenue,
    ROUND(
        100.0 * COUNT(trip_id) / SUM(COUNT(trip_id)) OVER (), 2
    ) AS trip_share_pct,
    ROUND(
        100.0 * SUM(final_fare) / SUM(SUM(final_fare)) OVER (), 2
    ) AS revenue_share_pct
FROM trips
WHERE trip_status = 'Completed'
GROUP BY surge_category
ORDER BY revenue DESC;

-- QUERY 5: Pickup Zone Demand vs Supply Gap
WITH zone_demand AS (
    SELECT
        pickup_area,
        COUNT(trip_id) AS total_requests,
        COUNT(CASE WHEN trip_status = 'Completed' THEN 1 END) AS fulfilled,
        COUNT(CASE WHEN trip_status IN ('Cancelled','No-show') THEN 1 END) AS unfulfilled
    FROM trips
    GROUP BY pickup_area
),
zone_gap AS (
    SELECT *,
        ROUND(100.0 * unfulfilled / total_requests, 2) AS gap_pct,
        RANK() OVER (ORDER BY unfulfilled DESC) AS gap_rank
    FROM zone_demand
)
SELECT
    pickup_area AS zone,
    total_requests,
    fulfilled,
    unfulfilled,
    gap_pct AS supply_gap_pct,
    CASE
        WHEN gap_pct >= 40 THEN '🔴 Critical Gap'
        WHEN gap_pct >= 25 THEN '🟡 Moderate Gap'
        ELSE '🟢 Healthy'
    END AS zone_health
FROM zone_gap
ORDER BY gap_pct DESC;

-- QUERY 6: Running Total Revenue (Cumulative)
WITH daily_revenue AS (
    SELECT
        DATE(pickup_time) AS trip_date,
        ROUND(SUM(final_fare), 2) AS daily_revenue
    FROM trips
    WHERE trip_status = 'Completed'
    GROUP BY DATE(pickup_time)
)
SELECT
    trip_date,
    daily_revenue,
    ROUND(SUM(daily_revenue) OVER (
        ORDER BY trip_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_revenue,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY trip_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7day_avg
FROM daily_revenue
ORDER BY trip_date;

-- QUERY 7: Cancellation Pattern — Who Cancels More?
WITH cancel_details AS (
    SELECT
        cn.cancelled_by,
        cn.reason,
        t.trip_status,
        c.city_name,
        cn.wait_minutes
    FROM cancellations cn
    JOIN trips t  ON cn.trip_id = t.trip_id
    JOIN cities c ON t.city_id = c.city_id
)
SELECT
    cancelled_by,
    reason,
    COUNT(*) AS cancel_count,
    ROUND(AVG(wait_minutes), 1) AS avg_wait_before_cancel,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY cancelled_by), 2
    ) AS pct_within_canceller
FROM cancel_details
GROUP BY cancelled_by, reason
ORDER BY cancelled_by, cancel_count DESC;

-- QUERY 8: Driver Rating vs Earnings Correlation
WITH driver_stats AS (
    SELECT
        d.driver_id,
        d.driver_name,
        d.rating,
        d.vehicle_type,
        COUNT(t.trip_id) AS total_trips,
        ROUND(SUM(t.final_fare), 2) AS total_earnings,
        ROUND(AVG(t.passenger_rating), 2) AS avg_passenger_rating
    FROM drivers d
    JOIN trips t ON d.driver_id = t.driver_id
    WHERE t.trip_status = 'Completed'
    GROUP BY d.driver_id, d.driver_name, d.rating, d.vehicle_type
)
SELECT
    driver_name,
    vehicle_type,
    rating AS platform_rating,
    avg_passenger_rating  AS passenger_given_rating,
    total_trips,
    total_earnings,
    CASE
        WHEN rating >= 4.5 THEN 'Elite'
        WHEN rating >= 4.0 THEN 'Good'
        WHEN rating >= 3.5 THEN 'Average'
        ELSE                    'Low'
    END AS rating_tier,
    NTILE(4) OVER (
        ORDER BY total_earnings DESC
    ) AS earnings_quartile
FROM driver_stats
ORDER BY total_earnings DESC;
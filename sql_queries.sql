-- =============================================
-- BUSINESS ANALYST ASSESSMENT - SQL QUERIES - POSTGRESQL
-- =============================================


-- Question 2: How many disconnect types are there?
SELECT 
    COUNT(DISTINCT "disconnectType") AS distinct_disconnect_types,
    STRING_AGG(DISTINCT "disconnectType", ', ') AS disconnect_types
FROM call_data_schema.raw_call_data;


-- Question 3: How many unique users are there?
SELECT 
    COUNT(DISTINCT "UserId") AS unique_users
FROM call_data_schema.raw_call_data;


-- Question 4: Top 10 users who took the most calls
SELECT 
    "UserId",
    COUNT(*) AS call_count
FROM call_data_schema.raw_call_data
GROUP BY "UserId"
ORDER BY call_count DESC
LIMIT 10;


-- Question 5: Average total handle time of a call (FIXED)
SELECT 
    ROUND(AVG("Total_Handle_Time")::numeric, 2) AS avg_handle_time_seconds,
    ROUND((AVG("Total_Handle_Time") / 60)::numeric, 2) AS avg_handle_time_minutes
FROM call_data_schema.raw_call_data
WHERE "Total_Handle_Time" IS NOT NULL;


-- Question 6: Top 10 users with disconnect type 'peer'
SELECT 
    "UserId",
    COUNT(*) AS peer_disconnect_count
FROM call_data_schema.raw_call_data
WHERE "disconnectType" = 'peer'
GROUP BY "UserId"
ORDER BY peer_disconnect_count DESC
LIMIT 10;


-- Question 7: Top 10 users with highest ratio of 'peer' disconnects
WITH user_stats AS (
    SELECT 
        "UserId",
        COUNT(*) AS total_calls,
        SUM(CASE WHEN "disconnectType" = 'peer' THEN 1 ELSE 0 END) AS peer_calls,
        SUM(CASE WHEN "disconnectType" = 'client' THEN 1 ELSE 0 END) AS client_calls,
        SUM(CASE WHEN "disconnectType" = 'transfer' THEN 1 ELSE 0 END) AS transfer_calls
    FROM call_data_schema.raw_call_data
    GROUP BY "UserId"
    HAVING COUNT(*) >= 10  -- Only users with significant call volume
)
SELECT 
    "UserId",
    total_calls,
    peer_calls,
    client_calls,
    transfer_calls,
    ROUND((peer_calls * 100.0 / total_calls)::numeric, 2) AS peer_ratio_percent,
    ROUND((client_calls * 100.0 / total_calls)::numeric, 2) AS client_ratio_percent,
    ROUND((transfer_calls * 100.0 / total_calls)::numeric, 2) AS transfer_ratio_percent
FROM user_stats
ORDER BY peer_ratio_percent DESC
LIMIT 10;


-- Question 8: Inbound queue calls per month
SELECT 
    EXTRACT(YEAR FROM "StartDateTime") AS year,
    EXTRACT(MONTH FROM "StartDateTime") AS month,
    TO_CHAR("StartDateTime", 'YYYY-MM') AS year_month,
    COUNT(*) AS call_count
FROM call_data_schema.raw_call_data
WHERE "StartDateTime" IS NOT NULL
GROUP BY year, month, year_month
ORDER BY year, month;

-- Question 9: Average number of calls taken during Q4 (per month)
WITH monthly_calls AS (
    SELECT 
        EXTRACT(YEAR FROM "StartDateTime") AS year,
        EXTRACT(MONTH FROM "StartDateTime") AS month,
        COUNT(*) AS call_count
    FROM call_data_schema.raw_call_data
    WHERE EXTRACT(MONTH FROM "StartDateTime") IN (10, 11, 12)
    GROUP BY year, month
)
SELECT 
    year,
    month,
    call_count,
    ROUND(AVG(call_count) OVER (PARTITION BY month)::numeric, 0) AS avg_monthly_calls_q4
FROM monthly_calls
ORDER BY year, month;

-- Question 10: Percentage difference in inbound calls (2023 vs 2024)
WITH yearly_totals AS (
    SELECT 
        EXTRACT(YEAR FROM "StartDateTime") AS year,
        COUNT(*) AS total_calls
    FROM call_data_schema.raw_call_data
    WHERE EXTRACT(YEAR FROM "StartDateTime") IN (2023, 2024)
    GROUP BY year
)
SELECT 
    MAX(CASE WHEN year = 2023 THEN total_calls END) AS calls_2023,
    MAX(CASE WHEN year = 2024 THEN total_calls END) AS calls_2024,
    ROUND(
        (
            MAX(CASE WHEN year = 2024 THEN total_calls END) -
            MAX(CASE WHEN year = 2023 THEN total_calls END)
        ) * 100.0 /
        MAX(CASE WHEN year = 2023 THEN total_calls END)::numeric,
    2) AS percentage_difference
FROM yearly_totals;


-- Question 11: Month & year with the most inbound queue calls
SELECT 
    EXTRACT(YEAR FROM "StartDateTime") AS year,
    EXTRACT(MONTH FROM "StartDateTime") AS month,
    TO_CHAR("StartDateTime", 'YYYY-MM') AS year_month,
    COUNT(*) AS call_count
FROM call_data_schema.raw_call_data
GROUP BY year, month, year_month
ORDER BY call_count DESC
LIMIT 1;

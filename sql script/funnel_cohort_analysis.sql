-- ============================================================
-- FUNNEL ANALYSIS & COHORT RETENTION ANALYSIS
-- E-Commerce Events | Cosmetics Shop | Oct 2019 - Feb 2020
-- Author: Samarth Gupta
-- Tool: PostgreSQL 18
-- ============================================================


-- ============================================================
-- SECTION 1: TABLE CREATION & DATA LOADING
-- ============================================================

-- Create master events table
CREATE TABLE IF NOT EXISTS ecommerce_events (
    event_time      TIMESTAMP,
    event_type      TEXT,
    product_id      BIGINT,
    category_id     BIGINT,
    category_code   TEXT,
    brand           TEXT,
    price           NUMERIC(10, 2),
    user_id         BIGINT,
    user_session    TEXT
);


-- Load October 2019
COPY ecommerce_events
FROM 'C:/PROJECTS/2_product_funnel/datasets/e_commerce_events_history/2019-Oct.csv'
DELIMITER ',' CSV HEADER;

-- Load November 2019
COPY ecommerce_events
FROM 'C:/PROJECTS/2_product_funnel/datasets/e_commerce_events_history/2019-Nov.csv'
DELIMITER ',' CSV HEADER;

-- Load December 2019
COPY ecommerce_events
FROM 'C:/PROJECTS/2_product_funnel/datasets/e_commerce_events_history/2019-Dec.csv'
DELIMITER ',' CSV HEADER;

-- Load January 2020
COPY ecommerce_events
FROM 'C:/PROJECTS/2_product_funnel/datasets/e_commerce_events_history/2020-Jan.csv'
DELIMITER ',' CSV HEADER;

-- Load February 2020
COPY ecommerce_events
FROM 'C:/PROJECTS/2_product_funnel/datasets/e_commerce_events_history/2020-Feb.csv'
DELIMITER ',' CSV HEADER;


-- Indexes for query performance
CREATE INDEX idx_user_id    ON ecommerce_events (user_id);
CREATE INDEX idx_event_time ON ecommerce_events (event_time);
CREATE INDEX idx_event_type ON ecommerce_events (event_type);

SELECT COUNT(*) AS total_rows FROM ecommerce_events;


-- ============================================================
-- SECTION 2: SCHEMA VALIDATION
-- ============================================================

-- Event type distribution
SELECT
    event_type,
    COUNT(*) AS event_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM ecommerce_events
GROUP BY event_type
ORDER BY event_count DESC;

-- Date range confirmation
SELECT
    MIN(event_time) AS earliest_event,
    MAX(event_time) AS latest_event
FROM ecommerce_events;

-- Unique users and sessions
SELECT
    COUNT(DISTINCT user_id)      AS unique_users,
    COUNT(DISTINCT user_session) AS unique_sessions
FROM ecommerce_events;

-- Null counts in category_code and brand
SELECT
    COUNT(*) FILTER (WHERE category_code IS NULL) AS null_category_code,
    COUNT(*) FILTER (WHERE brand IS NULL)         AS null_brand
FROM ecommerce_events;

-- Price sanity check
SELECT
    MIN(price)  AS min_price,
    MAX(price)  AS max_price,
    ROUND(AVG(price), 2) AS avg_price
FROM ecommerce_events
WHERE event_type = 'purchase';

-- Investigate negative prices on purchase events
SELECT COUNT(*) AS negative_price_purchases
FROM ecommerce_events
WHERE event_type = 'purchase'
AND price < 0;


-- ============================================================
-- SECTION 3: DATA CLEANING
-- ============================================================

-- Check for duplicate rows
SELECT
    event_time,
    event_type,
    product_id,
    user_id,
    user_session,
    COUNT(*) AS duplicate_count
FROM ecommerce_events
GROUP BY event_time, event_type, product_id, user_id, user_session
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 10;

-- Create deduplicated view for all analysis
CREATE OR REPLACE VIEW ecommerce_clean AS
SELECT DISTINCT
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session
FROM ecommerce_events;

-- Confirm clean row count
SELECT COUNT(*) AS clean_row_count
FROM ecommerce_clean;


-- ============================================================
-- SECTION 4: FUNNEL ANALYSIS
-- ============================================================

-- Unique users at each funnel stage
SELECT
    event_type,
    COUNT(DISTINCT user_id) AS unique_users
FROM ecommerce_clean
WHERE event_type IN ('view', 'cart', 'purchase')
GROUP BY event_type
ORDER BY unique_users DESC;

-- Stage-to-stage conversion and drop-off rates
WITH funnel AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS viewers,
        COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) AS carters,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchasers
    FROM ecommerce_clean
)
SELECT
    viewers,
    carters,
    purchasers,
    ROUND(carters    * 100.0 / viewers,  2) AS view_to_cart_rate,
    ROUND(purchasers * 100.0 / carters,  2) AS cart_to_purchase_rate,
    ROUND(purchasers * 100.0 / viewers,  2) AS overall_conversion_rate,
    ROUND((carters - purchasers) * 100.0 / carters, 2) AS cart_abandonment_rate
FROM funnel;

-- Revenue at risk from abandoned carts
WITH cart_value AS (
    SELECT ROUND(AVG(price), 2) AS avg_cart_price
    FROM ecommerce_clean
    WHERE event_type = 'cart'
    AND price > 0
),
abandoned AS (
    SELECT COUNT(DISTINCT user_id) AS abandoned_users
    FROM ecommerce_clean
    WHERE event_type = 'cart'
    AND user_id NOT IN (
        SELECT DISTINCT user_id
        FROM ecommerce_clean
        WHERE event_type = 'purchase'
    )
)
SELECT
    abandoned_users,
    avg_cart_price,
    ROUND(abandoned_users * avg_cart_price, 2) AS estimated_revenue_at_risk
FROM abandoned, cart_value;

-- Monthly funnel breakdown
SELECT
    DATE_TRUNC('month', event_time)                                        AS month,
    COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END)    AS viewers,
    COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END)    AS carters,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END)    AS purchasers,
    ROUND(COUNT(DISTINCT CASE WHEN event_type = 'cart'     THEN user_id END) * 100.0 /
          NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2) AS view_to_cart_rate,
    ROUND(COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
          NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END), 0), 2) AS cart_to_purchase_rate
FROM ecommerce_clean
GROUP BY DATE_TRUNC('month', event_time)
ORDER BY month;

-- Top 10 categories by conversion rate
SELECT
    category_code,
    COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS viewers,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchasers,
    ROUND(COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
          NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2) AS conversion_rate
FROM ecommerce_clean
WHERE category_code IS NOT NULL
GROUP BY category_code
HAVING COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) > 1000
ORDER BY conversion_rate DESC
LIMIT 10;

-- Top 10 brands by conversion rate
SELECT
    brand,
    COUNT(DISTINCT CASE WHEN event_type = 'view'     THEN user_id END) AS viewers,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchasers,
    ROUND(COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0 /
          NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0), 2) AS conversion_rate
FROM ecommerce_clean
WHERE brand IS NOT NULL
GROUP BY brand
HAVING COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) > 1000
ORDER BY conversion_rate DESC
LIMIT 10;

-- ============================================================
-- SECTION 5: COHORT RETENTION ANALYSIS
-- ============================================================

-- Step 1: Assign each user their cohort month (first activity month)
WITH user_cohorts AS (
    SELECT
        user_id,
        DATE_TRUNC('month', MIN(event_time)) AS cohort_month
    FROM ecommerce_clean
    GROUP BY user_id
),

-- Step 2: Get each user's active months
user_activities AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', event_time) AS activity_month
    FROM ecommerce_clean
),

-- Step 3: Calculate months since acquisition for each activity
user_retention AS (
    SELECT
        uc.user_id,
        uc.cohort_month,
        ua.activity_month,
        EXTRACT(YEAR FROM AGE(ua.activity_month, uc.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(ua.activity_month, uc.cohort_month)) AS months_since_acquisition
    FROM user_cohorts uc
    JOIN user_activities ua ON uc.user_id = ua.user_id
),

-- Step 4: Count cohort sizes
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM user_cohorts
    GROUP BY cohort_month
)

-- Step 5: Build retention matrix
SELECT
    TO_CHAR(ur.cohort_month, 'YYYY-MM')         AS cohort,
    cs.cohort_size,
    SUM(CASE WHEN months_since_acquisition = 0 THEN 1 ELSE 0 END) AS month_0,
    SUM(CASE WHEN months_since_acquisition = 1 THEN 1 ELSE 0 END) AS month_1,
    SUM(CASE WHEN months_since_acquisition = 2 THEN 1 ELSE 0 END) AS month_2,
    SUM(CASE WHEN months_since_acquisition = 3 THEN 1 ELSE 0 END) AS month_3,
    SUM(CASE WHEN months_since_acquisition = 4 THEN 1 ELSE 0 END) AS month_4,
    ROUND(SUM(CASE WHEN months_since_acquisition = 0 THEN 1 ELSE 0 END) * 100.0 / cs.cohort_size, 2) AS ret_month_0,
    ROUND(SUM(CASE WHEN months_since_acquisition = 1 THEN 1 ELSE 0 END) * 100.0 / cs.cohort_size, 2) AS ret_month_1,
    ROUND(SUM(CASE WHEN months_since_acquisition = 2 THEN 1 ELSE 0 END) * 100.0 / cs.cohort_size, 2) AS ret_month_2,
    ROUND(SUM(CASE WHEN months_since_acquisition = 3 THEN 1 ELSE 0 END) * 100.0 / cs.cohort_size, 2) AS ret_month_3,
    ROUND(SUM(CASE WHEN months_since_acquisition = 4 THEN 1 ELSE 0 END) * 100.0 / cs.cohort_size, 2) AS ret_month_4
FROM user_retention ur
JOIN cohort_sizes cs ON ur.cohort_month = cs.cohort_month
GROUP BY ur.cohort_month, cs.cohort_size
ORDER BY ur.cohort_month;

-- ============================================================
-- SECTION 6: SUPPORTING ANALYSIS
-- ============================================================

-- Repeat purchase rate
SELECT
    COUNT(DISTINCT user_id)                                    AS total_buyers,
    COUNT(DISTINCT CASE WHEN purchase_count > 1 
          THEN user_id END)                                    AS repeat_buyers,
    ROUND(COUNT(DISTINCT CASE WHEN purchase_count > 1 
          THEN user_id END) * 100.0 / 
          COUNT(DISTINCT user_id), 2)                          AS repeat_purchase_rate
FROM (
    SELECT
        user_id,
        COUNT(*) AS purchase_count
    FROM ecommerce_clean
    WHERE event_type = 'purchase'
    GROUP BY user_id
) purchase_counts;

-- Average time from first view to first purchase (days)
WITH first_view AS (
    SELECT user_id, MIN(event_time) AS first_view_time
    FROM ecommerce_clean
    WHERE event_type = 'view'
    GROUP BY user_id
),
first_purchase AS (
    SELECT user_id, MIN(event_time) AS first_purchase_time
    FROM ecommerce_clean
    WHERE event_type = 'purchase'
    GROUP BY user_id
)
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM 
        (fp.first_purchase_time - fv.first_view_time)) / 86400), 2) AS avg_days_to_first_purchase
FROM first_view fv
JOIN first_purchase fp ON fv.user_id = fp.user_id
WHERE fp.first_purchase_time >= fv.first_view_time;

-- Average session depth (events per session)
SELECT
    ROUND(AVG(events_per_session), 2) AS avg_session_depth
FROM (
    SELECT
        user_session,
        COUNT(*) AS events_per_session
    FROM ecommerce_clean
    GROUP BY user_session
) session_depths;

-- Monthly revenue trend
SELECT
    DATE_TRUNC('month', event_time)  AS month,
    COUNT(DISTINCT user_id)          AS unique_buyers,
    COUNT(*)                         AS total_purchases,
    ROUND(SUM(price), 2)             AS total_revenue,
    ROUND(AVG(price), 2)             AS avg_order_value
FROM ecommerce_clean
WHERE event_type = 'purchase'
AND price > 0
GROUP BY DATE_TRUNC('month', event_time)
ORDER BY month;

-- Top 10 brands by purchase volume
SELECT
    brand,
    COUNT(*)                AS total_purchases,
    COUNT(DISTINCT user_id) AS unique_buyers,
    ROUND(SUM(price), 2)    AS total_revenue,
    ROUND(AVG(price), 2)    AS avg_price
FROM ecommerce_clean
WHERE event_type = 'purchase'
AND brand IS NOT NULL
AND price > 0
GROUP BY brand
ORDER BY total_purchases DESC
LIMIT 10;
/* ============================================================================
   E-COMMERCE CUSTOMER FUNNEL ANALYSIS & DROP-OFF OPTIMIZATION
   SQL Analysis Script
   Dataset: ecommerce_funnel_data.csv  (import as table: funnel_events)
   Compatible with: MySQL 8+, PostgreSQL, SQL Server, SQLite (see notes)
   ============================================================================ */

-- ----------------------------------------------------------------------------
-- 0. TABLE CREATION (adjust types if your DB needs it, e.g. SQLite has no ENUM)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS funnel_events;

CREATE TABLE funnel_events (
    User_ID           VARCHAR(20),
    Session_ID        VARCHAR(20) PRIMARY KEY,
    Session_Date      DATE,
    Device            VARCHAR(20),      -- Mobile / Desktop / Tablet
    Traffic_Source    VARCHAR(30),      -- Organic Search / Paid Search / Social Media / Direct / Email
    Product_Category  VARCHAR(40),
    User_Type         VARCHAR(15),      -- New / Returning
    Homepage_Visit    TINYINT,          -- 1/0
    Search            TINYINT,
    Product_View      TINYINT,
    Add_to_Cart       TINYINT,
    Checkout          TINYINT,
    Purchase          TINYINT,
    Order_Value       DECIMAL(10,2)
);

-- Load data (MySQL example — adjust path/permissions, or use your DB's import wizard)
-- LOAD DATA INFILE '/path/to/ecommerce_funnel_data.csv'
-- INTO TABLE funnel_events
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;


-- ============================================================================
-- 1. OVERALL FUNNEL: STAGE-WISE VOLUME
-- ============================================================================
SELECT
    SUM(Homepage_Visit)  AS homepage_visits,
    SUM(Search)          AS searches,
    SUM(Product_View)    AS product_views,
    SUM(Add_to_Cart)     AS add_to_carts,
    SUM(Checkout)        AS checkouts,
    SUM(Purchase)        AS purchases
FROM funnel_events;


-- ============================================================================
-- 2. STAGE-WISE CONVERSION RATE & DROP-OFF RATE
--    Conversion = stage_n / stage_(n-1)      Drop-off = 1 - Conversion
-- ============================================================================
WITH stage_totals AS (
    SELECT
        SUM(Homepage_Visit) AS homepage_visits,
        SUM(Search)         AS searches,
        SUM(Product_View)   AS product_views,
        SUM(Add_to_Cart)    AS add_to_carts,
        SUM(Checkout)       AS checkouts,
        SUM(Purchase)       AS purchases
    FROM funnel_events
)
SELECT 'Homepage -> Search'        AS funnel_step,
       homepage_visits AS from_count, searches AS to_count,
       ROUND(searches * 1.0 / NULLIF(homepage_visits,0), 4) AS conversion_rate,
       ROUND(1 - searches * 1.0 / NULLIF(homepage_visits,0), 4) AS dropoff_rate
FROM stage_totals
UNION ALL
SELECT 'Search -> Product View',
       searches, product_views,
       ROUND(product_views * 1.0 / NULLIF(searches,0), 4),
       ROUND(1 - product_views * 1.0 / NULLIF(searches,0), 4)
FROM stage_totals
UNION ALL
SELECT 'Product View -> Add to Cart',
       product_views, add_to_carts,
       ROUND(add_to_carts * 1.0 / NULLIF(product_views,0), 4),
       ROUND(1 - add_to_carts * 1.0 / NULLIF(product_views,0), 4)
FROM stage_totals
UNION ALL
SELECT 'Add to Cart -> Checkout',
       add_to_carts, checkouts,
       ROUND(checkouts * 1.0 / NULLIF(add_to_carts,0), 4),
       ROUND(1 - checkouts * 1.0 / NULLIF(add_to_carts,0), 4)
FROM stage_totals
UNION ALL
SELECT 'Checkout -> Purchase',
       checkouts, purchases,
       ROUND(purchases * 1.0 / NULLIF(checkouts,0), 4),
       ROUND(1 - purchases * 1.0 / NULLIF(checkouts,0), 4)
FROM stage_totals;


-- ============================================================================
-- 3. CONVERSION BY DEVICE (the headline insight: mobile PV -> Cart drop-off)
-- ============================================================================
SELECT
    Device,
    SUM(Product_View)                                          AS product_views,
    SUM(Add_to_Cart)                                            AS add_to_carts,
    ROUND(SUM(Add_to_Cart) * 1.0 / NULLIF(SUM(Product_View),0), 4) AS pv_to_cart_rate,
    SUM(Checkout)                                               AS checkouts,
    SUM(Purchase)                                               AS purchases,
    ROUND(SUM(Purchase) * 1.0 / NULLIF(SUM(Homepage_Visit),0), 4) AS overall_conversion_rate
FROM funnel_events
GROUP BY Device
ORDER BY pv_to_cart_rate ASC;


-- ============================================================================
-- 4. CONVERSION BY TRAFFIC SOURCE
-- ============================================================================
SELECT
    Traffic_Source,
    SUM(Homepage_Visit)                                            AS sessions,
    SUM(Purchase)                                                  AS purchases,
    ROUND(SUM(Purchase) * 1.0 / NULLIF(SUM(Homepage_Visit),0), 4)  AS overall_conversion_rate,
    ROUND(AVG(CASE WHEN Purchase = 1 THEN Order_Value END), 2)     AS avg_order_value
FROM funnel_events
GROUP BY Traffic_Source
ORDER BY overall_conversion_rate DESC;


-- ============================================================================
-- 5. CONVERSION BY PRODUCT CATEGORY
-- ============================================================================
SELECT
    Product_Category,
    SUM(Product_View)                                              AS product_views,
    SUM(Purchase)                                                  AS purchases,
    ROUND(SUM(Purchase) * 1.0 / NULLIF(SUM(Product_View),0), 4)    AS view_to_purchase_rate,
    ROUND(AVG(CASE WHEN Purchase = 1 THEN Order_Value END), 2)     AS avg_order_value,
    ROUND(SUM(Order_Value), 2)                                     AS total_revenue
FROM funnel_events
GROUP BY Product_Category
ORDER BY total_revenue DESC;


-- ============================================================================
-- 6. NEW VS RETURNING USERS
-- ============================================================================
SELECT
    User_Type,
    SUM(Homepage_Visit)                                            AS sessions,
    SUM(Purchase)                                                  AS purchases,
    ROUND(SUM(Purchase) * 1.0 / NULLIF(SUM(Homepage_Visit),0), 4)  AS overall_conversion_rate,
    ROUND(AVG(CASE WHEN Purchase = 1 THEN Order_Value END), 2)     AS avg_order_value
FROM funnel_events
GROUP BY User_Type;


-- ============================================================================
-- 7. AVERAGE ORDER VALUE (overall + by device)
-- ============================================================================
SELECT
    ROUND(AVG(CASE WHEN Purchase = 1 THEN Order_Value END), 2) AS overall_avg_order_value
FROM funnel_events;

SELECT
    Device,
    ROUND(AVG(CASE WHEN Purchase = 1 THEN Order_Value END), 2) AS avg_order_value,
    ROUND(SUM(Order_Value), 2) AS total_revenue
FROM funnel_events
GROUP BY Device;


-- ============================================================================
-- 8. DEEP DIVE: WHY IS MOBILE PV -> CART WORSE?
--    Cross Device x Traffic Source x Category to isolate where the friction
--    concentrates (useful for the "why" behind the "what")
-- ============================================================================
SELECT
    Device,
    Product_Category,
    SUM(Product_View)                                              AS product_views,
    SUM(Add_to_Cart)                                                AS add_to_carts,
    ROUND(SUM(Add_to_Cart) * 1.0 / NULLIF(SUM(Product_View),0), 4)  AS pv_to_cart_rate
FROM funnel_events
GROUP BY Device, Product_Category
HAVING SUM(Product_View) >= 30          -- ignore statistically thin cells
ORDER BY Device, pv_to_cart_rate ASC;


-- ============================================================================
-- 9. MONTHLY TREND (are drop-offs improving/worsening over time?)
--    SQLite: replace DATE_FORMAT with strftime('%Y-%m', Session_Date)
-- ============================================================================
SELECT
    DATE_FORMAT(Session_Date, '%Y-%m')                              AS month,
    SUM(Homepage_Visit)                                             AS sessions,
    SUM(Purchase)                                                   AS purchases,
    ROUND(SUM(Purchase) * 1.0 / NULLIF(SUM(Homepage_Visit),0), 4)   AS conversion_rate
FROM funnel_events
GROUP BY month
ORDER BY month;

-- E-COMMERCE FUNNEL ANALYSIS
-- Query 1: Overall funnel stage volumes

SELECT
    SUM(Homepage_Visit) AS homepage_visits,
    SUM(Search) AS searches,
    SUM(Product_View) AS product_views,
    SUM(Add_to_Cart) AS add_to_carts,
    SUM(Checkout) AS checkouts,
    SUM(Purchase) AS purchases
FROM funnel_events;
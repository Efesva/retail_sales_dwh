-- Commercial KPIs on top of the star schema

-- 1. Monthly net sales, tickets and average ticket
SELECT d.year, d.month,
       ROUND(SUM(f.net_amount), 2)                                AS net_sales,
       COUNT(DISTINCT f.ticket_id)                                AS tickets,
       ROUND(SUM(f.net_amount) / COUNT(DISTINCT f.ticket_id), 2)  AS avg_ticket
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 2. Gross margin by category
SELECT p.category,
       ROUND(SUM(f.net_amount), 2)                                          AS net_sales,
       ROUND(SUM(f.net_amount - f.quantity * p.unit_cost), 2)               AS gross_margin,
       ROUND(100.0 * SUM(f.net_amount - f.quantity * p.unit_cost)
             / SUM(f.net_amount), 1)                                        AS margin_pct
FROM fact_sales f
JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY gross_margin DESC;

-- 3. Sales per shelf meter by category and store (space productivity)
WITH sales AS (
    SELECT f.store_key, f.product_key, d.year * 100 + d.month AS month_key,
           SUM(f.net_amount) AS net_sales
    FROM fact_sales f
    JOIN dim_date d ON d.date_key = f.date_key
    GROUP BY f.store_key, f.product_key, d.year * 100 + d.month
)
SELECT s.store_name, p.category,
       ROUND(SUM(sa.net_sales), 2)                          AS net_sales,
       ROUND(SUM(sh.shelf_meters), 2)                       AS shelf_meters,
       ROUND(SUM(sa.net_sales) / SUM(sh.shelf_meters), 2)   AS sales_per_meter
FROM fact_shelf_space sh
JOIN sales sa      ON sa.store_key = sh.store_key
                  AND sa.product_key = sh.product_key
                  AND sa.month_key = sh.month_key
JOIN dim_store s   ON s.store_key = sh.store_key
JOIN dim_product p ON p.product_key = sh.product_key
GROUP BY s.store_name, p.category
ORDER BY sales_per_meter DESC;

-- 4. Loyalty: share of sales and average ticket by customer segment
SELECT c.segment,
       ROUND(SUM(f.net_amount), 2)                                          AS net_sales,
       ROUND(100.0 * SUM(f.net_amount) / (SELECT SUM(net_amount) FROM fact_sales), 1) AS share_pct,
       ROUND(SUM(f.net_amount) / COUNT(DISTINCT f.ticket_id), 2)            AS avg_ticket
FROM fact_sales f
JOIN dim_customer c ON c.customer_key = f.customer_key
GROUP BY c.segment
ORDER BY net_sales DESC;

-- 5. Repeat purchase rate: customers with 2+ tickets in the period
SELECT ROUND(100.0 * SUM(CASE WHEN tickets >= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct
FROM (
    SELECT customer_key, COUNT(DISTINCT ticket_id) AS tickets
    FROM fact_sales
    GROUP BY customer_key
) t;

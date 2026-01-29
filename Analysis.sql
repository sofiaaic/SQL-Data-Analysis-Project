SELECT * FROM dim_customers
SELECT * FROM dim_products
SELECT * FROM fact_sales

-- 1. Changes Over Time Analysis
SELECT 
	YEAR(order_date) AS order_YEAR,
	MONTH(order_date) AS order_MONTH,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date) ASC;

SELECT 
  DATE_FORMAT(order_date, '%Y-%m-01') AS order_month,
  SUM(sales_amount) AS total_sales,
  COUNT(DISTINCT customer_key) AS total_customers,
  SUM(quantity) AS total_quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY DATE_FORMAT(order_date, '%Y-%m-01') ASC;

-- 2. Cumulative Analysis
-- Helps to understand whether our business is growing or declining

-- Calculate the total sales per month
-- and the running total of sales over time
SELECT
	m.order_date,
    m.total_sales,
    SUM(m.total_sales) OVER (PARTITION BY order_date ORDER BY m.order_date) AS running_total_sales
-- WINDOW FUNCTION
FROM 
(
SELECT 
	DATE_FORMAT(order_date, '%Y-%m-01') AS order_date, 
	SUM(sales_amount) AS total_sales
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
) AS m
ORDER BY m.order_date;

-- Same but w year
SELECT
	m.order_date,
    m.total_sales,
    SUM(m.total_sales) OVER (ORDER BY m.order_date) AS running_total_sales
-- WINDOW FUNCTION
FROM 
(
SELECT 
	DATE_FORMAT(order_date, '%Y-01-01') AS order_date, 
	SUM(sales_amount) AS total_sales
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-01-01')
) AS m
ORDER BY m.order_date;

-- Moving avg_price: promedio histórico del precio promedio anual
-- w year
SELECT
	m.order_date,
    m.total_sales,
    m.avg_price,
    SUM(m.total_sales) OVER (ORDER BY m.order_date) AS running_total_sales,
    AVG(avg_price) OVER (ORDER BY m.order_date) AS moving_average_price
-- WINDOW FUNCTION
FROM 
(
SELECT 
	DATE_FORMAT(order_date, '%Y-01-01') AS order_date, 
	SUM(sales_amount) AS total_sales,
    AVG(price) AS avg_price
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-01-01')
) AS m
ORDER BY m.order_date;

-- 3. Performance Analysis
-- Comparing current value to target value
-- Helps to measure success and compare performance

-- TASK: Analyze the yearly performance of products by comparing
-- each product's sales to both its average sales performance
-- and the previous year's sales.

-- CTE
WITH yearly_products_sales AS (
SELECT 
	YEAR(f.order_date) AS order_year,
    p.product_name,
    SUM(f.sales_amount) AS current_sales
FROM fact_sales f
LEFT JOIN dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name
ORDER BY YEAR(f.order_date) ASC
)
SELECT 
order_year, 
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
     ELSE 'Avg'
END AS avg_change,
-- YEAR BY YEAR ANALYSIS (long term trends analysis)
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
     ELSE 'No Change'
END AS py_change
FROM yearly_products_sales
ORDER BY product_name, order_year

-- The same but for month to month analysis (short term trends) 
WITH monthly_products_sales AS (
SELECT 
	MONTH(f.order_date) AS order_month,
    p.product_name,
    SUM(f.sales_amount) AS current_sales
FROM fact_sales f
LEFT JOIN dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY MONTH(f.order_date), p.product_name
ORDER BY MONTH(f.order_date) ASC
)
SELECT 
order_month, 
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
     ELSE 'Avg'
END AS avg_change,
-- MONTH BY MONTH ANALYSIS (short term trends analysis)
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_month) AS py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_month) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_month) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_month) < 0 THEN 'Decrease'
     ELSE 'No Change'
END AS py_change
FROM monthly_products_sales
ORDER BY product_name, order_month

-- 4. Part to whole analysis
-- Analyze how an individual part is performing compared to the overall,
-- allowing us to understand wich category has the greatest impact on the business

-- TASK: Wich categories contribute the most to overall sales
-- CTE 
WITH category_sales AS (
SELECT 
category, 
SUM(sales_amount) AS total_sales
FROM fact_sales f
LEFT JOIN dim_products p
ON p.product_key = f.product_key
GROUP BY category
)

SELECT
category, 
total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER())*100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC

-- 5. Data Segmentation 
-- Group the data based on a specific range
-- Helps understand the correlation between two measures.

-- TASK: Segment products into cost ranges and
-- count how many products fall into each segment.
WITH product_segments AS (
SELECT 
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
     WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
     ELSE 'above 1000' 
END cost_range
FROM dim_products
)

SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products

-- Group customers into three segments based on their spending behavior:
-- VIP: Customers with at least 12 months of history and spending more than 5,000
-- Regular: Customers with at least 12 months of history but spending 5,000 or less
-- New: Customers with a lifespan less than 12 months
-- And find the total number of customers by each group 
WITH customer_spending AS (
SELECT 
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM fact_sales f
LEFT JOIN dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key 
ORDER BY total_spending DESC
)

SELECT 
customer_segment,
COUNT(customer_key) AS total_customers
-- subquery
FROM ( 
SELECT
customer_key,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
	 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
     ELSE 'New'
END customer_segment
FROM customer_spending ) t
-- 
GROUP BY customer_segment
ORDER BY total_customers DESC


/*
============================================
CUSTOMER REPORT
============================================
Purpose:
	- This report consolidates key customer metrics and behaviors

Highlights:
	1. Gather essential fields such as names, ages, and transaction details
    2. Segments customers into categories (VIP, Regular, New) and age groups
    3. Aggregates customer-level metrics:
		- total orders 
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
	4. Calculate valuable KPIs:
		- recency (months since last order)
        - average order value 
        - average monthly spend
============================================
*/
CREATE VIEW report_customers AS 
-- 1. Base Query: Retrieves core columns from tables
WITH base_query AS (
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
    FROM fact_sales f
    LEFT JOIN dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
      AND c.birthdate IS NOT NULL
)
-- 2.- Customer Agreggations: Summarizes key metrics at the customer level
, customer_aggregation AS (
SELECT 
	customer_key,
	customer_number,
    customer_name,
	age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
	customer_key,
    customer_number,
    customer_name,
    age
)

SELECT 
	customer_key,
    customer_number,
    customer_name,
    age,
    CASE WHEN age < 20 THEN 'Under 20'
		 WHEN age between 20 and 29 THEN '20-29'
         WHEN age between 30 and 39 THEN '30-39'
         WHEN age between 40 and 49 THEN '40-49'
		 ELSE '50 and above'
	END AS age_group,
         
    CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		 WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		 ELSE 'New'
	END AS customer_segment,
    last_order_date,
    TIMESTAMPDIFF(MONTH, last_order_date,CURDATE()) AS recency,
	total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
    -- Compute Average order value (AOV)
    CASE WHEN total_orders = 0 THEN 0
		 ELSE total_sales/total_orders
    END AS avg_order_value,
    
-- Compute Average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales / lifespan
END AS avg_monthly_spend
FROM customer_aggregation
    

/*
============================================
PRODUCT REPORT
============================================
Purpose:
	- This report consolidates key product metrics and behaviors

Highlights:
	1. Gather essential fields such as product name, category, subcatecory, cost
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers
    3. Aggregates product-level metrics:
		- total orders 
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
	4. Calculate valuable KPIs:
		- recency (months since last sale)
        - average order revenue (AOR) 
        - average monthly revenue
============================================
*/
CREATE VIEW report_products AS 
-- 1. Base Query: Retrieves core columns fact_sales and dim_products
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM fact_sales f
    LEFT JOIN dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
)
-- 2.- Product Agreggations: Summarizes key metrics at the product level
, product_aggregation AS (
SELECT 
	product_key,
    product_name,
    category,
	subcategory,
    cost,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query
GROUP BY 
	product_key,
    product_name,
    category,
    subcategory,
    cost
)
-- Final query: Combines all product results in one output
SELECT 
	product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    TIMESTAMPDIFF(MONTH, last_sale_date,CURDATE()) AS recency_in_months,
    CASE WHEN total_sales >= 50000 THEN 'High-Performer'
		 WHEN total_sales >= 10000 THEN 'Mid-Range'
		 ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
    total_sales,
    total_quantity,
    total_customers,
	avg_selling_price,
    -- Compute Average order revenue (AOR)
    CASE WHEN total_orders = 0 THEN 0
		 ELSE total_sales/total_orders
    END AS avg_order_revenue,
    
-- Compute Average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales / lifespan
END AS avg_monthly_revenue
FROM product_aggregation





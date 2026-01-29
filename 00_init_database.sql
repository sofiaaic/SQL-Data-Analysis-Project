DROP DATABASE IF EXISTS DataWarehouseAnalytics;
CREATE DATABASE DataWarehouseAnalytics;
USE DataWarehouseAnalytics;

CREATE TABLE dim_customers (
    customer_key INT,
    customer_id INT,
    customer_number VARCHAR(50),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    country VARCHAR(50),
    marital_status VARCHAR(50),
    gender VARCHAR(50),
    birthdate DATE,
    create_date DATE
);

CREATE TABLE dim_products (
    product_key INT,
    product_id INT,
    product_number VARCHAR(50),
    product_name VARCHAR(50),
    category_id VARCHAR(50),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    maintenance VARCHAR(50),
    cost INT,
    product_line VARCHAR(50),
    start_date DATE
);

CREATE TABLE fact_sales (
    order_number VARCHAR(50),
    product_key INT,
    customer_key INT,
    order_date DATE,
    shipping_date DATE,
    due_date DATE,
    sales_amount INT,
    quantity TINYINT,
    price INT
);

TRUNCATE TABLE dim_customers;
TRUNCATE TABLE dim_products;
TRUNCATE TABLE fact_sales;

LOAD DATA LOCAL INFILE '/Users/sofia/Desktop/Proyectos/SQL/sql-data-analytics-project/datasets/flat-files/dim_customers.csv'
INTO TABLE dim_customers
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  customer_key,
  customer_id,
  customer_number,
  first_name,
  last_name,
  country,
  marital_status,
  gender,
  @birthdate,
  @create_date
)
SET
  birthdate   = STR_TO_DATE(NULLIF(TRIM(REPLACE(@birthdate, '\r','')), ''), '%Y-%m-%d'),
  create_date = STR_TO_DATE(NULLIF(TRIM(REPLACE(@create_date, '\r','')), ''), '%Y-%m-%d');


LOAD DATA LOCAL INFILE '/Users/sofia/Desktop/Proyectos/SQL/sql-data-analytics-project/datasets/flat-files/dim_products.csv'
INTO TABLE dim_products
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/sofia/Desktop/Proyectos/SQL/sql-data-analytics-project/datasets/flat-files/fact_sales.csv'
INTO TABLE fact_sales
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  order_number,
  product_key,
  customer_key,
  @order_date,
  @shipping_date,
  @due_date,
  sales_amount,
  quantity,
  price
)
SET
  order_date    = NULLIF(TRIM(REPLACE(@order_date, '\r','')), ''),
  shipping_date = NULLIF(TRIM(REPLACE(@shipping_date, '\r','')), ''),
  due_date      = NULLIF(TRIM(REPLACE(@due_date, '\r','')), '');



# 📊 Data Warehouse Analytics Project (SQL)

## 📌 Descripción del Proyecto

Este proyecto implementa un **Data Warehouse y una capa analítica** usando SQL para analizar el desempeño de ventas, el comportamiento de los clientes y el rendimiento de los productos a lo largo del tiempo.

Se basa en un diseño de tipo **Star Schema**, compuesto por:
- Tablas de dimensiones (`dim_customers`, `dim_products`)
- Una tabla de hechos (`fact_sales`)

El proyecto incluye:
- Carga de datos desde archivos CSV  
- Análisis temporal (mensual y anual)  
- Métricas acumuladas  
- Comparación de desempeño (Year-over-Year y promedio histórico)  
- Segmentación de datos  
- Creación de vistas analíticas orientadas al negocio  

---

## 🗃️ Esquema de la Base de Datos

### ⭐ Tablas de Dimensión

#### `dim_customers`
Almacena la información de los clientes.

| Column | Description |
|--------|-------------|
| customer_key | Surrogate key |
| customer_id | Original customer ID |
| customer_number | Business customer number |
| first_name | First name |
| last_name | Last name |
| country | Country |
| marital_status | Marital status |
| gender | Gender |
| birthdate | Date of birth |
| create_date | Customer creation date |

---

#### `dim_products`
Almacena la información de los productos.

| Column | Description |
|--------|-------------|
| product_key | Surrogate key |
| product_id | Original product ID |
| product_number | Product code |
| product_name | Product name |
| category | Product category |
| subcategory | Product subcategory |
| cost | Product cost |
| product_line | Product line |
| start_date | Product launch date |

---

### 📈 Tabla de Hechos

#### `fact_sales`
Almacena las transacciones de ventas.

| Column | Description |
|--------|-------------|
| order_number | Order ID |
| product_key | FK to products |
| customer_key | FK to customers |
| order_date | Order date |
| shipping_date | Shipping date |
| due_date | Due date |
| sales_amount | Total sale amount |
| quantity | Quantity sold |
| price | Unit price |

---

## ⚙️ Carga de Datos

Los datos se cargan desde archivos CSV utilizando:

```sql
LOAD DATA LOCAL INFILE 'dim_customers.csv' INTO TABLE dim_customers;
LOAD DATA LOCAL INFILE 'dim_products.csv' INTO TABLE dim_products;
LOAD DATA LOCAL INFILE 'fact_sales.csv' INTO TABLE fact_sales;

Create Table online_retail_sales(
Invoice_No Text Not null,
Stock_Code Text ,
Description Text,
Quantity Integer,
Invoice_Date date,
Unit_Price Numeric(10,2),
CustomerID Integer,
Country Varchar(50),
Revenue Numeric(10,2)
);

Select * From online_retail_sales;

----Total Orders(1)
Select Count(*) From online_retail_sales;

----Total revenue(2)
Select Sum(revenue) from online_retail_sales;

----Unique Orders(3)
Select Count(distinct invoice_no) from online_retail_sales;

----Unique Customers(4)
Select Count(distinct customerid) from online_retail_sales;

----Top 10 Countries by Revenue(5)
SELECT country, SUM(revenue) AS total_revenue FROM online_retail_sales
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 10;

----Monthly Revenue Analysis(6)
SELECT
EXTRACT(YEAR FROM invoice_date) AS year,
EXTRACT(MONTH FROM invoice_date) AS month,
SUM(revenue) AS total_revenue FROM online_retail_sales
GROUP BY EXTRACT(YEAR FROM invoice_date),
EXTRACT(MONTH FROM invoice_date)
ORDER BY year,month;

----Top 10 Best-Selling Products(7)
Select description,Sum(quantity) as total_quantity
From online_retail_sales
Group by description order by total_quantity DESC
Limit 10;

----Top 10 Customers by Revenue(8)
Select customerid,Sum(revenue) as total_revenue
From online_retail_sales where customerid is not null
Group by customerid order by total_revenue DESC
Limit 10;

----Repeat Customers vs One-Time Customers(9)
WITH customer_orders AS (SELECT CustomerID,
COUNT(DISTINCT Invoice_No) AS total_orders
FROM online_retail_sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID)

SELECT CASE
WHEN total_orders = 1 THEN 'One-Time Customer' ELSE 'Repeat Customer'
END AS customer_type,
COUNT(*) AS total_customers FROM customer_orders
GROUP BY CASE
WHEN total_orders = 1 THEN 'One-Time Customer'
ELSE 'Repeat Customer'
END;

----Country-wise Orders Analysis(10)
Select country,Count(distinct invoice_no) as total_invoice_no
From online_retail_sales
Group by country
Order by total_invoice_no DESC
Limit 10;

----Country-wise Revenue Contribution (%) (11)
WITH Country_wise_Revenue_Contribution AS 
(Select country,Sum(revenue) as total_revenue From online_retail_sales
Group by country
Order by Sum(revenue) DESC)

Select country,total_revenue,Round((total_revenue/Sum(total_revenue) 
Over())*100,2) AS percentage From
Country_wise_Revenue_Contribution
Limit 10;

----Average Order Value (AOV)(12)
With AOV AS(Select Sum(revenue) as avg_revenue,invoice_no from 
online_retail_sales
Group by invoice_no)

Select Avg(avg_revenue) From AOV;

----Alternative
SELECT SUM(revenue) / COUNT(DISTINCT invoice_no) AS avg_order_value 
FROM online_retail_sales;

----Monthly Order Analysis(13)
Select Extract(year from invoice_date) as year,
Extract(month from invoice_date) as month,
Count(distinct invoice_no) AS unique_orders
From online_retail_sales
Group by Extract(year from invoice_date),
Extract(month from invoice_date)
Order by year,month;

----Monthly Revenue vs Monthly Orders(14)
SELECT
EXTRACT(YEAR FROM invoice_date) AS year,
EXTRACT(MONTH FROM invoice_date) AS month,
COUNT(DISTINCT invoice_no) AS total_orders,
SUM(revenue) AS total_revenue,
ROUND(SUM(revenue) / COUNT(DISTINCT invoice_no),
2) AS monthly_aov
FROM online_retail_sales
GROUP BY
EXTRACT(YEAR FROM invoice_date),
EXTRACT(MONTH FROM invoice_date)
ORDER BY year,month;

----Customer Revenue Segmentation(15)
WITH CRS AS (SELECT customerid,          
SUM(revenue) AS total_revenue
FROM online_retail_sales
WHERE customerid IS NOT NULL
GROUP BY customerid
),

Customer_Segmentation AS
(SELECT CASE
WHEN total_revenue > 5000 THEN 'High Value Customer'
WHEN total_revenue BETWEEN 1000 AND 5000 THEN 'Medium Value Customer'
ELSE 'Low Value Customer'
END AS customer_status
FROM CRS)

SELECT customer_status,COUNT(*) AS total_customers
FROM Customer_Segmentation
GROUP BY customer_status
ORDER BY total_customers DESC;

----Customer Retention Analysis(16)
WITH customer_years AS(SELECT customerid,
EXTRACT(YEAR FROM invoice_date) AS year
FROM online_retail_sales
WHERE customerid IS NOT NULL
GROUP BY customerid, EXTRACT(YEAR FROM invoice_date)
)

SELECT COUNT(*) FILTER (WHERE year = 2010) AS customers_2010,
COUNT(*) FILTER (WHERE year = 2011) AS customers_2011,
COUNT(DISTINCT customerid) FILTER (
WHERE customerid IN (
SELECT customerid
FROM customer_years
GROUP BY customerid
HAVING COUNT(DISTINCT year) = 2)) AS repeat_year_customers
FROM customer_years;

----New vs Returning Customers – 2011(17)
WITH customer_history AS
(SELECT customerid,
MIN(EXTRACT(YEAR FROM invoice_date)) AS first_purchase_year
FROM online_retail_sales
WHERE customerid IS NOT NULL
GROUP BY customerid
),

customer_type AS
(SELECT CASE
WHEN first_purchase_year = 2011
THEN 'New Customer'
ELSE 'Returning Customer'
END AS customer_status
FROM customer_history
WHERE customerid IN
(SELECT DISTINCT customerid
FROM online_retail_sales
WHERE EXTRACT(YEAR FROM invoice_date) = 2011
AND customerid IS NOT NULL)
)

SELECT customer_status,
COUNT(*) AS total_customers
FROM customer_type
GROUP BY customer_status;

----Calculate Monthly Revenue Growth(18)
WITH monthly_revenue AS (SELECT 
EXTRACT(YEAR FROM invoice_date) AS year,
EXTRACT(MONTH FROM invoice_date) AS month,
SUM(revenue) AS current_revenue
FROM online_retail_sales
GROUP BY EXTRACT(YEAR FROM invoice_date),
EXTRACT(MONTH FROM invoice_date)
),

previous_month AS (SELECT year,month,current_revenue,
LAG(current_revenue) OVER (ORDER BY year, month) AS previous_revenue
FROM monthly_revenue)

SELECT year,month,
ROUND(current_revenue, 2) AS current_month_revenue,
ROUND(previous_revenue, 2) AS previous_month_revenue,
ROUND(
((current_revenue - previous_revenue) / NULLIF(previous_revenue, 0)) * 100,2) 
AS revenue_growth_percentage
FROM previous_month
ORDER BY year, month;

----Month-over-Month Order Growth Analysis(19)
With monthly_orders As (Select Extract(year from invoice_date) As year,
Extract(month from invoice_date) As month,
Count(distinct invoice_no) As current_order
From online_retail_sales
Group By Extract(year from invoice_date),
Extract(month from invoice_date)
),

Previous_month As (Select year,month,current_order,
Lag(current_order) Over (order by year,month) AS previous_order
From monthly_orders)

Select year,month ,Round(current_order,2) as current_month_order,
Round(previous_order,2) as previous_month_order,
Round((current_order-previous_order)::numeric/(Nullif(previous_order,0))*100,2) as 
order_growth_percentage From Previous_month;

----Customer Lifetime Value (CLV)
Select customerid,sum(revenue),count(distinct invoice_no) From online_retail_sales
Where customerid is not null
Group by customerid
Order by sum(revenue) DESC
Limit 10;

----Product Revenue Contribution Analysis
SELECT description,ROUND(SUM(revenue), 2) AS product_revenue,
ROUND((SUM(revenue) / SUM(SUM(revenue)) OVER()) * 100, 2) AS revenue_contribution_percentage
FROM online_retail_sales
WHERE description IS NOT NULL
GROUP BY description
ORDER BY product_revenue DESC
LIMIT 10;

----RFM Customer Segmentation

----Step 1
SELECT customerid,
MAX(invoice_date) AS last_purchase_date,
COUNT(DISTINCT invoice_no) AS frequency,
ROUND(SUM(revenue), 2) AS monetary FROM online_retail_sales
WHERE customerid IS NOT NULL
GROUP BY customerid
ORDER BY monetary DESC;

----Step 2
WITH customer_rfm AS (SELECT customerid,
MAX(invoice_date)::date AS last_purchase_date,
COUNT(DISTINCT invoice_no) AS frequency,
SUM(revenue) AS monetary
FROM online_retail_sales
WHERE customerid IS NOT NULL
GROUP BY customerid)

SELECT customerid,last_purchase_date,
DATE '2011-12-10' - last_purchase_date AS recency_days,
frequency,ROUND(monetary, 2) AS monetary
FROM customer_rfm
ORDER BY recency_days ASC;

----Step 3
WITH customer_rfm AS (SELECT customerid,
DATE '2011-12-10' - MAX(invoice_date)::date AS recency,
COUNT(DISTINCT invoice_no) AS frequency,
SUM(revenue) AS monetary
FROM online_retail_sales
WHERE customerid IS NOT NULL
GROUP BY customerid
),

rfm_scores AS (
SELECT customerid,recency,frequency,monetary,
NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM customer_rfm)

SELECT customerid,recency,frequency,
ROUND(monetary, 2) AS monetary,
r_score,f_score,m_score
FROM rfm_scores

----Step 4
WITH customer_rfm AS (SELECT customerid,
DATE '2011-12-10' - MAX(invoice_date)::date AS recency,
COUNT(DISTINCT invoice_no) AS frequency,SUM(revenue) AS monetary
FROM online_retail_sales
WHERE customerid IS NOT NULL
GROUP BY customerid),

rfm_scores AS (SELECT customerid,
NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM customer_rfm),

rfm_segments AS (SELECT customerid,r_score,f_score,m_score,
CASE
WHEN r_score = 5 AND f_score = 5 AND m_score = 5 THEN 'Champions'
WHEN r_score >= 4 AND f_score >= 4
THEN 'Loyal Customers'
WHEN r_score = 5
THEN 'Recent Customers'
WHEN r_score <= 2 AND f_score >= 4
THEN 'At Risk Customers'
WHEN r_score = 1 AND f_score = 1 AND m_score = 1
THEN 'Lost Customers'
ELSE 'Potential Customers'
END AS customer_segment
FROM rfm_scores)

SELECT customer_segment,
COUNT(*) AS total_customers
FROM rfm_segments
GROUP BY customer_segment
ORDER BY total_customers DESC;

----Running Total Revenue Analysis
SELECT 
EXTRACT(YEAR FROM invoice_date) AS year,
EXTRACT(MONTH FROM invoice_date) AS month,
ROUND(SUM(revenue), 2) AS monthly_revenue,
ROUND(SUM(SUM(revenue)) OVER (ORDER BY EXTRACT(YEAR FROM invoice_date), 
EXTRACT(MONTH FROM invoice_date)), 2) AS running_total_revenue
FROM online_retail_sales
GROUP BY EXTRACT(YEAR FROM invoice_date), 
EXTRACT(MONTH FROM invoice_date)
ORDER BY year, month;



















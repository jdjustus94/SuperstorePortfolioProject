--First Class Orders
SELECT customer_id, customer_name, order_id, order_date, ship_date, (ship_date-order_date) AS days_since_ordered
FROM superstore
WHERE ship_mode = 'First Class'
GROUP BY region, 1,2,3,4,5
ORDER BY customer_name;

--Category Orders
SELECT DISTINCT category, sub_category, SUM(sales) AS sales, SUM(profit) As profit, COUNT(row_id) AS orders
FROM superstore
GROUP BY 1,2
ORDER BY category, orders;

--Category Profits and Profit Difference
WITH A AS
(SELECT category, SUM(profit) AS profit_2019
FROM superstore
WHERE EXTRACT(year FROM order_date) = '2019'
GROUP BY 1
ORDER BY 1),

B AS 
(SELECT category, SUM(profit) AS profit_2020
FROM superstore
WHERE EXTRACT(year FROM order_date) = '2020'
GROUP BY 1
ORDER BY 1)

SELECT A.category, profit_2019, profit_2020, (profit_2020-profit_2019) AS profit_diff
FROM A
LEFT JOIN B
ON A.category = B.category
GROUP BY 1,2,3;

--Consumer orders by shipping mode
SELECT DISTINCT segment, ship_mode, COUNT(row_id) AS orders, SUM(sales) AS sales
FROM superstore
GROUP BY 1,2
ORDER BY 1, orders;

--Samsung phone sales and profit
SELECT sub_category, product_name, COUNT(row_id) AS orders, SUM(sales) AS sales, SUM(profit) AS profit
FROM superstore
WHERE product_name LIKE 'Samsung%'
GROUP BY 1,2
ORDER BY 2,5;

--Sales by Month per Year
WITH A AS
(SELECT EXTRACT(month FROM order_date) AS months, SUM(sales) AS sales_2019, SUM(profit) AS profit_2019
FROM superstore
WHERE EXTRACT(year FROM order_date) = '2019'
GROUP BY 1),

B AS
(SELECT EXTRACT(month FROM order_date) AS months, SUM(sales) AS sales_2020, SUM(profit) AS profit_2020
FROM superstore
WHERE EXTRACT(year FROM order_date) = '2020'
GROUP BY 1)

SELECT A.months, sales_2019, profit_2019, sales_2020, profit_2020, (sales_2020-sales_2019) AS yrly_sales_diff, 
(profit_2020-profit_2019) AS yrly_profit_diff
FROM A
INNER JOIN B
ON A.months=B.months;

--California sales % against total Western Region Sales
SELECT (SELECT SUM(sales) FROM superstore WHERE state = 'California') AS cali_sales,
(SELECT SUM(sales) FROM superstore WHERE region = 'West') AS western_sales,
ROUND(((SELECT SUM(sales) FROM superstore WHERE state = 'California')/(SELECT SUM(sales) FROM superstore WHERE region = 'West')*100.0),2) AS
cali_sale_perc
FROM superstore
LIMIT 1;

--New York City Orders/Sales with running total
SELECT customer_name, order_id,category,sub_category,product_id, order_date, segment, SUM(sales) AS sales, SUM(sales) OVER(PARTITION BY segment ORDER BY segment 
											ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM superstore
WHERE state = 'New York' AND city = 'New York City'
GROUP BY 1,2,3,4,5,6,7, sales
ORDER BY segment;

--Sale Percentage for each region and each segment
SELECT DISTINCT ROUND((((SELECT SUM(CASE WHEN region = 'Central' THEN 1 ELSE 0 END)
						   FROM superstore))::NUMERIC/((SELECT COUNT(region) FROM superstore))::NUMERIC),2) AS central_sale_perc,
ROUND((((SELECT SUM(CASE WHEN region = 'South' THEN 1 ELSE 0 END) FROM superstore))::NUMERIC/((SELECT COUNT(region) FROM superstore))::NUMERIC),2)
AS south_sale_perc,
ROUND((((SELECT SUM(CASE WHEN region = 'East' THEN 1 ELSE 0 END) FROM superstore))::NUMERIC/((SELECT COUNT(region) FROM superstore))::NUMERIC),2)
AS east_sale_perc,
ROUND((((SELECT SUM(CASE WHEN region = 'West' THEN 1 ELSE 0 END) FROM superstore))::NUMERIC/((SELECT COUNT(region) FROM superstore))::NUMERIC),2)
AS west_sale_perc,
ROUND((((SELECT SUM(CASE WHEN segment = 'Consumer' THEN 1 ELSE 0 END) FROM superstore))::NUMERIC/((SELECT COUNT(segment) FROM superstore))::NUMERIC),2)
AS consumer_sale_perc,
ROUND((((SELECT SUM(CASE WHEN segment = 'Corporate' THEN 1 ELSE 0 END) FROM superstore))::NUMERIC/((SELECT COUNT(segment) FROM superstore))::NUMERIC),2)
AS corporate_sale_perc,
ROUND((((SELECT SUM(CASE WHEN segment = 'Home Office' THEN 1 ELSE 0 END) FROM superstore))::NUMERIC/((SELECT COUNT(segment) FROM superstore))::NUMERIC),2)
AS home_office_sale_perc
FROM superstore;

-- 4th Quarter Product Sales with DOW
SELECT CONCAT(EXTRACT(month FROM order_date), '-', EXTRACT(day FROM order_date), ' ', CASE WHEN EXTRACT(dow FROM order_date) = 0 THEN 'Sunday'
WHEN EXTRACT(dow FROM order_date) = 1 THEN 'Monday'
WHEN EXTRACT(dow FROM order_date) = 2 THEN 'Tuesday'
WHEN EXTRACT(dow FROM order_date) = 3 THEN 'Wednesday'
WHEN EXTRACT(dow FROM order_date) = 4 THEN 'Thursday'
WHEN EXTRACT(dow FROM order_date) = 5 THEN 'Friday'
WHEN EXTRACT(dow FROM order_date) = 6 THEN 'Saturday'
END) AS date, order_id, category, sub_category, SUM(SUM(sales)) OVER(PARTITION BY category, sub_category ORDER BY order_date) AS sales,
SUM(SUM(profit)) OVER(PARTITION BY category, sub_category ORDER BY order_date) AS profit
FROM superstore
WHERE EXTRACT(quarter FROM order_date) = '4'
GROUP BY order_date, category, sub_category, order_id
ORDER BY order_date ASC, category;

--Customers with orders > 20
SELECT DISTINCT customer_name, customer_id, COUNT(customer_id) AS cust_orders, segment,
ROUND(AVG(AVG(sales)) OVER(PARTITION BY customer_name ORDER BY customer_name),2) AS avg_money_spent, 
SUM(SUM(sales)) OVER(PARTITION BY customer_name ORDER BY customer_name) AS total_money_spent
FROM superstore
GROUP BY 1,2,4
HAVING COUNT(customer_id) > 20
ORDER BY cust_orders DESC, segment;

--2019/2020 Quarterly Sales and Profit
WITH A AS
(SELECT CASE WHEN EXTRACT(quarter FROM order_date) = 1 THEN '1st Quarter'
WHEN EXTRACT(quarter FROM order_date) = 2 THEN '2nd Quarter'
WHEN EXTRACT(quarter FROM order_date) = 3 THEN '3rd Quarter' 
WHEN EXTRACT(quarter FROM order_date) = 4 THEN '4th Quarter' END AS quarter, SUM(sales) AS sales, ROUND(AVG(sales),2) AS avg_sales, 
COUNT(order_id) AS orders, SUM(profit) AS profit
FROM superstore
WHERE EXTRACT(year from order_date) = '2019'
GROUP BY 1
ORDER BY quarter),

B AS
(SELECT CASE WHEN EXTRACT(quarter FROM order_date) = 1 THEN '1st Quarter'
WHEN EXTRACT(quarter FROM order_date) = 2 THEN '2nd Quarter'
WHEN EXTRACT(quarter FROM order_date) = 3 THEN '3rd Quarter' 
WHEN EXTRACT(quarter FROM order_date) = 4 THEN '4th Quarter' END AS quarter, SUM(sales) AS sales, ROUND(AVG(sales),2) AS avg_sales, 
COUNT(order_id) AS orders, SUM(profit) AS profit
FROM superstore
WHERE EXTRACT(year from order_date) = '2020'
GROUP BY 1
ORDER BY quarter)

SELECT (A.quarter) AS quarters_2019, (A.orders) AS orders_2019,(A.sales) AS sales_2019,(A.avg_sales) AS avg_sale_2019,
(A.profit) AS profit_2019, (B.quarter) AS quarters_2020,(B.orders) AS orders_2020,(B.sales) AS sales_2020,(B.avg_sales) AS avg_sale_2020,
(B.profit) AS profit_2020
FROM A 
INNER JOIN B
ON A.quarter = B.quarter
ORDER BY 1;
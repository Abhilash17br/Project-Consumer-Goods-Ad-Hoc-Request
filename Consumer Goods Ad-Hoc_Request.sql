# Requests:

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT  market 
FROM DIM_CUSTOMER 
WHERE customer = 'Atliq Exclusive' AND region = 'APAC';

-- 2. What is the percentage of unique product increase in 2021 vs. 2020?
-- The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg 

WITH CTE AS(
	SELECT 
	COUNT(DISTINCT IF(fiscal_year = 2020,product_code,Null)) AS unique_products_2020,
	COUNT(DISTINCT IF(fiscal_year = 2021,product_code,Null)) AS unique_products_2021
	FROM  FACT_SALES_MONTHLY)
SELECT *,
ROUND(((unique_products_2021-unique_products_2020)/unique_products_2020)*100,2) AS percentage_chg 
FROM CTE;

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
-- The final output contains 2 fields, segment product_count.

SELECT  segment,COUNT( DISTINCT product_code) AS PRODUCT_COUNT
FROM DIM_PRODUCT
GROUP BY segment
ORDER BY PRODUCT_COUNT DESC;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
-- The final output contains these fields, segment product_count_2020 product_count_2021 difference.

WITH CTE1 AS (SELECT segment,COUNT( DISTINCT product_code) AS product_count_2020
			  FROM FACT_SALES_MONTHLY
			  LEFT JOIN DIM_PRODUCT USING(product_code)
			  WHERE FISCAL_YEAR = 2020
			  GROUP BY segment),
	 CTE2 AS (SELECT segment,COUNT( DISTINCT product_code) AS product_count_2021
			  FROM FACT_SALES_MONTHLY
			  LEFT JOIN DIM_PRODUCT USING(product_code)
			  WHERE FISCAL_YEAR = 2021
			  GROUP BY segment)
SELECT *, (product_count_2021-product_count_2020) AS difference
FROM CTE1
INNER JOIN CTE2 USING(segment)
ORDER BY difference DESC;

-- 5. Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, product_code product manufacturing_cost codebasics

SELECT product_code,product,manufacturing_cost
FROM FACT_MANUFACTURING_COST 
INNER JOIN DIM_PRODUCT USING(product_code)
WHERE manufacturing_cost IN 
((SELECT MAX(manufacturing_cost) FROM FACT_MANUFACTURING_COST),
 (SELECT MIN(manufacturing_cost) FROM FACT_MANUFACTURING_COST));


-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct
--     for the fiscal year 2021 and in the Indian market.
-- The final output contains these fields, customer_code customer average_discount_percentage.

SELECT customer_code,customer,AVG(pre_invoice_discount_pct) AS AVG_DISCOUNT
FROM FACT_PRE_INVOICE_DEDUCTIONS
INNER JOIN DIM_CUSTOMER USING( customer_code)
WHERE fiscal_year = 2021 AND market = 'India'
GROUP BY customer_code
ORDER BY AVG_DISCOUNT DESC LIMIT 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns: Month Year Gross sales Amount.

SELECT date,FISCAL_YEAR,ROUND((SUM(sold_quantity)*SUM(gross_price))/1000000,2) AS Gross_sales_Amount_MIL
FROM FACT_SALES_MONTHLY
INNER JOIN FACT_GROSS_PRICE USING(product_code,fiscal_year)
INNER JOIN  dim_customer USING(customer_code)
WHERE customer = 'Atliq Exclusive'
GROUP BY date,FISCAL_YEAR;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity?
-- The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity.

SELECT CEIL(MONTH(DATE_ADD(date,INTERVAL 4 MONTH))/3) AS Quarter, 
SUM(sold_quantity) AS total_sold_quantity
FROM FACT_SALES_MONTHLY WHERE FISCAL_YEAR = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
-- The final output contains these fields, channel gross_sales_mln,percentage.

WITH CTE AS(
			SELECT channel,ROUND((SUM(sold_quantity)*SUM(gross_price))/1000000,2) AS Gross_sales_mln
			FROM FACT_SALES_MONTHLY
			INNER JOIN FACT_GROSS_PRICE USING(product_code,fiscal_year)
			INNER JOIN  dim_customer USING(customer_code)
			WHERE fiscal_year = 2021
			GROUP BY channel)
SELECT *, Gross_sales_mln/SUM(Gross_sales_mln) OVER()*100  AS percentage 
FROM CTE
ORDER BY percentage DESC LIMIT 1;


-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
-- The final output contains these fields, division product_code,product total_sold_quantity rank_order.

WITH CTE AS (
SELECT division,product_code,CONCAT(product,' - ',variant) AS PRODUCT_NAME,SUM(sold_quantity) AS total_sold_quantity,
ROW_NUMBER() OVER(PARTITION BY division ORDER BY SUM(sold_quantity) DESC ) AS RN  
FROM FACT_SALES_MONTHLY
INNER JOIN DIM_PRODUCT USING(product_code)
WHERE fiscal_year = 2021
GROUP BY division,product_code,product_NAME)
SELECT * FROM CTE WHERE RN < 4;
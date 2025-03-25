select * from dim_customer limit 100;
select * from dim_product limit 100;
select * from fact_gross_price limit 100;
select * from fact_manufacturing_cost limit 100;
select * from fact_pre_invoice_deductions limit 100;
select * from fact_sales_monthly limit 100;

# ADHOC REQUESTS

select DISTINCT market from dim_customer where customer = "Atliq Exclusive" and region = "APAC";

/*
What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg*/

with cte_unique as(
select count(DISTINCT case when fiscal_year = 2020 then p.product_code end) as unique_products_2020, 
count(DISTINCT case when fiscal_year = 2021 then p.product_code end) as unique_products_2021
from dim_product p INNER JOIN fact_gross_price gp ON p.product_code = gp.product_code)

select unique_products_2020 , unique_products_2021, 
ROUND((abs(unique_products_2020 - unique_products_2021)/(unique_products_2020) *100 ),2)   
as percentage_chg from cte_unique;


/* Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
The final output contains 2 fields, segment product_count*/

select segment, count(DISTINCT product_code) as unique_product_count from dim_product 
group by segment order by 2 desc;




/* Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, 
segment product_count_2020 product_count_2021 difference*/

with uniq_segment_products as(
select p.segment, count( DISTINCT case when fiscal_year = 2020 then p.product_code end) as unique_products_2020, 
count( DISTINCT case when fiscal_year = 2021 then p.product_code end) as unique_products_2021
 from dim_product p INNER JOIN fact_gross_price gp ON
p.product_code = gp.product_code
group by p.segment)
select *, abs(unique_products_2020 - unique_products_2021) as diff from uniq_segment_products order by diff desc;

/*Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost*/


select p.product_code, p.product, manufacturing_cost from dim_product p INNER JOIN fact_manufacturing_cost mc 
ON p.product_code = mc.product_code
where manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)  
or 
manufacturing_cost = ( select min(manufacturing_cost) from fact_manufacturing_cost) order by manufacturing_cost desc;


/* Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and 
in the Indian market. The final output contains these fields, customer_code customer average_discount_percentage */

select c.customer_code,c.customer, ROUND(pd.pre_invoice_discount_pct*100,2) as average_discount_pct
 from dim_customer c INNER JOIN fact_pre_invoice_deductions pd ON c.customer_code = pd.customer_code
where market ="India" and fiscal_year = "2021" order by pre_invoice_discount_pct desc
LIMIT 5;

/* Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and 
high-performing months and take strategic decisions. The final report contains these columns: Month Year Gross sales Amount */

with Atliq_Exclusive_Sales as(
select * from fact_sales_monthly where customer_code IN (select customer_code from dim_customer where customer = "Atliq Exclusive"))

select MONTHNAME(date) as Sale_month , YEAR(date) as Sale_year, ROUND((sum(sold_quantity*gross_price)/1000000),2) as Gross_Sales_Amount_Millions
 from Atliq_Exclusive_Sales aes INNER JOIN fact_gross_price gp ON aes.product_code  = gp.product_code and aes.fiscal_year = gp.fiscal_year
GROUP BY MONTHNAME(date),YEAR(date) order by Sale_year, Gross_Sales_Amount_Millions desc;



/* In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity*/

select CASE WHEN MONTH(date) IN(9,10,11) then "Q1" WHEN MONTH(date) IN(12,1,2) then "Q2"
            WHEN MONTH(date) IN(3,4,5) then "Q3" WHEN MONTH(date) IN (6,7,8) then "Q4" end as Quarter, 
            sum(sold_quantity) as Total_Sold_Quantity 
            from fact_sales_monthly where fiscal_year = 2020 group by Quarter order by Total_Sold_Quantity desc;

/*Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
 The final output contains these fields, channel gross_sales_mln percentage*/
 
 WITH channel_gross_sales as(
 select c.channel, ROUND((sum(fm.sold_quantity*gp.gross_price)/1000000),2) as gross_sales_Millions from dim_customer c LEFT JOIN 
 fact_sales_monthly fm ON c.customer_code = fm.customer_code LEFT JOIN fact_gross_price gp
  ON gp.product_code = fm.product_code and gp.fiscal_year = fm.fiscal_year Where gp.fiscal_year = 2021
 group by c.channel)
 
 select channel, gross_sales_Millions, ROUND(((gross_sales_Millions/ sum(gross_sales_Millions)OVER())*100) ,2) as pct_contributed 
 from channel_gross_sales order by gross_sales_Millions desc;
 
 
/*Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields, division product_code product total_sold_quantity rank_order*/

with cte_rnk as(
select p.division,p.product_code,p.product,
sum(fm.sold_quantity) as total_sold_quantity, DENSE_RANK() OVER(partition by p.division order by sum(fm.sold_quantity) desc) as rnk
 from dim_product p INNER JOIN fact_sales_monthly fm ON p.product_code = fm.product_code
where fm.fiscal_year = 2021 group by p.division,p.product_code,p.product)

select * from cte_rnk where rnk <=3;


select c.customer_code,c.customer, ROUND(pd.pre_invoice_discount_pct*100,2) as average_discount_pct
 from dim_customer c INNER JOIN fact_pre_invoice_deductions pd ON c.customer_code = pd.customer_code
where market ="India" and fiscal_year = "2021" order by pre_invoice_discount_pct desc
LIMIT 5;

select c.customer_code,c.customer,AVG(ROUND((pre_invoice_discount_pct*100),2)) as average_discount_pct
 from dim_customer c INNER JOIN fact_pre_invoice_deductions pd ON c.customer_code = pd.customer_code
where market ="India" and fiscal_year = "2021"  group by c.customer_code,c.customer 
order by average_discount_pct desc
LIMIT 5;



select * from dim_customer c INNER JOIN fact_pre_invoice_deductions pd ON c.customer_code = pd.customer_code
 where market = "India" and customer = "Amazon" and fiscal_year = 2021
-- CREATE SCHEMA sales_data;
-- SET search_path = sales_data;

-- DROP TABLE IF EXISTS sales;
-- CREATE TABLE sales (
-- 	ORDERNUMBER integer,
-- 	QUANTITYORDERED	int,
-- 	PRICEEACH float,	
-- 	ORDERLINENUMBER	integer,
-- 	SALES float,
-- 	ORDERDATE timestamp,	
-- 	STATUS varchar,	
-- 	QTR_ID int,
-- 	MONTH_ID int,
-- 	YEAR_ID	int,
-- 	PRODUCTLINE	varchar,
-- 	MSRP int,
-- 	PRODUCTCODE varchar,
-- 	CUSTOMERNAME varchar,
-- 	PHONE varchar,
-- 	ADDRESSLINE1 varchar, 
-- 	ADDRESSLINE2 varchar,
-- 	CITY varchar,
-- 	STATE varchar,
-- 	POSTALCODE varchar,
-- 	COUNTRY varchar,
-- 	TERRITORY varchar,
-- 	CONTACTLASTNAME varchar,
-- 	CONTACTFIRSTNAME varchar,
-- 	DEALSIZE varchar
-- );

-- set client_encoding = 'utf8';

-- copy sales from '/Applications/PostgreSQL 14/Data/sales_data_sample.csv' delimiter ',' csv header encoding 'windows-1251';


select * from sales;

-------------- CHECKING UNIQUE VALUES --------------

select distinct status from sales; -- nice to plot
select distinct year_id from sales;
select distinct productline from sales; -- nice to plot
select distinct country from sales; -- nice to plot
select distinct dealsize from sales; -- nice to plot
select distinct territory from sales; -- nice to plot


------------- ANALYSIS ------------

------ Grouping sales by product line
select productline, round(cast(sum(sales) as numeric),2) as revenue from sales group by 1 order by 2 desc;

------ Months operated per year
select year_id, count(distinct month_id) as months_operated from sales group by 1;

------ Sales by Year
select year_id, round(cast(sum(sales) as numeric),2) as revenue from sales group by 1 order by 2 desc;

------ Sales by Dealsize
select dealsize, round(cast(sum(sales) as numeric),2) as revenue from sales group by 1 order by 2 desc;

------ Top 3 months for sales in each year
with cte as(
select *, row_number() over(partition by year_id order by revenue desc) as rnk from(
select year_id, month_id, round(cast(sum(sales) as numeric),2) as revenue, count(ordernumber) as total_orders from sales group by 1,2) as a)

select year_id, month_id, revenue, total_orders from cte where rnk<4;

------- What Product Line Sells Most in Best Month?
with cte as(
select *, row_number() over(partition by year_id order by revenue desc) as rnk from(
select year_id, month_id, productline, round(cast(sum(sales) as numeric),2) as revenue, count(ordernumber) as total_orders from sales group by 1,2,3) as a)

select year_id, month_id, productline, revenue, total_orders from cte where rnk=1;

------- Who is the best Customer?
--- RFM Analysis
-- Recency: last order date, Frequency: Count of total orders, Monetary value: Total Spend
drop table if exists rfm;
create table rfm as(
with cte as(
	select customername, round(cast(sum(sales) as numeric),2) as Total_Sales, round(cast( avg(sales) as numeric),2) as avg_sales, count(ordernumber) as total_orders, max(orderdate) as last_order_date,
	(select max(orderdate) from sales) as max_orderdate,
	((select max(orderdate) from sales) - max(orderdate)) as recency
	from sales group by 1
),
rfm_calc as(
	select cte.*, 
		ntile(4) over(order by recency desc) as rfm_recency,
		ntile(4) over(order by total_orders) as rfm_frequency,
		ntile(4) over(order by Total_Sales) as rfm_monetary
	from cte
)
select *, (rfm_recency + rfm_frequency + rfm_monetary) as rfm_cell,
	concat(rfm_recency::varchar, rfm_frequency::varchar, rfm_monetary::varchar) as rfm_cell_string
from rfm_calc
);

select customername, rfm_recency, rfm_frequency, rfm_monetary, rfm_cell,
case
	when rfm_cell_string in ('111', '112', '121', '122', '123', '132', '211', '212', '114', '141') then 'Lost Customers'
	when rfm_cell_string in ('133', '134', '143', '244', '334', '343', '344') then 'Slipping Away'
	when rfm_cell_string in ('311', '411', '331') then 'New Customers'
	when rfm_cell_string in ('222', '223','233','322') then 'Potential Churners'
	when rfm_cell_string in ('323', '333', '321', '422', '332', '432') then 'Active'
	when rfm_cell_string in ('433', '434', '443', '444') then 'Loyal'
end as rfm_segment
from rfm;


------------- Most sold Product Codes 
select productcode, count(*) as ct 
from sales group by 1 order by 2 desc limit 1;


-------- Country wise analysis
select country, round(cast(sum(sales) as numeric),2) as Total_Sales, round(cast( avg(sales) as numeric),2) as avg_sales, count(ordernumber) as total_orders 
from sales group by 1 order by 2 desc;





--Assumption for Q1 & Q3: I excluded cancelled and disputed orders because they are not actual sales. I also excluded In Process and On Hold under the assumption that these orders are not finalized.
--For Q2: To calculate the average selling price, I made the assumption that I can include all orders regardless of their status because these products once were sold. 
--Additional note: No null value / any other values that appear error to me 

--Q1. Which product has the highest sales in 2003 and 2004 ?
with tbl_product 
as 
(
	select a.product_id, p.product_line, round(sum(quantity * unit_price)) as total_sales
	from "Order".sales a join "Order".products p on a.product_id = p.product_id 
	where 
	extract (year from order_date) in (2003, 2004) 
	and status in ('Shipped', 'Resolved')
	group by a.product_id, p.product_line 
)
select product_id, product_line, total_sales, dense_rank() over (order by total_sales desc) as product_rank 
from tbl_product

-- Q2. What is the average, minimum, and maximum sales price per deal size?

--assuming the sales price is quantity multiplied by unit_price
select deal_size, 
max(quantity * unit_price) as max_sales_price, 
min(quantity * unit_price) as min_sales_price,
avg(quantity * unit_price) as avg_sales_price,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY quantity * unit_price) as median_sales_price
from "Order".sales 
--where status in ('Shipped', 'Resolved')
group by deal_size 

--assuming the sale price refers to unit price
select deal_size, 
max(unit_price) as max_sales_price, 
min(unit_price) as min_sales_price,
avg(unit_price) as avg_sales_price,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY unit_price) as median_sales_price
from "Order".sales 
--where status in ('Shipped', 'Resolved')
group by deal_size 


-- Q3. What are the total sales, the most popular product, and largest contributing country all per region?

--Q3.1 Total sales per region
select 
c.territory, 
sum(quantity * unit_price) as total_sales_per_region
from "Order".sales a 
join "Order".customers c on a.customer_id = c.customer_id 
and status in ('Shipped', 'Resolved')
group by c.territory

--Q3.2 Most popular product line per region
with tbl_product as 
(
	select *, 
	dense_rank() over (partition by territory order by total_sales desc) as rnk
	from (
		select 
		p.product_line, 
		c.territory, 
		sum(quantity * unit_price) as total_sales
		from "Order".sales a 
		join "Order".customers c on a.customer_id = c.customer_id 
		join "Order".products p on p.product_id = a.product_id 
		and status in ('Shipped', 'Resolved')
		group by p.product_line, c.territory 
	) a
)
select * from tbl_product
where rnk <= 1

--Q3.3. The country with the highest sales per region 

with tbl_product as 
(
	select *, 
	dense_rank() over (partition by territory order by total_sales desc) as rnk
	from (
		select 
		c.address_country, 
		c.territory, 
		sum(quantity * unit_price) as total_sales
		from "Order".sales a 
		join "Order".customers c on a.customer_id = c.customer_id 
		join "Order".products p on p.product_id = a.product_id 
		where status in ('Shipped', 'Resolved')
		group by c.address_country , c.territory 
	) a
)
select * from tbl_product
where rnk <= 1
order by territory






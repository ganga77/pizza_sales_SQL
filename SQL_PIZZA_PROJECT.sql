create database pizzahut;




create table pizzahut.ordersorders (
order_id int not null,
order_date date not null,
order_time time not null,
primary key(order_id));



create table pizzahut.order_details (
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key(order_details_id));

--

Select count(order_id) from pizzahut.orders;





-- Calculate the total revenue generated from pizza sales.
Select round(SUM(od.quantity * pz.price)) as total_revenue from pizzahut.pizzas pz
JOIN pizzahut.order_details od
ON pz.pizza_id = od.pizza_id;

-- Identify the highest-priced pizza. 



Select ty.name, pz.price from pizzahut.pizza_types ty
JOIN pizzahut.pizzas pz
ON ty.pizza_type_id = pz.pizza_type_id
order by price desc limit 1;

-- Identify the most common pizza and its size ordered.



Select ord.pizza_id, pzt.name, COUNT(ord.quantity) as top_sellers , pz.size from pizzahut.order_details ord
Join
pizzahut.pizzas pz
on ord.pizza_id = pz.pizza_id
Join pizzahut.pizza_types pzt
ON pz.pizza_type_id = pzt.pizza_type_id
group by ord.pizza_id, pz.size, pzt.name
order by top_sellers desc
limit 5;


-- Join the necessary tables to find the total quantity of each pizza category ordered.








Select pt.category,  SUM(od.quantity) from pizzahut.pizza_types pt
JOIN pizzahut.pizzas pz
ON pt.pizza_type_id = pz.pizza_type_id
JOIN pizzahut.order_details od
on od.pizza_id = pz.pizza_id
group by pt.category
order by SUM(od.quantity) desc;

-- Determine the distribution of orders by hour of the day.

Select hour(order_time), count(order_id) from pizzahut.orders
group by hour(order_time)
order by hour(order_time) ;


-- Join relevant tables to find the category-wise distribution of pizzas.

Select count(order_id), order_date from pizzahut.orders group by order_date;



-- Group the orders by date and calculate the average number of pizzas ordered per day.


Select avg(tot) from (Select sum(dtl.quantity) as tot,  od.order_date from pizzahut.order_details dtl
JOIN pizzahut.orders od
on od.order_id = dtl.order_details_id
group by od.order_date) x;

-- Determine the top 3 most ordered pizza types based on revenue.


Select  ty.name, SUM(dtl.quantity * pz.price) as revenue from pizzahut.pizza_types ty
JOIN pizzahut.pizzas pz
ON pz.pizza_type_id = ty.pizza_type_id

JOIN pizzahut.order_details dtl
ON dtl.pizza_id = pz.pizza_id
group by ty.name
order by revenue desc limit 3 ;

-- 


 
-- Calculate the percentage contribution of each pizza type to total revenue.


with revenue_per_category  as (
						Select pt.category as categories, round(SUM(pz.price * dtl.quantity)) as revenue
						from  pizzahut.pizza_types pt
						JOIN pizzahut.pizzas pz
						ON pt.pizza_type_id = pz.pizza_type_id

						JOIN pizzahut.order_details dtl
						ON dtl.pizza_id = pz.pizza_id
						group by pt.category
),
	sum_revenue  as (
						Select SUM(revenue) as total_rev from revenue_per_category),
    percentage_revenue  as (
						Select categories, round(revenue/ (Select total_rev from sum_revenue) * 100, 2) as pt_per_cat from revenue_per_category )           

Select rv.categories, rv.revenue, pt.pt_per_cat from  revenue_per_category rv
JOIN percentage_revenue pt
ON rv.categories = pt.categories
order by rv.revenue desc;
                 
                 


 
-- Top 5 days with maximum sale

with total_revenue_per_day as (
						Select DATE(od.order_date) as ord_date, 
                        SUM(pz.price * dtl.quantity) as revenue 
                        from pizzahut.pizzas as pz
						JOIN pizzahut.order_details dtl
						ON pz.pizza_id = dtl.pizza_id
						JOIN pizzahut.orders od
						ON od.order_id = dtl.order_details_id
						group by date(od.order_date)
						order by date(od.order_date)),
     sum_revenue as (
						Select SUM(revenue) as total_revenue
                        from total_revenue_per_day 
                        ),
     percentage_rev_per_day as (
          
						Select 
                        ord_date,
                        round(revenue / (Select total_revenue from sum_revenue) * 100, 2) as pt_rev
                        from total_revenue_per_day)

Select (tr.ord_date),  tr.revenue, pt.pt_rev from total_revenue_per_day tr 
JOIN percentage_rev_per_day pt
ON (tr.ord_date) = (pt.ord_date)
order by pt.pt_rev desc 
limit 5;

-- Analyze the cumulative revenue generated over time.

with total_revenue_per_day as (
						Select DATE(od.order_date) as ord_date, 
                        SUM(pz.price * dtl.quantity) as revenue 
                        from pizzahut.pizzas as pz
						JOIN pizzahut.order_details dtl
						ON pz.pizza_id = dtl.pizza_id
						JOIN pizzahut.orders od
						ON od.order_id = dtl.order_details_id
						group by date(od.order_date)
						order by date(od.order_date))
Select ord_date,
	   revenue,
       round(SUM(revenue) over(order by ord_date)) as cumulative_sum
       from total_revenue_per_day;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.     
     


Select name, 
	   category, 
       rk, 
       revenue from 
       (Select pt.name, pt.category,   SUM(pz.price * dtl.quantity) as revenue,
	   rank() over(partition by category order by SUM(pz.price * dtl.quantity) desc) as rk from pizzahut.pizza_types pt
                    JOIN pizzahut.pizzas pz
                    ON pz.pizza_type_id = pt.pizza_type_id
                    JOIN pizzahut.order_details dtl
                    ON dtl.pizza_id = pz.pizza_id
                    group by pt.name, pt.category) x
                    where x.rk<=3
				;


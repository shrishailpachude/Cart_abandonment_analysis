                                        -- Creating & Importing data

-- Created Database
create database cart_abandonment_analysis;

-- Selecting Database
use cart_abandonment_analysis;

-- Imported sales table
create table sales_raw
(customer_id varchar(10),
session_id varchar(5),
visit_date date,
device_type varchar(10),
user_type varchar(10),
marketing_channel varchar(30),	
product_id	varchar(5),
region varchar(5),
product_category varchar(50),	
unit_price	decimal(10,2),
quantity int,
discount_percent int,
discount_amount decimal(10,2),
revenue decimal(10,2),
pages_viewed int,
time_on_site_sec int,
product_view int,
added_to_cart int,
checkout int,
Payment	int, 
purchased int,
cart_abandoned int,
rating	int,
payment_Method varchar(30));

-- creating copy of raw_table
create table sales
(select * from sales_raw);

                                         -- Data Cleaning
-- Handling Inconsistent Price
-- Updated unit_price
update sales
set unit_price = case when unit_price like '%$%' then Trim(Replace(unit_price,'$',''))
					  when unit_price like '%USD%'  then Trim(Replace(unit_price,'USD',''))
                      else Trim(unit_price) end;
                      

-- Triming extra spaces    
update sales
set 
    customer_id = TRIM(customer_id),
    session_id = TRIM(session_id),
    device_type = TRIM(device_type),
    user_type = TRIM(user_type),
    marketing_channel = TRIM(marketing_channel),
    region = TRIM(region),
    product_category = TRIM(product_category),
    payment_Method = TRIM(payment_method);
    
-- Updating Payment failed
update sales
set payment_Method = 'Payment Failed'
where Payment = 1
and purchased = 0;

-- Updating No transactions as Unpaid payments
update sales
set payment_Method = 'Not Paid'
where payment_Method is null;

-- Checking duplicates (No duplicates found)
with cte as
(select *,row_number() over(partition by customer_id,session_id,product_id,visit_date 
                    order by customer_id) as rn 
from sales)

select *
from cte 
where rn>1;


-- Checking outliers 
-- No outliers in Unit_price (Normal distribution of price)
with stats as 
(select
    product_category,
    avg(unit_price)    as mean_price,
    stddev(unit_price) as std_price
  from sales
  group by product_category
)
select
  s.product_category,
  s.unit_price,
  st.mean_price,st.std_price
from sales s
join stats st using (product_category)
where s.unit_price > st.mean_price + 3* st.std_price
 or s.unit_price < st.mean_price - 3* st.std_price;
 
 
 -- No outliers in Revenue
 with ranking as
(select revenue,ntile(4) over(order by revenue) as quartile
from sales
where revenue > 0),

Qtl as 
(select max(case when quartile = 1 then revenue end) as Q1,
       max(case when quartile = 3 then revenue end) as Q3
from ranking),

Bounds as
(select Q1,Q3,(Q3-Q1) as IQR,
      Q1-1.5*(Q3-Q1) as lower_bound,
      Q3+1.5*(Q3-Q1) as upper_bound
from qtl)

select *
from sales
cross join bounds
where revenue < lower_bound
 or revenue > upper_bound;
 
                                              
                                              -- Data Analysis

-- Overall Abandonment rate     
select concat(round(100*sum(cart_abandoned)/count(*),2),'%') as Overall_Abandonment_rate
from sales
where added_to_cart = 1;   


-- Conversion funnel
select count(*) as total_sessions,
      concat(round(100*sum(product_view)/count(*),2),'%') as stage_1_product_view,
      concat(round(100*sum(added_to_cart)/count(*),2),'%') as stage_2_added_to_cart,
      concat(round(100*sum(checkout)/count(*),2),'%') as stage_3_checkout,
      concat(round(100*sum(payment)/count(*),2),'%') as stage_4_payment,
      concat(round(100*sum(purchased)/count(*),2),'%') as stage_5_purchased
from sales;
   
   
-- Stage-by-Stage Drop-Off Rates
with funnel as 
(select sum(product_view) as stage_1,
       sum(added_to_cart) as stage_2,
       sum(checkout) as stage_3,
       sum(payment) as stage_4,
       sum(purchased) as stage_5
from sales),
       
funnel_steps as
(select 1 as step_num,'Product view' as stage,stage_1 as total_users from funnel
union 
select 2,'Add to cart',stage_2 from funnel
union
select 3,'Checkout',stage_3 from funnel
union
select 4,'Payment',stage_4 from funnel
union
select 5,'Purchased',stage_5 from funnel)

select step_num,stage,total_users,
	concat(round(100*(total_users - lag(total_users) over(order by step_num))/
             lag(total_users) over(order by step_num),2),'%') as drop_pct_from_prev
from funnel_steps;
  
  
-- Abandonment & Revenue lost by Device type  
select device_type,count(*) as total_sessions,
      sum(added_to_cart) as added_to_cart,
      sum(cart_abandoned) as abandoned,
      sum(purchased) as purchase,
     -- Sessions added to cart but never converted to purchase	
      concat(round(100*sum(cart_abandoned)/sum(added_to_cart),2),'%') as abandoned_rate_pct,
     -- Sessions added to cart & got converted
      concat(round(100*sum(purchased)/sum(added_to_cart),2),'%') as conversion_rate_pct,
     -- Average revenue for converted purchase
      round(avg(case when purchased =1 then revenue end),2) as avg_order_value,
     -- Estimated lost revenue due to abandonment
      sum(case when cart_abandoned =1 then ((unit_price*quantity)-discount_amount) end) as net_Lost_revenue
from sales
group by device_type
order by abandoned_rate_pct desc;                                            
                                   
  
-- Abandonment & Revenue gained by Marketing channel
select marketing_channel,count(*) as total_sessions,
       sum(added_to_cart) as add_to_cart,
       sum(purchased) as purchased,
       sum(cart_abandoned) as abandoned,
     -- Sessions added to cart but never converted to purchase
       concat(round(100*sum(cart_abandoned)/sum(added_to_cart),2),'%') as abandoned_rate_pct,
     -- Sessions added to cart & got converted
       concat(round(100*sum(purchased)/sum(added_to_cart),2),'%') as conversion_rate_pct,
     -- Average revenue for converted purchase
       round(avg(case when purchased=1 then revenue end),2) as avg_order_value,
	 -- Most abandoned channel ranked sequentially
       rank() over(order by round(100*sum(cart_abandoned)/sum(added_to_cart),2) desc) as abandonment_rank
from sales
group by marketing_channel 
order by abandoned_rate_pct desc;  
 
 
-- Abandonment by Region									
select region,
    -- Sessions added to cart but never converted to purchase
    concat(round(100*sum(cart_abandoned)/sum(added_to_cart),2),'%') as abandonment_rate_pct,
    -- Sessions added to cart & got converted
    concat(round(100*sum(purchased)/sum(added_to_cart),2),'%') as conversion_rate_pct,
     -- Average revenue for converted purchase
round(avg(case when purchased = 1 then revenue end),2) as avg_order_value
from sales
group by region
order by abandonment_rate_pct desc;
                       
                       
-- Abandonment by Region & User type											
with categorised as
(select region,user_type,
    -- Sessions added to cart but never converted to purchase
    concat(round(100*sum(cart_abandoned)/sum(added_to_cart),2),'%') as abandonment_rate_pct,
    -- Sessions added to cart & got converted
    concat(round(100*sum(purchased)/sum(added_to_cart),2),'%') as conversion_rate_pct
from sales
group by region,user_type)  

select c.*,case when abandonment_rate_pct >= 80 then 'Criticial'
                when abandonment_rate_pct >= 65 then 'High'
                when abandonment_rate_pct >= 50 then 'Medium'
                else 'Low' end as risk_tier,
			rank() over(order by abandonment_rate_pct desc) as priority_rank
from categorised as c;         


--  Abandonment & lost revenue by Product_category
with category_stats as
(select product_category,
       count(*) as total_sessions,
      sum(added_to_cart) as added_to_cart,
      sum(cart_abandoned) as abandoned,
      sum(purchased) as purchase,
    -- Sessions added to cart but never converted to purchase
     concat(round(100*sum(cart_abandoned)/sum(added_to_cart),2),'%') as abandonment_rate_pct,
    -- Sessions added to cart & got converted
     concat(round(100*sum(purchased)/sum(added_to_cart),2),'%') as conversion_rate_pct,
    -- Average unit price
      round(avg(unit_price)) as avg_unit_price,
    -- Estimated lost revenue due to abandonment
      sum(case when cart_abandoned =1 then ((unit_price*quantity)-discount_amount) end) as net_Lost_revenue
from sales
group by product_category),

Overall_loss as
(select sum(net_lost_revenue) as Overall_lost_revenue
from  category_stats)  

select c.*,concat(round(100*c.net_lost_revenue/o.overall_lost_revenue,2),'%') as pct_of_total_loss
from category_stats as c
cross join Overall_loss as o 
order by net_Lost_revenue desc;                     
                                              

-- Lost Revenue from abandonment
select count(*) as abandoned_sessions,
       -- Gross Lost Revenue before discounts
       sum(unit_price*quantity) as gross_lost_revenue,
       -- Net lost Revenue after discounts
       sum(unit_price*quantity)-sum(discount_amount) as net_lost_revenue,
       -- Discounts given on carts that never converted
       sum(discount_amount) as wasted_discount_value,
       -- Average abandoned cart value
       round(avg((unit_price*quantity)-discount_amount),2) as average_abandoned_cart_value
from sales
where cart_abandoned =1;   

                                           
-- Lost Revenue from abandonment by region
with region_loss as
(select region,count(*) as abandoned_sessions,
  round(avg((unit_price*quantity)-discount_amount),2) as average_abandoned_cart_value,
  sum(unit_price*quantity)-sum(discount_amount) as net_lost_revenue
from sales  
where cart_abandoned =1
group by region),  

overall_loss as
(select sum(net_lost_revenue) as Overall_lost_revenue
from region_loss)  

select r.*,
    concat(round((100*r.net_lost_revenue/o.overall_lost_revenue),2),'%') as pct_of_overall_loss,
	rank() over(order by r.net_lost_revenue desc) as loss_rank 
from region_loss as r 
cross join overall_loss as o;    


-- Recovery of loss if every region matches West region(Best Performer) 
with region_stats as
(select region,
  sum(added_to_cart) as added_to_cart,
  sum(cart_abandoned) as cart_abandoned,
  concat(round(100*sum(cart_abandoned)/sum(added_to_cart),2),'%') as abandoned_rate_pct,
  round(avg(unit_price*quantity *(1-discount_percent/100)),2) as average_cart_value
from sales 
group by region),

west_rate as
(select abandoned_rate_pct as benchmark_rate
from region_stats
where region = 'West')

select region,
       added_to_cart,
       cart_abandoned,
       abandoned_rate_pct,
       benchmark_rate,
      round(r.added_to_cart*(r.abandoned_rate_pct - w.benchmark_rate)/100) as recoverable_sessions,
      round(r.added_to_cart*(r.abandoned_rate_pct - w.benchmark_rate)/100*average_cart_value) as recoverable_revenue
from region_stats as r
cross join west_rate as w
where r.abandoned_rate_pct > w.benchmark_rate
order by r.abandoned_rate_pct desc;


-- Average_order_value for Converted vs Abandoned carts
select case when purchased=1 then 'Converted'
            when cart_abandoned=1 then 'Abandoned'
            else 'Browsed only' end as session_status,
	 count(*) as total_sessions,
     round(avg(unit_price*quantity),2) as avg_gross_cart_value,
     round(avg((unit_price*quantity)-discount_amount),2) as avg_net_cart_value,
     round(avg(unit_price),2) as avg_unit_price,
	 round(avg(pages_viewed), 2) as avg_pages_viewed,
     round(avg(time_on_site_sec),1) as avg_time_on_site_sec
from sales 
group by session_status
order by avg_unit_price desc;


-- Are high discounts reducing abandonment?
select case when discount_percent =0 then '0% - No Discount'
            when discount_percent between 1 and 10 then '1-10%'
            when discount_percent between 11 and 15 then '11-15%'
            when discount_percent between 16 and 20 then '16-20%'
            when discount_percent between 21 and 25 then '21-25%'
            else '26-30%' end as discount_band,
	 count(*) as total_sessions,
     sum(added_to_cart) as carts_added,
     sum(cart_abandoned) as abandoned_carts,
     sum(purchased) as total_purchases,
     concat(round(100*sum(cart_abandoned)/sum(added_to_cart),2),'%') as abandonment_rate_pct,
     concat(round(100*sum(purchased)/sum(added_to_cart),2),'%') as conversion_rate_pct
from sales
group by discount_band
order by discount_band;
 

-- Is less time on Page effecting the abandonment?
select case when time_on_site_sec between 0 and 299 then '1. 0-5 min'
	        when time_on_site_sec between 300 and 599 then '2. 5-10 min'
			when time_on_site_sec between 600 and 899 then '3. 10-15 min'
            when time_on_site_sec between 900 and 1199 then '4. 15-20 min'
            else '5. 20+ min' end as time_bucket,
            count(*) as total_sessions,
            sum(added_to_cart) as carts_added,
            sum(cart_abandoned) as carts_abandoned,
            sum(purchased) as Purchased,
            concat(round(100*sum(cart_abandoned)/sum(added_to_cart),2),'%') as abandonment_rate_pct,
            concat(round(100*sum(purchased)/sum(added_to_cart),2),'%') as conversion_rate_pct
from sales
group by time_bucket
order by time_bucket;

















                       
                                              
                                              
                                              
                                              
                                              
                                              

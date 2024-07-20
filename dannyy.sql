CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
select * from menu
select * from sales
select * from members

--What is the total amount each customer spent at the restaurant?

select sum(price) as total_sales,customer_id as Customer 
from dannys_diner.menu m join dannys_diner.sales s on s.product_id=m.product_id
group by customer_id
order by total_sales desc

--How many days has each customer visited the restaurant?

select count(order_date),customer_id  
from sales s 
group by customer_id
order by count(order_date) desc

--What was the first item from the menu purchased by each customer?

with cte as
(select customer_id,order_date,product_name,
dense_rank() over(partition by customer_id order by order_date asc) as rnk
from dannys_diner.sales s join dannys_diner.menu m on m.product_id=s.product_id
)
select customer_id,product_name
from cte
where rnk=1

--What is the most purchased item on the menu and how many times was it purchased by all customers?

select count(s.product_id) as most_prefered_item,product_name from dannys_diner.menu m
join dannys_diner.sales s on m.product_id=s.product_id
group by product_name
order by most_prefered_item desc

--Which item was the most popular for each customer?

with cte as 
(
select 
customer_id,product_name,count(m.product_id) as total_count,
dense_rank() over(partition by customer_id order by count(m.product_id) desc)as rnk
from dannys_diner.menu m 
join dannys_diner.sales s 
on m.product_id=s.product_id
group by customer_id,product_name)

select customer_id,product_name,total_count
from cte
where rnk=1

--Which item was purchased first by the customer after they became a member?

with member_first as
(
select me.join_date  as joining_date,me.customer_id ,
	s.order_date as ordering_date,s.product_id ,
	row_number() over(partition by me.customer_id order by s.order_date asc)as rnk 
from dannys_diner.members me 
inner join dannys_diner.sales s on s.customer_id=me.customer_id
and s.order_date>me.join_date)

select customer_id,product_name
from member_first 
inner join dannys_diner.menu on member_first.product_id=menu.product_id
where rnk=1
order by customer_id asc

--Which item was purchased just before the customer became a member?

with member_first as
(
select me.join_date  as joining_date,me.customer_id ,
	s.order_date as ordering_date,s.product_id ,
	row_number() over(partition by me.customer_id order by s.order_date desc )as rnk 
from dannys_diner.members me 
inner join dannys_diner.sales s on s.customer_id=me.customer_id
and s.order_date<me.join_date)

select customer_id,product_name
from member_first 
inner join dannys_diner.menu on member_first.product_id=menu.product_id
where rnk=1
order by customer_id asc

--What is the total items and amount spent for each member before they became a member?

SELECT 
  sales.customer_id, 
  COUNT(sales.product_id) AS total_items, 
  SUM(menu.price) AS total_sales
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
  ON sales.customer_id = members.customer_id
  AND sales.order_date < members.join_date
INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

with menu_price as 
(
select product_id 
,case when product_id=1 then price*20
else price*10 end as points
from dannys_diner.menu)

select sum(m.points) as total_points,s.customer_id 
from menu_price m 
join dannys_diner.sales s on s.product_id=m.product_id
group by s.customer_id
order by s.customer_id

--In the first week after a customer joins the program (including their join date) then earn 2* points 
--all the items not just sushi-how many points do customer A and B have at the end of a january

with cte as
(select s.customer_id,s.order_date,me.join_date,m.price,m.product_name,
case when product_name='sushi' then 2*m.price
when s.order_date between me.join_date and (me.join_date+ 6) then 2*m.price
else m.price end as new_price
from dannys_diner.sales s 
join dannys_diner.members me on me.customer_id=s.customer_id 
join dannys_diner.menu m on m.product_id=s.product_id
where s.order_date<='2021-01-31')

select customer_id,sum(new_price)*10 as total_price
from cte
group by customer_id
create table sales_sql_challenge(
	"customer_id" VARCHAR(1),
	"order_date" DATE,
	"product_id" NUMERIC
);

INSERT INTO sales_sql_challenge
	("customer_id", "order_date", "product_id")
values
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

create table menu_sql_challenge(
	"product_id" INTEGER,
  	"product_name" VARCHAR(5),
  	"price" NUMERIC
);
INSERT INTO menu_sql_challenge
	("product_id", "product_name", "price")
VALUES
  	('1', 'sushi', '10'),
  	('2', 'curry', '15'),
  	('3', 'ramen', '12');


create table members_sql_challenge(
	"customer_id" VARCHAR(1),
  	"join_date" DATE
);

INSERT INTO members_sql_challenge
	("customer_id", "join_date")
values
	('A', '2021-01-07'),
	('B', '2021-01-09');
---------------------------
--members_danny, menu_danny, sales-danny 


/*
1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
 */

--1. What is the total amount each customer spent at the restaurant?


select 
	customer_id,
	sum(price) as total_purchase
from sales_danny as s
INNER JOIN menu_danny as m 
	on m.product_id = s.product_id
group by customer_id
order by customer_id ;




WITH sales_menu_CTE as(
	select 
		customer_id,
		order_date,
		salesd.product_id,
		menud.product_name,
		menud.price
	from public.sales_danny as salesd
	left join public.menu_danny as menud
		on salesd.product_id = menud.product_id)
select 
	customer_id,
	sum(price) as total_price
from sales_menu_CTE
group by customer_id
order by customer_id;


--2. How many days has each customer visited the restaurant?

select
	customer_id,
	count(DISTINCT(order_date)) as counts_of_visit
from sales_danny 
group by customer_id
order by customer_id;


----AŞAğıdakki yöntem fazla uzun
WITH sales_menu_CTE as(
	select 
		customer_id,
		order_date,
		salesd.product_id,
		menud.product_name,
		menud.price
	from public.sales_danny as salesd
	left join public.menu_danny as menud
		on salesd.product_id = menud.product_id)
select
	customer_id,
	count(order_date) as count_of_visit				--müşterilerin kaç defa restorana geldiğini görmek için order_date leri saydık.
from sales_menu_CTE
group by customer_id
order by customer_id;


--3. What was the first item from the menu purchased by each customer?

WITH CTE as ( 
			select customer_id,
					rank() over (PARTITION by customer_id order by order_date asc) as rank,
					row_number() over (PARTITION by customer_id order by order_date asc) as rn,
					product_name
			from sales_danny as s
			INNER JOIN menu_danny as m
				on s.product_id = m.product_id )
select 
	customer_id,
	product_name,
	rn
from CTE 
where rn = 1; 

-- 
WITH CTE as ( 
			select customer_id,
					rank() over (PARTITION by customer_id order by order_date asc) as rank,
					row_number() over (PARTITION by customer_id order by order_date asc) as rn,
					product_name
			from sales_danny as s
			INNER JOIN menu_danny as m
				on s.product_id = m.product_id )
select 
	customer_id,
	product_name,
	rn
from CTE 
where rn >= 2;







WITH CTE as (select 
				customer_id,
				order_date,
				m.product_id, 
				product_name,
				rank() over (PARTITION by customer_id order by s.order_date asc ) as rank,
				row_number() over (PARTITION by customer_id order by s.order_date asc) as rn
			from sales_danny as s
			INNER JOIN menu_danny as m
				on s.product_id = m.product_id)
select
	customer_id,
	product_name,
	rn
from CTE 
where rn = 1;



--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select 
	customer_id,
	count(order_date) as count_of_order,
	product_name
from sales_danny as s
INNER JOIN menu_danny as m
	on s.product_id = m.product_id
group by product_name, customer_id
order by count(order_date) desc 
limit 3;





select
	product_name,
	COUNT(order_date) as count_of_order
from sales_danny as s
INNER JOIN menu_danny as m
	on s.product_id = m.product_id 
group by m.product_name 
order by count(order_date) desc
limit 1 ;




--5. Which item was the most popular for each customer?

WITH most_populer as (select
						customer_id,
						product_name,
						count(m.product_id) as order_count,
						DENSE_RANK() over (PARTITION by customer_id order by COUNT(customer_id) desc ) as rank
						from sales_danny as s
						INNER JOIN menu_danny as m
							on m.product_id = s.product_id
						group by customer_id ,m.product_name
)
select 
	customer_id,
	product_name,
	order_count
from most_populer 
where rank = 1;



--6. Which item was purchased first by the customer after they became a member? -- SOR

WITH jmember as (select
					mem.customer_id,
					s.product_id,
					ROW_NUMBER() over (PARTITIOn by mem.customer_id order by s.order_date ) as row_num
				from members_danny as mem
				INNER JOIN sales_danny as s
					on mem.customer_id = s.customer_id
					and s.order_date > mem.join_date
				)
select
	customer_id,
	product_name
from jmember
INNER JOIN menu_danny as m
	on jmember.product_id = m.product_id
where row_num = 1
order by customer_id asc;



--7. Which item was purchased just before the customer became a member?


WITH jmember as (select
					mem.customer_id,
					s.product_id,
					ROW_NUMBER() over (PARTITIOn by mem.customer_id order by s.order_date desc) as row_num
				from members_danny as mem
				INNER JOIN sales_danny as s
					on mem.customer_id = s.customer_id
					and s.order_date < mem.join_date
				)
select
	customer_id,
	product_name
from jmember
INNER JOIN menu_danny as m
	on jmember.product_id = m.product_id
where row_num = 1
order by customer_id asc;


--8. What is the total items and amount spent for each member before they became a member?

select 
	s.customer_id,
	count(product_name) as total_item,
	sum(price) as total_price
from members_danny as mem
INNER JOIN sales_danny as s
	on s.customer_id = mem.customer_id
	and s.order_date < mem.join_date
INNER JOIN menu_danny as m
	on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;




--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH pointsCTE as (select 
						product_id,
						case 
							when product_id = 1 then price * 20
							else price * 10
						end as points
					from menu_danny)
select 
	customer_id,
	sum(points) as total_points
from sales_danny as s
INNER JOIN pointsCTE as p
	on p.product_id = s.product_id
group by customer_id
order by customer_id ;


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


WITH CTE as (select 
				customer_id,
				join_date,
				join_date + interval '6 day' as valid_date,
				DATE_TRUNC('month', '2021-01-31':: DATE) + interval '1 month' - interval '1 day' as last_date
			from members_danny)
select
	s.customer_id,
	sum(case
			when m.product_name = 'sushi' then m.price * 2 * 10 
			when s.order_date between c.join_date and c.valid_date then m.price * 2 * 10
			else 10 * m.price
		end) as points
from sales_danny as s
INNER JOIN CTE as c
	on s.customer_id = c.customer_id
	and c.join_date <= s.order_date
	and s.order_date <= c.last_date
INNER JOIN menu_danny as m 
	on m.product_id = s.product_id
group by s.customer_id;



--Müşteri üye olduktan sonra ilk olarak hangi ürünü satın aldı?

select s.customer_id, s.order_date , mb.join_date, m.product_name
from sales s 
join menu m 
on s.product_id = m.product_id
join members mb 
on s.customer_id = mb.customer_id
order by 1,2;
-----------------------------------------------------------------
with order_date_table as (
select s.customer_id, mb.join_date, s.order_date ,  m.product_name,
dense_rank() over (partition by s.customer_id order by s.order_date  ) as ranked
from sales s 
right join menu m 
on s.product_id = m.product_id
right join members mb 
on s.customer_id = mb.customer_id
and mb.join_date <= s.order_date )
select customer_id, join_date, min(order_date) as first_order,  product_name
from order_date_table
where ranked = 1
group by customer_id,join_date, product_name
order by 1;
------------------------------------------------------------------------------------
--Which item was purchased just before the customer became a member?
--Müşteri üye olmadan hemen önce hangi ürün satın alındı?

select *
FROM(
select s.customer_id , s.order_date ,s.product_id, m.product_name , m.price , mb.join_date,
dense_rank () over(partition by mb.join_date order by s.order_date DESC) as first_member
--,rank() over(partition by mb.join_date order by s.order_date DESC) as first_member_rank,
--row_number() over(partition by mb.join_date order by s.order_date DESC) as first_member_row
from sales s
left join menu m on m.product_id = s.product_id 
left join members mb  on s.customer_id = mb.customer_id
where mb.join_date > order_date ) as ilk_siparisler
where first_member = 1;

--What is the total items and amount spent for each member before they became a member?
--Üye olmadan önce her üyenin toplam harcaması ve kalemleri ne kadardı?

select customer_id, sum(price) as sum_price, count(*) as total_items
from ( select s.customer_id , s.order_date ,s.product_id, m.product_name , m.price , mb.join_date,
dense_rank () over(partition by mb.join_date order by s.order_date DESC) as first_member
--,rank() over(partition by mb.join_date order by s.order_date DESC) as first_member_rank,
--row_number() over(partition by mb.join_date order by s.order_date DESC) as first_member_row
from sales s
left join menu m on m.product_id = s.product_id 
left join members mb  on s.customer_id = mb.customer_id
where mb.join_date > order_date ) as ilk_siparisler
group by customer_id 
order by customer_id ;

--If each $1 spent equates to 10 points and sushi has a 
--2x points multiplier - how many points would each customer have?
--Harcanan her 1 dolar 10 puana denk geliyorsa ve suşinin 2x puan çarpanı varsa, 
--her müşteri kaç puan kazanır?

select customer_id, sum(puanlar) as toplam_puan
from(
select s.customer_id , s.order_date ,s.product_id, m.product_name , m.price,
case when m.product_name = 'sushi' then price * 20 
else price * 10 
end as puanlar
from sales s
left join menu m on m.product_id = s.product_id) as birlesmis_tablo
group by customer_id 
order by 1;

------------------------------------------------------------------

--In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?
--Müşteri programa katıldıktan sonraki ilk hafta (katılım tarihi dahil) 
--sadece suşide değil tüm ürünlerde 2 kat puan kazanır - 
--Ocak ayı sonunda müşteri A ve B'nin kaç puanı vardır?


with puan_tablosu as (select s.customer_id ,
case when order_date between join_date and (join_date + interval '6 day') then price *20
	else
	case when product_name = 'sushi' then price *20
		else price * 10
			end
	end as puan ,
s.order_date, (join_date + interval '6 day') ,s.product_id, m.product_name , m.price , mb.join_date
from sales s
left join menu m on m.product_id = s.product_id 
left join members mb  on s.customer_id = mb.customer_id)
--where order_date < '2021-02-01' )
select customer_id, sum(puan) as toplam_puan
from puan_tablosu
group by customer_id ;

-----------------------------------------------------------------------------

WITH puan_tablosu as (select s.customer_id ,
case when order_date between join_date and (join_date + interval '6 day') then price *20
	else
	case when product_name = 'sushi' then price *20
		else price * 10
			end
	end as puan ,
s.order_date, (join_date + interval '6 day') ,s.product_id, m.product_name , m.price , mb.join_date
from sales s
left join menu m on m.product_id = s.product_id 
left join members mb  on s.customer_id = mb.customer_id
where order_date < '2021-02-01' and s.customer_id in ('A', 'B') )
select customer_id, sum(puan) as toplam_puan
from puan_tablosu
group by customer_id ;








 
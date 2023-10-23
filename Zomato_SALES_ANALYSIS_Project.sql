create database zomato_portfolio_project;
use zomato_portfolio_project;

drop table if exists goldusers_signup;
create table goldusers_signup(user_id int,gold_signup_date date);
insert into goldusers_signup(user_id,gold_signup_date) values(1,'2017-09-22'),(3,'2017-04-21'); 
select * from goldusers_signup;
#--------------------------------------------------------------------------------------------------------#

drop table if exists users;
create table users(user_id int,signup_date date);
insert into users values(1,'2014-09-02'),(2,'2015-01-15'),(3,'2014-04-11');
select * from users;
#-------------------------------------------------------------------------------------------------------#

drop table if exists sales;
create table sales(user_id int, created_date date,product_id int);

INSERT INTO sales(user_id,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);

select * from sales;

#--------------------------------------------------------------------------------------------------#

drop table if exists product;

create table product (product_id int primary key,product_name char(20),price int);
insert into product values(1,'p1',980),(2,'p2',870),(3,'p3',330);

select * from product;

#--------------------------------------------------------------------------------------------------#
# now we will be starting with the questions:-->
#-------------------------------------------------------------------------------------------------------------#

# Question No.1:-> # what is the total amount each customer spents on zomato?
select s.user_id,s.product_id,sum(p.price) from sales s inner join product p on s.product_id=p.product_id group by user_id order by user_id;

#----------------------------------------------------------------------------------------------------------------------------------------------------------

# Question No. 2:-># How many days has each customer visited zomato?
select user_id, count(distinct(created_date)) as count_of_Visit
from sales 
group by user_id 
order by user_id;
 
#-------------------------------------------------------------------------------------------------------------------------------------------------------------

# Question No. 3:-> what was the first product purchased by each customer?
select * from 
(select *, rank() over(partition by user_id order by created_date) as rnk from sales) as d
where rnk=1;  
#-------------------------------------------------------------------------------------------------------------------------

# Question No. 4:-> what is the most purchased item on the menu and how many times was it purchased by all customers?
select user_id, count(product_id) as cnt from sales where product_id=
(SELECT product_id
    FROM sales
    GROUP BY product_id
    ORDER BY COUNT(product_id) DESC
    LIMIT 1) group by user_id;   
    
#---------------------------------------------------------------------------------------------------------------------------------
    
#5.  what item was the most popular for each of the customer?
select * from 
(select * , rank() over(partition by user_id order by cnt desc) as rnk from
(select user_id , product_id, count(product_id) as cnt from sales group by user_id,product_id) as d) as e where rnk=1;

#---------------------------------------------------------------------------------------------------------------------------------------------------------------

# 6. which item was purchased first by the customer after they become a member ?
select * from 
(select *, rank() over ( partition by user_id order by created_date ) as rnk from 
(select s.user_id, s.created_date,s.product_id,g.gold_signup_date from sales as s inner join goldusers_signup as g on s.user_id = g.user_id 
where s.created_date>= g.gold_signup_date  order by created_date asc) as b ) as e where rnk = 1 ;      

#---------------------------------------------------------------------------------------------------------------------------------------------------------

# 7. which item was purchased just before the customer became a member?  same as above but oppposite. 
select * from 
(select *, rank() over ( partition by user_id order by created_date desc) as rnk from 
(select s.user_id, s.created_date,s.product_id,g.gold_signup_date from sales as s inner join goldusers_signup as g on s.user_id = g.user_id 
where s.created_date<= g.gold_signup_date  order by created_date asc) as b ) as e where rnk = 1 order by user_id;

#--------------------------------------------------------------------------------------------------------------------------------------------------------

#8.  what is the total orders and amount spent for each member before they became a member? 

select user_id, count(created_date) as order_purchased , sum(price) as total_amt_spent from
(select c.*, d.price from 
(select a.user_id, a.created_date, a.product_id , b.gold_signup_date from sales as a inner join goldusers_signup as b on a.user_id= b.user_id 
and created_date<= gold_signup_date) c inner join product d on c.product_id=d.product_id ) e group by user_id ;

#---------------------------------------------------------------------------------------------------------------------------------------------------

/*
 # 9.(a)if buying each product generates points, for eg. 5rs= 2 zomato point and each product has differnt purchasing points
for eg. for p1 5rs=1 zomato point ,for p2 10rs= 5 zomato point and p3 5rs =1 zomato point .

calculate points collected by each customers and for which product most points have been given till now.  
*/

select user_id, sum(total_points) total_points_earned from 
(select e.*, amt/points total_points from 
(select d.*, case when product_id=1 then 5 when product_id =2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.user_id, c.product_id, sum(price) amt from 
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) c 
group by user_id, product_id) as d) e ) f  group by user_id   ;

#9.(b) and for which product most points have been given till now.

select * from 
(select * , rank() over (order by total_points_earned desc) rnk from 
(select product_id, sum(total_points) total_points_earned from 
(select e.*, amt/points total_points from 
(select d.*, case when product_id=1 then 5 when product_id =2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.user_id, c.product_id, sum(price) amt from 
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) c 
group by user_id, product_id) as d) e ) f  group by product_id ) g) h where rnk=1 ;


#-----------------------------------------
# EXTRA 
#9.  agar aisa kuch puche ki cash back kitna hua hai toh below :-
select user_id, sum(total_points) * 2.5 total_cashback_earned from 
(select e.*, amt/points total_points from 
(select d.*, case when product_id=1 then 5 when product_id =2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.user_id, c.product_id, sum(price) amt from 
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) c 
group by user_id, product_id) as d) e ) f  group by user_id   ;

# 2.5 is taken from :- (if buying each product generates points, for eg. 5rs= 2 zomato point ) this line of the question. 
 
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
# 10. In the first 1 year after a customer joins the gold program (including their join date ) irrespective of 
what the customer has purchased they earn 5 zomato points for every 10 rs spent. who earned more, 1 or 3 ? 
and what was their points earning in their 1st year?

*/
select c.*, d.price*0.5 total_points_earned from 
(select a.user_id,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b on a.user_id=b.user_id and 
created_date>= gold_signup_date and created_date<= date_add(gold_signup_Date, INTERVAL 1 YEAR ) ) C inner join product d on c.product_id=d.product_id ;

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# 11. Rank all the transactions of the customers?
select *, rank() over(partition by user_id order by created_date) rnk from sales;

#---------------------------------------------------------------------------------------------------------------------------------------------------------

#12. Rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction mark as NA?

select e.*, case when rnk =0  then 'NA' else rnk end  as rnkk from 
(select c.*, cast((case when gold_signup_date is null then 0 else rank() over(partition by user_id order by created_date desc) end )as char(10)) as rnk from
(select a.user_id, a.created_date, a.product_id, b.gold_signup_date from sales a left join goldusers_signup b on a.user_id=b.user_id and created_date>= gold_signup_date) c) e;

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

##########------------------------------COMMPLETE ZOMATO_SalesAnalysis_PROJECT--------------------------------------------########################





SELECT * FROM plans ;
SELECT * FROM subscriptions ;

-----------------------------------------------
-- A. Customer Journey Summary of 8 samples
SELECT 
	s.customer_id,
	p.plan_name,
	s.start_date
FROM subscriptions s
LEFT JOIN plans p
ON s.plan_id = p.plan_id
WHERE s.customer_id <= 8;

-----------------------------------------------
-- B. Data Analysis Question

-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS customers
FROM subscriptions ;


-- 2. What is the monthly distribution of trial plan start_date values 
-- use the start of the month as the group by value
SELECT EXTRACT(MONTH FROM start_date) AS month,
	TO_CHAR(start_date, 'Mon') AS monthname,
	COUNT(start_date)
FROM subscriptions
WHERE plan_id = 0
GROUP BY EXTRACT(MONTH FROM start_date), monthname
ORDER BY EXTRACT(MONTH FROM start_date) ;

-- 3. What plan start_date values occur after the year 2020 for our dataset? 
-- Show the breakdown by count of events for each plan_name
SELECT plan_id,
	COUNT(plan_id) AS transaction
FROM subscriptions 
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY plan_id;

-- 4. What is the customer count & percent of customers 
-- who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT customer_id) AS churn_customer,
	ROUND( COUNT(DISTINCT customer_id) * 100.0 / 
	(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) , 4) AS pct
FROM subscriptions
WHERE plan_id = 4 ;


-- 5. How many customers have churned straight after their initial free trial 
-- what percentage is this rounded to the nearest whole number? 
WITH user_history AS(
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS user_activity_count
FROM subscriptions s ),
pivot AS(
SELECT customer_id,
         MIN(CASE WHEN user_activity_count = 1 THEN plan_id END) AS first_plan,
         MAX(CASE WHEN user_activity_count = 2 THEN plan_id END) AS second_plan
  FROM user_history 
  GROUP BY customer_id
)
SELECT COUNT(customer_id) churn_after_trial,
	COUNT(customer_id) * 100.0 /
		(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS pct
FROM pivot 
WHERE first_plan = 0 AND second_plan = 4;


-- 6.What is the number and percentage of customer plans after their initial free trial?
WITH user_journey AS(
SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS user_activity
FROM 
	subscriptions),
after_trial AS(
SELECT u.plan_id,
	p.plan_name,
	COUNT(u.plan_id) AS status
FROM user_journey u
LEFT JOIN plans p 
ON u.plan_id = p.plan_id
WHERE user_activity = 2
GROUP BY u.plan_id, p.plan_name)
SELECT *,
	status / (SELECT SUM(status) FROM after_trial) * 100.0 AS pct
FROM after_trial;


-- 7. What is the customer count and percentage breakdown of 
-- all 5 plan_name values at 2020-12-31?

WITH activity AS(
SELECT customer_id,
	MAX(plan_id) AS plan_id
FROM subscriptions
WHERE start_date <= '2020-12-31' 
GROUP BY customer_id),
plan_category AS(
SELECT a.plan_id,
	p.plan_name,
	COUNT(customer_id) AS total
FROM activity a
LEFT JOIN plans p
ON a.plan_id = p.plan_id 
GROUP BY a.plan_id, p.plan_name
ORDER BY 1)
SELECT *,
	total / (SELECT SUM(total) FROM plan_category) * 100.0 AS pct
FROM plan_category ;


-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT *,
ROW_NUMBER() OVER() AS annual_user
FROM subscriptions
WHERE plan_id = 3 AND EXTRACT(YEAR FROM start_date) <= 2020;


-- 9. How many days on average does it take for a customer 
-- to an annual plan from the day they join Foodie-Fi?
WITH annual_user AS(
SELECT *
FROM subscriptions
WHERE plan_id = 3),
trial_user AS(
SELECT *
FROM subscriptions 
WHERE plan_id = 0),
list AS(
SELECT a.customer_id,
	a.start_date AS annual_date,
	t.start_date AS trial_date,
	a.start_date  - t.start_date AS days
FROM annual_user a
LEFT JOIN trial_user t
ON a.customer_id = t.customer_id)
SELECT ROUND(AVG(days),0) AS day_to_annual
FROM list;

-- 10. Can you further breakdown the average value of number 9
-- into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH annual_user AS(
SELECT *
FROM subscriptions
WHERE plan_id = 3),
trial_user AS(
SELECT *
FROM subscriptions 
WHERE plan_id = 0),
list AS(
SELECT a.customer_id,
	a.start_date AS annual_date,
	t.start_date AS trial_date,
	a.start_date  - t.start_date AS days
FROM annual_user a
LEFT JOIN trial_user t
ON a.customer_id = t.customer_id),
groupped AS(
SELECT *,
	CASE 
		WHEN days BETWEEN 0 AND 30 THEN '1. 0-30 days'
		WHEN days BETWEEN 31 AND 60 THEN '2. 31-60 days'
		WHEN days BETWEEN 61 AND 90 THEN '3. 61-90 days'
        WHEN days BETWEEN 91 AND 120 THEN '4. 91-120 days'
        WHEN days BETWEEN 121 AND 150 THEN '5. 121-150 days'
        WHEN days BETWEEN 151 AND 180 THEN '6. 151-180 days'
        WHEN days BETWEEN 181 AND 210 THEN '7. 181-210 days'
        WHEN days BETWEEN 211 AND 240 THEN '8. 211-240 days'
        WHEN days BETWEEN 241 AND 270 THEN '9. 241-270 days'
        WHEN days BETWEEN 271 AND 300 THEN '9a. 271-300 days'
        ELSE '9b. 300+ days'
	END AS day_bucket
FROM list) 
SELECT day_bucket, 
	COUNT(day_bucket)
FROM groupped
GROUP BY day_bucket 
ORDER BY day_bucket ;

-- 11. How many customers downgraded 
-- from a pro monthly to a basic monthly plan in 2020?
WITH pro AS(
SELECT * 
FROM subscriptions
WHERE plan_id = 2),
basic AS(
SELECT * 
FROM subscriptions 
WHERE plan_id = 1),
join_table AS(
SELECT p.customer_id AS id,
	p.plan_id AS pro,
	b.plan_id AS basic
FROM pro p
LEFT JOIN basic b
ON p.customer_id = b.customer_id)
SELECT COUNT(*) AS downgrade_user
FROM join_table 
WHERE pro = 2 AND basic = 1 ;






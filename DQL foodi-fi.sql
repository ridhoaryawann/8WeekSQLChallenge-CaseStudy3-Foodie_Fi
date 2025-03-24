SELECT * FROM plans ;

SELECT * FROM subscriptions ;


-- A. Customer Journey Summary

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



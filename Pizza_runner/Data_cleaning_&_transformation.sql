-- Data Cleaning & Transformation 

-- customer_orders 
DROP TABLE IF EXISTS temp_customer_orders;

CREATE TEMP TABLE temp_customer_orders AS
SELECT
  order_id,
  customer_id,
  pizza_id,
  CASE
    WHEN exclusions = '' OR exclusions = 'null' THEN NULL
    ELSE exclusions
  END AS exclusions,
  CASE
    WHEN extras = '' OR extras = 'null' THEN NULL
    ELSE extras
  END AS extras,
  order_time
FROM customer_orders;

SELECT *
FROM temp_customer_orders;

-- runner_orders
DROP TABLE IF EXISTS temp_runner_orders;

CREATE TEMP TABLE temp_runner_orders AS
SELECT 
	order_id,
	runner_id,
	CASE 
		WHEN pickup_time ='null' THEN NULL
		ELSE pickup_time
	END AS pickup_time,
	CASE 
		WHEN distance ='null' THEN NULL
		ELSE CAST(regexp_replace(distance, '[a-z]+', '')AS FLOAT)
	END AS distance,
	CASE 
		WHEN duration ='null' THEN NULL
		ELSE CAST(regexp_replace(duration, '[a-z]+','')AS FLOAT)
	END AS duration,
	CASE
		WHEN cancellation = '' OR cancellation ='null' THEN NULL
		ELSE cancellation 
	END AS cancellation
FROM runner_orders;

SELECT*
FROM temp_runner_orders;
		
	
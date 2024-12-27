-- q1. How manyd pizzas were ordered?

SELECT COUNT(*) AS pizzas_ordered
FROM temp_customer_orders;

-- q2 How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM temp_customer_orders;

-- q3 How many successful orders were delivered by each runner?

SELECT 
	runner_id,
    COUNT(DISTINCT order_id) AS order_delivered
FROM temp_runner_orders
WHERE distance > 0
GROUP BY 1; 

-- q4 How many of each type of pizza was delivered?
SELECT 
	pn.pizza_name, 
    COUNT(co.order_id) AS pizza_delivered 
FROM temp_customer_orders AS co 
INNER JOIN pizza_names AS pn
ON pn.pizza_id = co.pizza_id
INNER JOIN temp_runner_orders as ro
ON ro.order_id = co.order_id
WHERE ro.distance > 0
GROUP BY 1;

-- q5 How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
	co.customer_id,
	pn.pizza_name, 
    COUNT(co.pizza_id) AS pizza_ordered 
FROM temp_customer_orders AS co 
INNER JOIN pizza_names AS pn
ON pn.pizza_id = co.pizza_id
GROUP BY 1,2
ORDER BY 1;

-- q6 What was the maximum number of pizzas delivered in a single order?

SELECT
	co.order_id,
	COUNT(co.pizza_id) AS pizza_delivered
FROM temp_customer_orders AS co
INNER JOIN temp_runner_orders AS ro
ON ro.order_id = co.order_id
WHERE distance > 0 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- q7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?\

SELECT 
	customer_id,
    SUM( CASE WHEN (extras IS NOT NULL) 
						OR (exclusions IS NOT NULL) THEN 1
    ELSE 0 END) AS atleast_1_change,
    COUNT(*) - SUM( CASE WHEN (extras IS NOT NULL )
               OR (exclusions IS NOT NULL) THEN 1
    ELSE 0 END) AS no_change
FROM temp_customer_orders AS co 
INNER JOIN temp_runner_orders AS ro
ON ro.order_id = co.order_id
WHERE distance > 0 
GROUP BY customer_id
ORDER BY customer_id;

-- q8 How many pizzas were delivered that had both exclusions and extras?

SELECT 
	customer_id,
	COUNT(pizza_id) AS pizzas_delivered_with_both_changed
FROM temp_customer_orders AS co 
INNER JOIN temp_runner_orders AS ro
ON ro.order_id = co.order_id
WHERE distance > 0
	 AND extras IS NOT NULL AND exclusions IS NOT NULL
GROUP BY customer_id;
-- q9 What was the total volume of pizzas ordered for each hour of the day?

SELECT 
	COUNT(co.order_id) AS total_volume,
	EXTRACT(HOUR FROM co.order_time) AS hour_of_day
FROM temp_customer_orders AS co
GROUP BY 2
ORDER BY 2;

-- q10 What was the volume of orders for each day of the week?
SELECT 
	COUNT(co.order_id) AS total_volume,
	EXTRACT(dow FROM co.order_time) AS DAY
FROM temp_customer_orders AS co
GROUP BY 2
ORDER BY 2;

/* Section B 
	q1 How many runners signed up for each 1 week period? */ 

SELECT 
	COUNT(runner_id) AS registered_runner,
	EXTRACT(week FROM registration_date) AS each_week,
	DATE_TRUNC('week',registration_date)
FROM runners
GROUP BY 2,3;

-- q2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT 
	runner_id,
	ROUND(AVG(EXTRACT(EPOCH FROM(tro.pickup_time::TIMESTAMP - order_time))/60),2) AS delivery_minutes
FROM temp_runner_orders as tro
INNER JOIN temp_customer_orders AS tco
ON tco.order_id = tro.order_id
WHERE pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 2; 

-- DIVIDED BY 60 to change from seconds to minutes

--q3 Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH number_of_order AS(
SELECT 
	tco.order_id,
	COUNT(tco.order_id) AS number_of_pizza,
	EXTRACT(EPOCH FROM(tro.pickup_time::TIMESTAMP - tco.order_time))/60 AS preparation_time
FROM temp_customer_orders AS tco
INNER JOIN temp_runner_orders AS tro
ON tco.order_id = tro.order_id
WHERE pickup_time IS NOT NULL
GROUP BY 1,3
)
SELECT 
	number_of_pizza,
	AVG(preparation_time) AS average_preparation_time
FROM number_of_order	
GROUP BY 1
ORDER BY 1;

--q4 What was the average distance travelled for each customer?

SELECT 
	tco.customer_id,
	ROUND(AVG(tro.distance)) AS avg_distance
FROM temp_runner_orders AS tro
INNER JOIN temp_customer_orders AS tco
ON tco.order_id = tro.order_id
GROUP BY 1;

--q5 What was the difference between the longest and shortest delivery times for all orders?
SELECT 
	MAX(duration) -MIN(duration) AS diff_delivery_time
FROM temp_runner_orders
WHERE duration IS NOT NULL;

-- q6 What was the average speed for each runner for each delivery and do you notice any trend for these values?


SELECT 
	runner_id,
	order_id,
	distance,
	AVG(distance / (duration ::NUMERIC/60)) AS avg_speed
FROM temp_runner_orders
WHERE duration IS NOT NULL
GROUP BY 1,2,3
ORDER BY 3;

--q7 What is the successful delivery percentage for each runner?


SELECT
	runner_id,
		SUM(CASE 
		WHEN pickup_time IS NULL THEN 0
		ELSE 1 
	END) AS succesful_delivery,
	COUNT(*) AS total_order,
		(SUM(CASE 
		WHEN pickup_time IS NULL THEN 0
		ELSE 1 END)::FLOAT/ COUNT(*))*100 AS pct_succesful_delivery
FROM temp_runner_orders
GROUP BY 1
ORDER BY 4 DESC;

-- PART C
-- q1 What are the standard ingredients for each pizza?
SELECT 
    pr.pizza_id,
	pn.pizza_name,
    topping AS topping_id,
	topping_name
FROM pizza_recipes AS pr
LEFT JOIN LATERAL unnest(string_to_array(pr.toppings, ',')) AS topping ON true
INNER JOIN pizza_toppings AS pt
ON pt.topping_id = CAST(topping AS INT)
INNER JOIN pizza_names AS pn
ON pn.pizza_id = pr.pizza_id
GROUP BY 1,2,3,4
 
-- q2 What was the most commonly added extra?

SELECT
	topping_name,
	COUNT(pizza_id) AS added_extra
FROM temp_customer_orders AS tco
LEFT JOIN  LATERAL unnest(string_to_array(tco.extras, ',')) AS extra ON true
INNER JOIN pizza_toppings AS pt
ON pt.topping_id= CAST(extra AS INT)
WHERE extras IS NOT NULL
GROUP BY 1;

--q3 What was the most common exclusion?

SELECT
	topping_name,
	COUNT(exclusions) AS exclusions_added
FROM temp_customer_orders AS tco
LEFT JOIN LATERAL unnest(string_to_array(tco.exclusions,','))AS exclude_id ON true
INNER JOIN pizza_toppings AS pt
ON pt.topping_id = CAST(exclude_id AS INT)
WHERE exclusions IS NOT NULL 
GROUP BY 1;

/* q4 Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/


WITH exclusions_name AS ( 
	SELECT
		order_id,
		string_agg(pt.topping_name,',') AS exclusions
FROM temp_customer_orders AS tco
LEFT JOIN LATERAL unnest(string_to_array(tco.exclusions,',')) AS exclude_id ON true
INNER JOIN pizza_toppings AS pt
ON pt.topping_id = CAST(exclude_id AS INT)	
WHERE exclusions IS NOT NULL
GROUP BY 1
),
extras_name AS(
SELECT
	order_id,
	string_agg(pt.topping_name,',') AS extras
FROM temp_customer_orders AS tco
LEFT JOIN LATERAL unnest(string_to_array(tco.extras, ',')) AS extras_id ON true
INNER JOIN pizza_toppings AS pt
ON pt.topping_id = CAST(extras_id AS INT)
WHERE extras IS NOT NULL
GROUP BY 1
)
SELECT 
	tco.customer_id,
	tco.order_id,
	pn.pizza_name,
	CASE
       WHEN en.exclusions IS NOT NULL THEN ' -Exclude ' || en.exclusions
             ELSE ''
         END ||
    CASE
        WHEN et.extras IS NOT NULL THEN ' -Extra ' || et.extras
        ELSE ''
    END AS order_description
FROM temp_customer_orders AS tco
INNER JOIN pizza_names AS pn
ON pn.pizza_id = tco.pizza_id
LEFT JOIN exclusions_name AS en
ON en.order_id = tco.order_id
LEFT JOIN extras_name AS et
ON et.order_id = tco.order_id
GROUP BY 1,2,3,4;

/* q5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" */

/*WITH pizza_ingredients AS (
  SELECT 
    pn.pizza_name,
    pr.toppings,
    pn.pizza_id
  FROM pizza_names AS pn
  INNER JOIN pizza_recipes AS pr
    ON pr.pizza_id = pn.pizza_id
)
SELECT 
	tco.order_id,
	pi.pizza_name,
	STRING_AGG(pt.topping_name,',') AS topping_ingredients
FROM pizza_ingredients AS pi
LEFT JOIN LATERAL unnest(string_to_array(pi.toppings,',')) AS S(topping_id) ON true
INNER JOIN pizza_toppings AS pt
ON pt.topping_id = CAST(S.topping_id AS INT)
LEFT JOIN temp_customer_orders AS tco
ON tco.pizza_id = pi.pizza_id
GROUP BY 1,2*/

WITH Ingredients AS (
    SELECT    tco.order_id,
              tco.pizza_id,
              pt.topping_name,
              CASE
                  WHEN pt.topping_id = ANY(string_to_array(tco.extras, ',')::INT[]) THEN '2x' || pt.topping_name
                  ELSE pt.topping_name
              END AS ingredient_with_extra
    FROM      temp_customer_orders AS tco 
CROSS JOIN LATERAL unnest(string_to_array((SELECT toppings FROM pizza_recipes WHERE pizza_id = tco.pizza_id), ',')::INT[]) AS r(topping_id)
INNER JOIN pizza_toppings AS pt USING(topping_id)
GROUP BY  1, 2, 3, pt.topping_id, tco.extras
),
Aggregated_Ingredients AS (
    SELECT   order_id,
             pizza_id,
             STRING_AGG(DISTINCT ingredient_with_extra, ', ' ORDER BY ingredient_with_extra) AS ingredients
    FROM     Ingredients
    GROUP BY 1, 2
)
SELECT   ai.order_id,
         CONCAT(pn.pizza_name, ': ',  ai.ingredients) AS order_description
FROM     Aggregated_Ingredients AS ai 
INNER JOIN pizza_names AS pn USING(pizza_id)
ORDER BY 1

--q6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH Og_Ingredients AS (
SELECT
	pt.topping_id,
	COUNT(*) AS base_ingredients
FROM pizza_recipes AS pr
INNER JOIN pizza_toppings AS pt
ON pt.topping_id = ANY(string_to_array(pr.toppings,','):: INT[])
GROUP BY 1
),
extras_Ingredients AS(
SELECT
	unnest(string_to_array(tco.extras,',')::INT[]) AS topping_id,
	COUNT(*) AS extra_ingredients
FROM temp_customer_orders AS tco
WHERE tco.extras IS NOT NULL
GROUP BY 1
),
All_ingredients AS(
  SELECT   
  	topping_id,
   (COALESCE(base_ingredients, 0) + COALESCE(extra_ingredients, 0)) as total_count
FROM Og_Ingredients AS og
FULL OUTER JOIN extras_Ingredients USING(topping_id)
)
SELECT   pt.topping_name,
         ai.total_count
FROM     All_Ingredients AS ai 
INNER JOIN pizza_toppings AS pt 
ON ai.topping_id = pt.topping_id
ORDER BY 2 DESC

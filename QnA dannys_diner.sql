-- q1 What is the total amount each customer spent at the restaurant? 

SELECT 
	s.customer_id,
    SUM(m.price) AS total_spent
FROM sales AS s
INNER JOIN menu AS m
ON m.product_id = s.product_id
GROUP BY s.customer_id;


-- q2 How many days has each customer visited the restaurant?

SELECT 
		customer_id,
		COUNT(DISTINCT order_date) AS number_of_visit
FROM sales
GROUP BY customer_id
ORDER BY COUNT(DISTINCT order_date) DESC;

-- q3 What was the first item from the menu purchased by each customer?

WITH sales_rank AS( 
SELECT
		s.customer_id,
		m.product_name AS first_item_purchased,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS first_item
FROM sales AS s
INNER JOIN menu AS m
ON m.product_id = s.product_id
)
SELECT 
	sr.customer_id,
	sr.first_item_purchased
FROM sales_rank AS sr
WHERE first_item = 1
GROUP BY sr.customer_id, first_item_purchased;


-- q4 What is the most purchased item on the menu and how many times was it purchased by all customers
	
SELECT 
	m.product_name,
	COUNT(s.product_id) AS purchased_item
FROM  menu AS m
INNER JOIN sales AS s
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY COUNT(s.product_id) DESC
LIMIT 1;
    

-- q5 Which item was the most popular for each customer? 

WITH most_popular_item AS(
SELECT 
	s.customer_id, 
    m.product_name,
	COUNT(s.product_id) AS purchased_count,
	DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS popular
FROM sales AS s
INNER JOIN menu AS m
ON m.product_id = s.product_id
GROUP BY 1,2
)
SELECT
	customer_id,
    product_name,
    purchased_count
FROM most_popular_item AS mpi
WHERE popular = 1;

-- q6 Which item was purchased first by the customer after they became a member?

WITH first_purchase AS(
SELECT 
	s.customer_id,
    s.product_id,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) AS first_item
FROM sales AS s
INNER JOIN members AS m
ON m.customer_id = s.customer_id
 AND  s.order_date >= m.join_date
)

SELECT
	fp.customer_id,
    me.product_name
FROM first_purchase AS fp
INNER JOIN menu AS me
ON fp.product_id = me.product_id
WHERE first_item =1;

-- q7 Which item was purchased just before the customer became a member?

WITH purchase_before_member AS(
SELECT 
	s.customer_id,
    s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS first_item
FROM sales AS s
INNER JOIN members AS m
ON m.customer_id = s.customer_id
AND m.join_date > s.order_date
)
SELECT 
	customer_id,
    product_name
FROM purchase_before_member AS pbm
INNER JOIN menu AS me
ON me.product_id = pbm.product_id
WHERE first_item = 1;

-- q8 What is the total items and amount spent for each member before they became a member?


SELECT
	s.customer_id,
    COUNT(s.product_id) AS total_items, 
    SUM(me.price) AS total_spent
FROM sales AS s
INNER JOIN members AS m
ON m.customer_id = s.customer_id
AND s.order_date < m.join_date
INNER JOIN menu AS me
ON s.product_id = me.product_id
GROUP BY s.customer_id;

-- q9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- $ 1 equal 10 points 
-- sushi 20 points for each $1

WITH cummulated_points AS(
SELECT 
	product_id,
    CASE WHEN product_id = 1 THEN price * 20 
    ELSE price * 10 END AS points_cummulated
FROM menu 
) 
SELECT 
	s.customer_id,
    SUM(cp.points_cummulated) AS total_points
FROM cummulated_points AS cp
INNER JOIN sales AS s
ON s.product_id = cp.product_id
GROUP BY 1;

-- q10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- first 2 weeks points 2x on all items

SELECT 
	me.customer_id,
    SUM(CASE WHEN s.order_date BETWEEN me.join_date AND (me.join_date + 6) THEN price*20
		ELSE 
			CASE WHEN m.product_id = 1 THEN price * 20 
			ELSE price * 10 END
		END) AS points_cummulated
FROM menu AS m
JOIN sales AS s
ON s.product_id = m.product_id
JOIN members AS me
ON me.customer_id = s.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY 1;
    

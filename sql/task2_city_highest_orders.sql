SELECT 
    u.city,
    SUM(o.amount) AS total_order_amount
FROM 
    users u
INNER JOIN 
    orders o
ON 
    u.user_id = o.user_id
GROUP BY 
    u.city
ORDER BY 
    total_order_amount DESC
LIMIT 1;

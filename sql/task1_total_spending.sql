SELECT 
    u.user_id,
    u.name,
    SUM(o.amount) AS total_spending
FROM 
    users u
LEFT JOIN 
    orders o
ON 
    u.user_id = o.user_id
GROUP BY 
    u.user_id, u.name
ORDER BY 
    total_spending DESC;

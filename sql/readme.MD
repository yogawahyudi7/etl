# Documentation for SQL Queries

## SQL Query Descriptions

The SQL queries in this project focus on performance optimization and readability while meeting business analysis requirements, especially when working with large datasets.

## Query 1: User Spending Summary

Description:

This query retrieves a summary of user spending by calculating the total amount spent by each user based on their orders. The query ensures all users are included in the result, even if they have not placed any orders.

- We join users and order on user id and sum the total spending, and group by take user_id and name.

## Query 2: City with Highest Total Order Amount

Description:

This query identifies the city with the highest total order amount by aggregating the total spending of users grouped by their city.

- We join users and orders and using inner join because we just need 1 city, so we make sure to have only data that in both table. Sum amount and group by city and we limited by 1 for taking the higest
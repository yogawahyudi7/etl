-- 1. Remove unnecessary joins: Ensure that only the required tables are joined.
-- 2. Use proper indexes: Index user_id in both users and orders for faster joins. Additionally, if filtering by city, indexing the city column in users will help.
-- 3. Avoid SELECT *: Specify only the columns needed to reduce memory usage.
-- 4. Optimize grouping/aggregations: Ensure proper use of group keys and filters to reduce redundant calculations.

-- INDEX QUERY
-- 1. this index is for join table for question number 1
CREATE INDEX idx_users_user_id ON users(user_id);
CREATE INDEX idx_orders_user_id ON orders(user_id);

--this is for question number 2
CREATE INDEX idx_users_city ON users(city);
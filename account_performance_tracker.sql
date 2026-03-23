-- ============================================================
-- PROJECT 2: Client Account Performance Tracker
-- Author: Ali Mugasa
-- Tools: SQL (SQLite)
-- Dataset: Bank client data (800 clients, 1500+ accounts, 19K+ transactions)
--
-- Business Context:
-- The client services team needs to identify growth opportunities
-- across the portfolio. These queries segment accounts by value,
-- track performance trends, and flag underserved clients who
-- could benefit from additional products.
-- ============================================================


-- ============================================================
-- Q1: Client ranking by total portfolio value
-- Business Question: Who are our highest-value clients?
-- ============================================================

SELECT
    c.client_id,
    c.first_name || ' ' || c.last_name AS client_name,
    c.geography,
    c.credit_score,
    COUNT(a.account_id) AS num_accounts,
    ROUND(SUM(a.balance), 2) AS total_portfolio_value,
    RANK() OVER (ORDER BY SUM(a.balance) DESC) AS value_rank
FROM clients c
JOIN accounts a ON c.client_id = a.client_id
WHERE c.exited = 0
GROUP BY c.client_id
ORDER BY value_rank
LIMIT 25;


-- ============================================================
-- Q2: Client segmentation by portfolio value tier
-- Business Question: How is our client base distributed by value?
-- ============================================================

WITH client_value AS (
    SELECT
        c.client_id,
        c.geography,
        c.is_active,
        SUM(a.balance) AS total_balance,
        COUNT(a.account_id) AS num_products
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    WHERE c.exited = 0
    GROUP BY c.client_id
)
SELECT
    CASE
        WHEN total_balance >= 200000 THEN 'Platinum (200K+)'
        WHEN total_balance >= 100000 THEN 'Gold (100K-200K)'
        WHEN total_balance >= 50000 THEN 'Silver (50K-100K)'
        WHEN total_balance >= 10000 THEN 'Bronze (10K-50K)'
        ELSE 'Basic (Under 10K)'
    END AS client_tier,
    COUNT(*) AS num_clients,
    ROUND(AVG(total_balance), 2) AS avg_balance,
    ROUND(AVG(num_products), 1) AS avg_products,
    ROUND(SUM(total_balance), 2) AS tier_total_balance
FROM client_value
GROUP BY client_tier
ORDER BY tier_total_balance DESC;


-- ============================================================
-- Q3: Product adoption by geography
-- Business Question: Which regions are underpenetrated for
--     specific products?
-- ============================================================

SELECT
    c.geography,
    a.product_type,
    COUNT(DISTINCT c.client_id) AS clients_with_product,
    ROUND(AVG(a.balance), 2) AS avg_balance,
    ROUND(SUM(a.balance), 2) AS total_balance
FROM clients c
JOIN accounts a ON c.client_id = a.client_id
WHERE c.exited = 0
GROUP BY c.geography, a.product_type
ORDER BY c.geography, total_balance DESC;


-- ============================================================
-- Q4: Average products per client — active vs inactive
-- Business Question: Do active clients hold more products?
-- ============================================================

SELECT
    CASE WHEN c.is_active = 1 THEN 'Active' ELSE 'Inactive' END AS status,
    COUNT(DISTINCT c.client_id) AS num_clients,
    COUNT(a.account_id) AS total_accounts,
    ROUND(COUNT(a.account_id) * 1.0 / COUNT(DISTINCT c.client_id), 2) AS avg_products_per_client,
    ROUND(AVG(a.balance), 2) AS avg_account_balance
FROM clients c
JOIN accounts a ON c.client_id = a.client_id
WHERE c.exited = 0
GROUP BY status;


-- ============================================================
-- Q5: Cross-sell opportunities — high-value clients with
--     fewer than 3 products
-- Business Question: Which valuable clients could we offer
--     additional products?
-- ============================================================

WITH client_summary AS (
    SELECT
        c.client_id,
        c.first_name || ' ' || c.last_name AS client_name,
        c.geography,
        c.credit_score,
        c.estimated_salary,
        COUNT(a.account_id) AS num_products,
        SUM(a.balance) AS total_balance,
        GROUP_CONCAT(a.product_type, ', ') AS current_products
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    WHERE c.exited = 0 AND c.is_active = 1
    GROUP BY c.client_id
)
SELECT
    client_id,
    client_name,
    geography,
    credit_score,
    num_products,
    ROUND(total_balance, 2) AS total_balance,
    current_products
FROM client_summary
WHERE num_products < 3 AND total_balance > 50000
ORDER BY total_balance DESC
LIMIT 20;


-- ============================================================
-- Q6: Month-over-month deposit trends by product type
-- Business Question: Which products are growing or declining?
-- ============================================================

WITH monthly_product AS (
    SELECT
        t.month,
        a.product_type,
        ROUND(SUM(t.total_deposits), 2) AS total_deposits
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    JOIN clients c ON t.client_id = c.client_id
    WHERE c.exited = 0
    GROUP BY t.month, a.product_type
),
with_lag AS (
    SELECT
        month,
        product_type,
        total_deposits,
        LAG(total_deposits) OVER (
            PARTITION BY product_type ORDER BY month
        ) AS prev_month_deposits
    FROM monthly_product
)
SELECT
    month,
    product_type,
    total_deposits,
    prev_month_deposits,
    ROUND(
        (total_deposits - prev_month_deposits) * 100.0 /
        NULLIF(prev_month_deposits, 0), 1
    ) AS pct_change
FROM with_lag
WHERE prev_month_deposits IS NOT NULL
ORDER BY month DESC, product_type
LIMIT 30;


-- ============================================================
-- Q7: Top clients by transaction volume (most engaged)
-- Business Question: Who are our most active clients by
--     transaction count?
-- ============================================================

SELECT
    c.client_id,
    c.first_name || ' ' || c.last_name AS client_name,
    c.geography,
    COUNT(DISTINCT t.month) AS active_months,
    SUM(t.num_transactions) AS total_transactions,
    ROUND(SUM(t.total_deposits), 2) AS total_deposits,
    ROUND(SUM(t.total_withdrawals), 2) AS total_withdrawals,
    ROW_NUMBER() OVER (ORDER BY SUM(t.num_transactions) DESC) AS activity_rank
FROM clients c
JOIN transactions t ON c.client_id = t.client_id
WHERE c.exited = 0
GROUP BY c.client_id
ORDER BY activity_rank
LIMIT 20;


-- ============================================================
-- Q8: Underserved high-income clients
-- Business Question: Which high-salary clients have low
--     product adoption?
-- ============================================================

WITH client_profile AS (
    SELECT
        c.client_id,
        c.first_name || ' ' || c.last_name AS client_name,
        c.estimated_salary,
        c.credit_score,
        c.geography,
        COUNT(a.account_id) AS num_products,
        SUM(a.balance) AS total_balance
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    WHERE c.exited = 0 AND c.is_active = 1
    GROUP BY c.client_id
)
SELECT
    client_id,
    client_name,
    geography,
    credit_score,
    ROUND(estimated_salary, 0) AS salary,
    num_products,
    ROUND(total_balance, 2) AS total_balance
FROM client_profile
WHERE estimated_salary > 80000
    AND num_products <= 1
    AND credit_score >= 650
ORDER BY estimated_salary DESC
LIMIT 20;


-- ============================================================
-- Q9: Geography performance summary
-- Business Question: How does each region compare on key
--     account metrics?
-- ============================================================

SELECT
    c.geography,
    COUNT(DISTINCT c.client_id) AS total_clients,
    COUNT(a.account_id) AS total_accounts,
    ROUND(COUNT(a.account_id) * 1.0 / COUNT(DISTINCT c.client_id), 2) AS products_per_client,
    ROUND(SUM(a.balance), 2) AS total_aum,
    ROUND(AVG(a.balance), 2) AS avg_account_balance,
    ROUND(AVG(c.credit_score), 0) AS avg_credit_score,
    ROUND(COUNT(DISTINCT CASE WHEN c.is_active = 1 THEN c.client_id END) * 100.0 /
        COUNT(DISTINCT c.client_id), 1) AS active_rate_pct
FROM clients c
JOIN accounts a ON c.client_id = a.client_id
WHERE c.exited = 0
GROUP BY c.geography
ORDER BY total_aum DESC;


-- ============================================================
-- Q10: Credit score distribution and product adoption
-- Business Question: Do higher credit clients hold more products
--     and higher balances?
-- ============================================================

WITH client_metrics AS (
    SELECT
        c.client_id,
        c.credit_score,
        CASE
            WHEN c.credit_score >= 750 THEN 'Excellent (750+)'
            WHEN c.credit_score >= 700 THEN 'Good (700-749)'
            WHEN c.credit_score >= 650 THEN 'Fair (650-699)'
            WHEN c.credit_score >= 600 THEN 'Below Average (600-649)'
            ELSE 'Poor (Below 600)'
        END AS credit_tier,
        COUNT(a.account_id) AS num_products,
        SUM(a.balance) AS total_balance
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    WHERE c.exited = 0
    GROUP BY c.client_id
)
SELECT
    credit_tier,
    COUNT(*) AS num_clients,
    ROUND(AVG(num_products), 2) AS avg_products,
    ROUND(AVG(total_balance), 2) AS avg_portfolio_value,
    ROUND(SUM(total_balance), 2) AS total_aum
FROM client_metrics
GROUP BY credit_tier
ORDER BY total_aum DESC;

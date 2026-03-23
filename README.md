# Client Account Performance Tracker — SQL

## Overview
This project analyzes client account performance to identify growth opportunities across a bank's portfolio. The goal is to surface underserved high-value clients, track product adoption trends, and help client services teams prioritize cross-sell and engagement strategies.

## Dataset
Three related tables modeling a bank's client portfolio:

| Table | Records | Description |
|-------|---------|-------------|
| `clients` | 800 | Client demographics, credit score, tenure, and activity status |
| `accounts` | 1,537 | Account-level data including product type and balance |
| `transactions` | 18,990 | Monthly transaction summaries per account (2024–2025) |

## Tools
- **SQL** (SQLite) — JOINs, CTEs, CASE statements, window functions (RANK, ROW_NUMBER, LAG), aggregations
- **DB Browser for SQLite** — Query execution and testing

## Business Questions Answered

| # | Question | SQL Techniques |
|---|----------|----------------|
| 1 | Who are our highest-value clients? | JOIN, RANK() window function |
| 2 | How is the client base distributed by value tier? | CTE, CASE, aggregation |
| 3 | Which regions are underpenetrated for specific products? | JOIN, GROUP BY multiple columns |
| 4 | Do active clients hold more products? | JOIN, conditional grouping |
| 5 | Which high-value clients are cross-sell opportunities? | CTE, GROUP_CONCAT, filtering |
| 6 | Which products are growing or declining month-over-month? | CTE, LAG() window function |
| 7 | Who are our most engaged clients by transaction volume? | ROW_NUMBER() window function, JOIN |
| 8 | Which high-income clients are underserved? | CTE, multi-condition filtering |
| 9 | How does each region compare on key metrics? | JOIN, multiple aggregations |
| 10 | Do higher credit clients hold more products and higher balances? | CTE, CASE, aggregation |

## Setup
1. Download or clone this repo
2. Open DB Browser for SQLite (free) or SQLiteOnline.com
3. Run `setup_tables.sql` to create tables
4. Import the three CSV files from the `data/` folder
5. Run queries from `account_performance_tracker.sql`

## Key Findings
- A significant number of high-balance, active clients hold only 1–2 products — strong cross-sell opportunity
- High-income clients with low product count represent untapped potential for investment accounts and credit products
- Product adoption varies meaningfully by geography, suggesting regional marketing strategies
- Active clients hold more products on average, reinforcing the link between engagement and product penetration

## Author
**Ali Mugasa, MBA** — [LinkedIn](https://linkedin.com) | alimugasa0@gmail.com

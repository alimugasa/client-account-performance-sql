-- ============================================================
-- SETUP: Create tables and import CSV data
-- Run this first in DB Browser for SQLite or SQLiteOnline
-- ============================================================

CREATE TABLE IF NOT EXISTS clients (
    client_id TEXT PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INTEGER,
    gender TEXT,
    geography TEXT,
    credit_score INTEGER,
    estimated_salary REAL,
    tenure_months INTEGER,
    is_active INTEGER,
    join_date TEXT,
    exited INTEGER,
    exit_date TEXT,
    exit_reason TEXT
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id TEXT PRIMARY KEY,
    client_id TEXT,
    product_type TEXT,
    balance REAL,
    open_date TEXT,
    has_credit_card INTEGER,
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id TEXT PRIMARY KEY,
    client_id TEXT,
    account_id TEXT,
    month TEXT,
    num_transactions INTEGER,
    total_deposits REAL,
    total_withdrawals REAL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- After creating tables, use DB Browser's "Import" feature
-- to load each CSV into its matching table.
-- File > Import > Table from CSV File

# Olist E-Commerce Customer & Sales Analytics

## Project Overview

This project analyzes the **Brazilian E-Commerce Public Dataset by Olist** using **SQL, SQLite, DBeaver, and Tableau Public**.

The goal of the project is to transform raw transactional data into business insights across:

- Sales performance
- Customer behavior and retention
- Product performance
- Payment behavior
- Delivery performance
- Customer satisfaction

The project follows an end-to-end analytics workflow:

**Raw Data → SQLite Database → SQL Analysis → Dashboard-Ready CSVs → Tableau Dashboards**

Most business analyses use **delivered orders only**, unless otherwise stated.

---

## Dataset

The project uses the **Brazilian E-Commerce Public Dataset by Olist**.

Dataset source:

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The dataset contains approximately 100,000 marketplace orders and includes information about:

- Customers
- Orders
- Order items
- Payments
- Reviews
- Products
- Sellers
- Geolocation
- Product category translations

### Important Customer Identifier

The dataset contains both:

- `customer_id`
- `customer_unique_id`

`customer_id` identifies the customer record associated with an individual order, while `customer_unique_id` is used to identify the same customer across multiple orders.

Therefore, this project uses **`customer_unique_id` for customer-level analysis**.

---

## Tools & Technologies

- **SQL**
- **SQLite**
- **DBeaver**
- **Tableau Public**
- **Git**
- **GitHub**
- **CSV**

### SQL Techniques Used

- Common Table Expressions (CTEs)
- Window functions
- `ROW_NUMBER()`
- `NTILE()`
- Conditional aggregation
- Subqueries
- Multi-table joins
- Date calculations
- Ranking
- Customer segmentation
- Cohort analysis
- Indexing
- Data validation

---

# Business Questions

## Sales Analysis

- How much product revenue does Olist generate?
- How do sales and order volume change over time?
- Which Brazilian states generate the most sales?
- Which product categories generate the most revenue?
- What are the highest-value orders?
- How concentrated are sales geographically?

## Customer Analysis

- What percentage of customers make repeat purchases?
- How frequently do customers place orders?
- Who are the highest-value customers?
- How do new and returning customers change over time?
- How long does it take customers to make a second purchase?
- How concentrated are sales among high-value customers?
- How can customers be segmented using RFM?
- How does customer retention vary across acquisition cohorts?

## Product Analysis

- Which products generate the most sales?
- Which products have the strongest repeat-purchase behavior?
- How concentrated are sales across the product catalog?
- Which categories have the highest average selling prices?
- How does product weight relate to freight cost?
- Which product categories are growing or declining?

## Payment Analysis

- Which payment methods are used most frequently?
- Which payment methods account for the largest share of payment value?
- How commonly do customers use installments?
- How does order value vary by payment method?

## Delivery Analysis

- How long do orders take to reach customers?
- How frequently are orders delivered later than estimated?
- How does delivery performance vary across Brazilian states?
- Which states experience the longest delivery times?
- How closely do actual delivery dates match estimated delivery dates?

## Customer Satisfaction Analysis

- What is the overall average review score?
- What percentage of reviews are positive?
- How does late delivery affect customer satisfaction?
- How does delay severity affect review scores?
- Which product categories have the highest and lowest customer satisfaction?
- How does customer satisfaction vary across sellers?
- Does order value relate to customer satisfaction?
- How does customer satisfaction change over time?

---

# Key Business KPIs

| KPI | Result |
|---|---:|
| Total Product Sales | **R$13.22M** |
| Total Freight Value | **R$2.20M** |
| Total Order Value | **R$15.42M** |
| Delivered Orders | **96,478** |
| Unique Customers | **93,358** |
| Average Order Value | **R$137.04** |
| Average Items per Order | **1.14** |
| Repeat Customers | **2,801** |
| Repeat Purchase Rate | **3.00%** |
| Average Delivery Time | **12.6 days** |
| Late Delivery Rate | **6.77%** |
| Average Review Score | **4.16 / 5** |
| Positive Review Rate | **78.93%** |

---

# Key Insights

## 1. Customer Retention Is Low

Only **3.0% of customers made at least two delivered purchases**.

This indicates that Olist's customer base is heavily dominated by one-time buyers and suggests an opportunity to improve repeat purchasing and customer retention.

The RFM analysis further divides customers into segments including:

- Loyal High Value
- At Risk Repeat
- Repeat Customers
- Recent High Value
- Recent One-Time
- Other One-Time

The largest segment is **Other One-Time**, representing almost half of the customer base.

---

## 2. Sales Are Concentrated Among Higher-Value Customers

Customers were divided into spending deciles based on their historical product spending.

The **highest-spending 10% of customers generate approximately 41% of product sales**.

The cumulative sales concentration analysis also shows that approximately the top half of customers account for more than 80% of total product revenue.

This suggests that a relatively small proportion of customers contributes a substantial share of revenue.

---

## 3. Credit Cards Dominate Payment Value

Payment value is heavily concentrated in credit-card transactions.

| Payment Method | Payment Value Share |
|---|---:|
| Credit Card | **78.5%** |
| Boleto | **18.0%** |
| Voucher | **2.2%** |
| Debit Card | **1.4%** |

Credit cards are by far the dominant payment method across the Olist marketplace.

---

## 4. Delivery Performance Varies by State

Delivery performance differs substantially across Brazil.

Some states experience relatively short average delivery times, while others require considerably longer periods for orders to reach customers.

The state-level analysis compares:

- Average delivery days
- Late delivery rate
- Delivered order volume

This geographic variation may reflect differences in logistics infrastructure, fulfillment distance, and regional carrier performance.

---

## 5. Delivery Delays Are Strongly Associated With Lower Customer Satisfaction

Customer satisfaction decreases substantially as delivery delays become more severe.

| Delivery Group | Avg. Review Score |
|---|---:|
| On Time / Early | **4.29** |
| 1–3 Days Late | **3.29** |
| 4–7 Days Late | **2.10** |
| 8+ Days Late | **1.70** |

Orders delivered on time or early receive substantially higher review scores than delayed orders.

The negative review rate also increases sharply as delays become more severe.

This is one of the clearest operational findings in the project and highlights the importance of reliable delivery performance for customer satisfaction.

---

## 6. Customer Satisfaction Varies Across Product Categories

Average review scores differ across product categories.

The analysis compares the **10 highest-rated** and **10 lowest-rated** categories, while requiring sufficient review volume to reduce the influence of very small samples.

Because reviews are recorded at the **order level**, an order containing products from multiple categories may contribute the same review to each category represented in that order.

---

# Tableau Dashboards

The project includes three Tableau dashboards that summarize the SQL analysis.

---

## Dashboard 1 — Executive Overview

This dashboard provides a high-level view of overall marketplace performance.

### KPIs

- Total Product Sales
- Total Orders
- Unique Customers
- Average Order Value
- Average Review Score

### Visualizations

- Monthly Product Sales
- Monthly Orders
- Sales by State
- Top Product Categories by Sales
- Payment Method Breakdown

![Olist E-Commerce Dashboard 1](Olist%20E-Commerce%20Customer%20%26%20Sales%20Analytics/Scripts/Dashboard/images/Olist%20E-Commerce%20Dashboard%201.png)

---

## Dashboard 2 — Customer & Retention Analytics

This dashboard focuses on customer behavior, value, segmentation, and retention.

### KPIs

- Unique Customers
- Repeat Customers
- Repeat Purchase Rate
- Average Customer Spend

### Visualizations

- New vs Returning Customers
- RFM Customer Segments
- Customer Sales Concentration
- Cohort Retention

![Olist E-Commerce Dashboard 2](Olist%20E-Commerce%20Customer%20%26%20Sales%20Analytics/Scripts/Dashboard/images/Olist%20E-Commerce%20Dashboard%202.png)

### Cohort Retention Note

Month 0 represents each customer's acquisition month and is therefore always **100%**.

Because post-purchase retention rates are much smaller, the Tableau heatmap color scale is capped at **1%** so differences between later retention periods remain visible.

---

## Dashboard 3 — Products, Delivery & Satisfaction

This dashboard focuses on product performance, logistics, and customer experience.

### KPIs

- Average Delivery Days
- Late Delivery Rate
- Average Review Score
- Positive Review Rate

### Visualizations

- Top Products by Sales
- Delivery Performance by State
- Delivery Delay vs Review Score
- Top & Bottom Product Categories by Review Score

![Olist E-Commerce Dashboard 3](Olist%20E-Commerce%20Customer%20%26%20Sales%20Analytics/Scripts/Dashboard/images/Olist%20E-Commerce%20Dashboard%203.png)

---

# Tableau Workbook

The complete Tableau packaged workbook is included in the repository:

```text
Olist E-Commerce Customer & Sales Analytics/
└── Scripts/
    └── Dashboard/
        └── tableau/
            └── olist_ecommerce_analytics_dashboard.twbx
```

The packaged workbook contains all three dashboards and their supporting Tableau worksheets.

---

# SQL Analysis Structure

The SQL scripts are organized by analytical area.

```text
Olist E-Commerce Customer & Sales Analytics/
└── Scripts/
    │
    ├── database/
    │   ├── 01_create_tables.sql
    │   ├── 02_create_indexes.sql
    │   └── 03_data_validation.sql
    │
    ├── sql/
    │   ├── 01_data_exploration.sql
    │   ├── 02_sales_analysis.sql
    │   ├── 03_customer_analysis.sql
    │   ├── 04_product_analysis.sql
    │   ├── 05_payment_analysis.sql
    │   ├── 06_delivery_analysis.sql
    │   ├── 07_customer_satisfaction.sql
    │   └── 08_business_kpis.sql
    │
    └── Dashboard/
        ├── Data/
        ├── images/
        └── tableau/
```

---

# Database Scripts

### `01_create_tables.sql`

Creates the relational tables used for the Olist dataset.

### `02_create_indexes.sql`

Creates indexes on frequently joined, filtered, and grouped columns to improve query performance.

### `03_data_validation.sql`

Performs validation checks on imported data, including:

- Row counts
- Missing values
- Key fields
- Duplicate records
- Table relationships
- Data consistency

---

# SQL Analysis Scripts

### `01_data_exploration.sql`

Initial exploration of:

- Orders
- Customers
- Products
- Sellers
- Dataset date coverage
- Order status distribution

### `02_sales_analysis.sql`

Analyzes:

- Product sales
- Monthly sales trends
- Order volume
- Average order value
- State-level sales
- Product-category sales

### `03_customer_analysis.sql`

Analyzes:

- Repeat purchase behavior
- Customer order frequency
- Highest-value customers
- New vs returning customers
- Time to second purchase
- Customer sales concentration
- RFM segmentation
- Cohort retention

### `04_product_analysis.sql`

Analyzes:

- Top-selling products
- Repeat purchasing by product
- Product sales concentration
- Category pricing
- Product weight
- Freight cost
- Category growth

### `05_payment_analysis.sql`

Analyzes:

- Payment methods
- Payment value share
- Installment usage
- Payment-method order value

### `06_delivery_analysis.sql`

Analyzes:

- Average delivery time
- Late-delivery rate
- Delivery performance by state
- Delivery estimates
- Delivery-delay severity

### `07_customer_satisfaction.sql`

Analyzes:

- Overall review KPIs
- Late delivery and satisfaction
- Delay severity and review scores
- Category satisfaction
- Seller satisfaction
- Order value and satisfaction
- Satisfaction trends over time

### `08_business_kpis.sql`

Creates dashboard-ready business metrics including:

- Overall business KPI snapshot
- Monthly KPI trends
- Monthly sales growth
- Delivery performance
- Customer satisfaction metrics

---

# Analytical Definitions

## Product Sales

Product sales are defined as:

```sql
SUM(order_items.price)
```

Freight is excluded from Product Sales.

---

## Freight Value

Freight value is calculated separately using:

```sql
SUM(order_items.freight_value)
```

---

## Total Order Value

```text
Total Order Value = Product Sales + Freight Value
```

---

## Average Order Value

Average Order Value is based on **product sales**, excluding freight.

---

## Unique Customer

Customers are identified using:

```text
customer_unique_id
```

rather than `customer_id`.

---

## Repeat Customer

A repeat customer is defined as a customer with:

```text
2 or more delivered orders
```

---

## Customer Monetary Value

Customer monetary value is calculated using:

```sql
SUM(order_items.price)
```

across the customer's delivered orders.

Freight is excluded.

---

## Positive Review

A positive review is defined as a review score of:

```text
4 or 5
```

---

## Negative Review

A negative review is defined as a review score of:

```text
1 or 2
```

---

## Late Delivery

An order is classified as late when:

```text
Actual Delivery Date > Estimated Delivery Date
```

---

# Review Data Handling

Some orders contain multiple review records.

To avoid double-counting, order-level review analysis keeps the **latest available review** using:

```sql
ROW_NUMBER() OVER (
    PARTITION BY r.order_id
    ORDER BY
        r.review_answer_timestamp DESC,
        r.review_creation_date DESC,
        r.review_id DESC
)
```

Only records with:

```text
review_rank = 1
```

are retained for order-level satisfaction analysis.

Review scores range from **1 to 5**, where higher values indicate greater customer satisfaction.

---

# RFM Customer Segmentation

Customers are segmented using three dimensions:

### Recency

Number of days since the customer's most recent delivered order.

### Frequency

Number of delivered orders placed by the customer.

### Monetary Value

Total product spending across delivered orders.

The resulting customer segments include:

- Loyal High Value
- At Risk Repeat
- Repeat Customers
- Recent High Value
- Recent One-Time
- Other One-Time

This analysis helps identify high-value customers, recently active customers, repeat customers, and customers potentially at risk of disengagement.

---

# Customer Sales Concentration

Customers are ranked by historical product spending and divided into **10 spending deciles** using:

```sql
NTILE(10)
```

Decile 1 represents the **highest-spending 10% of customers**, while Decile 10 represents the lowest-spending group.

A Pareto-style visualization is used to compare:

- Product sales by customer-spending decile
- Cumulative share of total product sales

---

# Cohort Retention Analysis

Customers are assigned to acquisition cohorts based on the month of their **first delivered purchase**.

Retention is then measured by:

```text
Months Since First Purchase
```

For each cohort, the analysis measures the percentage of customers who return and place another delivered order in later months.

---

# Dashboard Data

The SQL analysis outputs were exported as CSV files and used as independent Tableau data sources.

```text
Dashboard/
└── Data/
    ├── category_sales.csv
    ├── category_satisfaction.csv
    ├── cohort_retention.csv
    ├── customer_sales_concentration.csv
    ├── delay_satisfaction.csv
    ├── executive_kpis.csv
    ├── monthly_kpis.csv
    ├── new_vs_returning.csv
    ├── payment_methods.csv
    ├── product_sales_concentration.csv
    ├── rfm_segments.csv
    ├── sales_by_state.csv
    ├── state_delivery.csv
    ├── top_customers.csv
    └── top_products.csv
```

Each CSV is kept as an independent Tableau data source because the datasets operate at different analytical grains.

---

# Project Workflow

```text
Brazilian E-Commerce Raw CSV Files
                │
                ▼
          SQLite Database
                │
                ▼
      Data Validation & Indexing
                │
                ▼
         SQL Business Analysis
                │
                ▼
      Dashboard-Ready CSV Exports
                │
                ▼
          Tableau Public
                │
                ▼
       3 Analytics Dashboards
```

---

# Repository Structure

```text
SQL-Customer-and-Sales-Analysis/
│
└── Olist E-Commerce Customer & Sales Analytics/
    │
    └── Scripts/
        │
        ├── database/
        │   ├── 01_create_tables.sql
        │   ├── 02_create_indexes.sql
        │   └── 03_data_validation.sql
        │
        ├── sql/
        │   ├── 01_data_exploration.sql
        │   ├── 02_sales_analysis.sql
        │   ├── 03_customer_analysis.sql
        │   ├── 04_product_analysis.sql
        │   ├── 05_payment_analysis.sql
        │   ├── 06_delivery_analysis.sql
        │   ├── 07_customer_satisfaction.sql
        │   └── 08_business_kpis.sql
        │
        └── Dashboard/
            │
            ├── Data/
            │   ├── category_sales.csv
            │   ├── category_satisfaction.csv
            │   ├── cohort_retention.csv
            │   ├── customer_sales_concentration.csv
            │   ├── delay_satisfaction.csv
            │   ├── executive_kpis.csv
            │   ├── monthly_kpis.csv
            │   ├── new_vs_returning.csv
            │   ├── payment_methods.csv
            │   ├── product_sales_concentration.csv
            │   ├── rfm_segments.csv
            │   ├── sales_by_state.csv
            │   ├── state_delivery.csv
            │   ├── top_customers.csv
            │   └── top_products.csv
            │
            ├── images/
            │   ├── Olist E-Commerce Dashboard 1.png
            │   ├── Olist E-Commerce Dashboard 2.png
            │   └── Olist E-Commerce Dashboard 3.png
            │
            └── tableau/
                └── olist_ecommerce_analytics_dashboard.twbx
```

---

# Project Highlights

This project demonstrates experience with:

- Relational data analysis
- SQL query development
- Multi-table joins
- CTEs and subqueries
- Window functions
- Business KPI development
- Customer segmentation
- RFM analysis
- Cohort retention analysis
- Pareto / concentration analysis
- Geographic analysis
- Delivery-performance analysis
- Customer-satisfaction analysis
- Data validation
- Database indexing
- Tableau dashboard development
- Data visualization
- Business storytelling

---

# Notes & Limitations

- Most analyses use **delivered orders only** unless otherwise stated.
- Product Sales exclude freight.
- Product names are not provided in the original Olist dataset, so individual products are identified using `product_id`.
- Missing or unmatched product-category translations are retained as `Unknown` rather than being removed.
- Reviews are recorded at the **order level**, not the individual product level.
- Multi-category orders may therefore contribute the same order review to multiple product categories.
- For seller-level satisfaction analysis, only orders containing products from a single seller are used where seller attribution must be unambiguous.
- Newer acquisition cohorts naturally have fewer observable retention periods than older cohorts.
- The cohort-retention heatmap caps the color scale at 1% to make low post-purchase retention differences visible; Month 0 remains 100%.

---

# Dataset Attribution

**Brazilian E-Commerce Public Dataset by Olist**

Kaggle:

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The dataset is anonymized and publicly available for analytical and educational use.

---

# Author

**Dabin Choi**

GitHub:  
https://github.com/dabinchoi04

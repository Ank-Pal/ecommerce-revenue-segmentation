# 📖 Tableau Data Dictionary: Olist E-Commerce Data Models

This data dictionary outlines the metadata, data types, business definitions, and dimensional classifications for all fields in the **Olist Modeled Tableau Extract** (`data/processed/olist_modeled_tableau.csv`) and the **Regional Logistics Summary** (`data/processed/regional_revenue_logistics.csv`).

---

## 1. Primary Order Extract: `olist_modeled_tableau.csv`

| Field Name | Physical Type | Tableau Role | Description | Sample Value |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | String (32) | Dimension | Unique 32-character MD5 identifier of the order | `e481f51cbdc54678b7cc49136f2d6af7` |
| `customer_unique_id` | String (32) | Dimension | Unique identifier representing an individual consumer across multiple orders | `7c396fd4836f1a329e2adc7d5e1f0ec9` |
| `order_status` | String | Dimension | Operational state of the order (`delivered`, `shipped`, `canceled`) | `delivered` |
| `purchase_timestamp` | DateTime | Dimension (Date) | Timestamp when customer placed the transaction | `2017-10-02 10:56:33` |
| `purchase_date_key` | Integer | Dimension | Surrogate date key in `YYYYMMDD` format | `20171002` |
| `customer_delivered_timestamp` | DateTime | Dimension (Date) | Timestamp when carrier handed parcel to consumer | `2017-10-10 21:25:13` |
| `estimated_delivery_timestamp` | DateTime | Dimension (Date) | Target SLA delivery date communicated at checkout | `2017-10-18 00:00:00` |
| `order_total_value` | Decimal | Measure | Total merchandise value plus freight charges (Gross Revenue in BRL) | `452.80` |
| `total_freight_value` | Decimal | Measure | Total shipping charges billed for the order | `28.50` |
| `item_count` | Integer | Measure | Total units/items purchased in the order | `2` |
| `delivery_transit_days` | Integer | Measure | Total elapsed calendar days from purchase to delivery | `8` |
| `delivery_delay_days` | Integer | Measure | Variance in days between actual delivery and estimated SLA (positive = late) | `-8` |
| `delivery_delay_band` | String | Dimension | Categorical fulfillment interval (`Early`, `On-Time`, `Minor Delay`, etc.) | `2. On-Time (0-4d early)` |
| `is_delayed` | Integer | Dimension | Binary flag: `1` if delivered after estimated date, `0` if on-time or early | `0` |
| `review_score` | Integer | Measure | Customer satisfaction rating (1 to 5 stars) | `5` |
| `customer_state` | String (2) | Dimension (Geo) | 2-letter Brazilian state abbreviation (e.g., `SP`, `RJ`, `MG`) | `SP` |
| `customer_city` | String | Dimension | City of customer delivery residence | `Sao Paulo` |
| `macro_region` | String | Dimension | Brazilian macro-economic territory (`Southeast`, `South`, `Northeast`, etc.) | `Southeast` |
| `state_latitude` | Decimal | Measure (Geo) | Centroid latitude coordinate of Brazilian state | `-23.5505` |
| `state_longitude` | Decimal | Measure (Geo) | Centroid longitude coordinate of Brazilian state | `-46.6333` |
| `r_score` | Integer | Dimension | Recency quintile rank ($1$ to $5$; $5$ = most recent purchase) | `5` |
| `f_score` | Integer | Dimension | Frequency quintile rank ($1$ to $5$; $5$ = highest order count) | `4` |
| `m_score` | Integer | Dimension | Monetary quintile rank ($1$ to $5$; $5$ = highest lifetime spend) | `5` |
| `rfm_cell` | String (3) | Dimension | Concatenated 3-digit score cell (e.g., `545`) | `545` |
| `rfm_segment` | String | Dimension | Core business segment (`Champions (Top Tier)`, `Loyal Customers`, etc.) | `Champions (Top Tier)` |
| `customer_tier` | String | Dimension | Strategic rollup tier (`Top Tier (VIP)`, `Mid Tier`, `Low Tier`) | `Top Tier (VIP)` |
| `is_churned` | Integer | Dimension | Churn indicator: `1` if customer made no repeat order or inactive >180d | `0` |

---

## 2. Regional Summary: `regional_revenue_logistics.csv`

| Field Name | Physical Type | Tableau Role | Description | Sample Value |
| :--- | :--- | :--- | :--- | :--- |
| `state_code` | String (2) | Dimension (Geo) | Brazilian UF code | `SP` |
| `state_name` | String | Dimension | Full federative state name | `Sao Paulo` |
| `macro_region` | String | Dimension | Geographic macro-region | `Southeast` |
| `latitude` | Decimal | Measure (Geo) | Geographic latitude coordinate | `-23.5505` |
| `longitude` | Decimal | Measure (Geo) | Geographic longitude coordinate | `-46.6333` |
| `total_orders` | Integer | Measure | Cumulative order volume delivered to state | `42,813` |
| `total_customers` | Integer | Measure | Unique consumer count residing in state | `39,501` |
| `total_revenue_gmv` | Decimal | Measure | Total Gross Merchandise Value in Brazilian Reais (BRL) | `6,248,190.50` |
| `national_revenue_share_pct` | Decimal | Measure | State contribution to national gross revenue (%) | `39.2%` |
| `freight_burden_pct` | Decimal | Measure | Total freight cost expressed as percentage of GMV | `12.4%` |
| `avg_transit_days` | Decimal | Measure | Average transit duration from purchase to customer delivery | `7.8` |
| `avg_delay_days_when_late` | Decimal | Measure | Average days late for orders that breached delivery SLA | `4.6` |
| `delivery_delay_rate_pct` | Decimal | Measure | Percentage of orders experiencing delivery delays | `4.8%` |
| `avg_review_score` | Decimal | Measure | Average customer review score (1.0 to 5.0) | `4.32` |
| `vip_customers_count` | Integer | Measure | Number of top-tier VIP consumers residing in state | `3,912` |
| `vip_customer_density_pct` | Decimal | Measure | Percentage of state customer base classified as VIP | `9.9%` |
| `logistics_friction_index` | Decimal | Measure | Composite friction metric: `Delay_Rate * (5.0 - CSAT)` | `3.26` |

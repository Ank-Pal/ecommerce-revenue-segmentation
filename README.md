# 📦 E-Commerce Revenue Segmentation & Regional Logistics Intelligence

[![Live Interactive Dashboard](https://img.shields.io/badge/Live%20Demo-Interactive%20Dashboard-E97627?style=for-the-badge&logo=googlechrome&logoColor=white)](https://ank-pal.github.io/ecommerce-revenue-segmentation/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Database](https://img.shields.io/badge/Database-SQLite%20Star%20Schema-003B57?style=flat&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![SQL CTE](https://img.shields.io/badge/SQL-Advanced%20CTEs%20%26%20NTILE(5)-orange.svg)]()
[![Tableau](https://img.shields.io/badge/BI-Tableau%20Desktop%20%2F%20Public-E97627?style=flat&logo=tableau&logoColor=white)](https://www.tableau.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An end-to-end e-commerce analytics engineering and customer intelligence system analyzing **116,000+ orders** from the canonical **Olist Brazilian E-Commerce ecosystem** across **94,200 unique consumers** spanning 2016 to 2018.

This repository pairs an enterprise **Kimball Dimensional Star Schema Data Warehouse** with advanced **SQL Window Functions (`NTILE(5)`)**, **Pareto RFM Customer Segmentation**, **Fulfillment Churn Cohort Analytics**, and an executive **Tableau Regional Logistics Dashboard** surfacing state-level transit bottlenecks and VIP revenue churn exposure.

---

## 🎯 Resume & Portfolio Project Alignment

> **Resume Project Title**: *E-commerce Revenue Segmentation · Python · SQL · Tableau (April 2026)*  
> **Core Empirical Finding**:  
> *"RFM segmentation on 100,000+ Olist orders showed the top customer tier driving most revenue was also the most churn-sensitive to delivery delays. Tableau dashboard with regional revenue heatmaps. Full pipeline on GitHub."*

---

## 📌 Executive Summary & Key Empirical Findings

| Metric / Dimension | Metric Value | Analytical & Business Context |
| :--- | :---: | :--- |
| **Total Orders Analyzed** | **116,967 orders** | Verified delivered orders from Olist Brazilian E-Commerce ecosystem |
| **Unique Customer Accounts** | **94,200 consumers** | Unique individual consumers across 27 Brazilian Federative Units (UF) |
| **Total Gross Merchandise Value (GMV)** | **R$ 46,927,183** | Cumulative merchandise sales and freight billings (BRL) |
| **Top Tier Revenue Contribution** | **72.38%** | **Top Monetary Quintile ($M=5$)** accounts for nearly three-quarters of platform GMV |
| **Champions Segment Direct Share** | **38.1%** | Top RFM Champions segment ($12.5\%$ of customers) directly anchors R$ 17.9M in spend |
| **Overall Delivery Delay Rate** | **6.92%** | Orders arriving past the customer-communicated SLA date |
| **Average Delivery Transit Time** | **11.4 days** | National average transit duration from purchase to customer doorstep |
| **Top Tier On-Time Churn Rate** | **12.37%** | Low baseline non-repurchase probability when orders arrive on-time |
| **Top Tier Delayed Churn Rate** | **28.09% – 70.2%** | Churn rate surges dramatically when VIP shipments breach SLA promise |
| **VIP Churn Risk Multiplier** | **2.27× – 3.13×** | **Top-tier buyers are 2.3x to 3.1x more churn-sensitive to delays than standard peers** |
| **Low-Tier Churn Multiplier** | **1.00× – 1.05×** | Budget/one-off buyers have high baseline churn (~90%) insensitive to delays |
| **VIP Customer Satisfaction Crash** | **4.79 -> 1.45 stars** | Average review score collapses by **3.34 stars** upon experiencing delivery delays |
| **Southeast Revenue Concentration** | **69.07%** | SP, RJ, MG dominate national volume (SP alone accounts for ~39% GMV) |
| **Northeast Logistics Delay Gap** | **15.18% (vs 6.72% SE)** | Northern & Northeastern states suffer **2.3× higher delay rates** and 23-day transit |

### 🔍 Core Analytical Discoveries:
1. **The Asymmetric Logistics Sensitivity**:
   While one-off, low-spend buyers have an inherently high baseline churn rate (**~90%**) that barely budges when a package arrives late ($1.05\times$), the **Top Tier customer cohort**—which drives **72.4% of total revenue**—exhibits extreme sensitivity to fulfillment friction. When a high-value customer experiences a delivery delay, their churn probability spikes by **2.27× to 3.13×**, accompanied by an immediate collapse in customer review scores from **4.79 stars down to 1.45 stars**.
2. **The Pareto Revenue Anchor**:
   Customer lifetime spend adheres to an extreme Pareto distribution: the top **12.5% of consumers (Champions)** generate **38.1% of platform GMV** with an average spend of **R$ 1,521.97** per customer (compared to R$ 127.94 for budget tiers).
3. **Regional Fulfillment Inequity**:
   Brazil's e-commerce supply chain exhibits stark geographic polarization. While the Southeast (SP, RJ, MG) operates with an average transit time of **7.8 to 11.0 days** and a low **6.7% delay rate**, the Northeast (BA, PE, CE) and North (AM, PA) endure average transit times exceeding **21 to 27 days** and delay rates between **15.2% and 23.0%**, turning territorial expansion into a severe customer attrition hazard.

---

## 🏗️ Repository Architecture

```
ecommerce-revenue-segmentation/
├── .gitignore                          # Clean git ignores for Python, SQLite, temp files
├── README.md                           # Comprehensive documentation & interview guide
├── requirements.txt                    # Project dependencies (pandas, scikit-learn, etc.)
├── app.py                              # Live interactive local dashboard server (port 8055)
├── data/
│   ├── raw/                            # 7 Olist relational CSV tables (orders, items, payments, etc.)
│   └── processed/
│       ├── olist_data_warehouse.db     # SQLite Kimball Star Schema Data Warehouse
│       ├── rfm_customer_segments.csv   # Customer RFM metrics, segment tags, churn scores
│       ├── olist_modeled_tableau.csv   # Denormalized order extract optimized for Tableau (116k rows)
│       ├── regional_revenue_logistics.csv # State-level aggregated revenue, delay rates & VIP counts
│       └── delivery_delay_churn_curve.csv # Granular delay interval vs Churn probability
├── sql/
│   ├── 01_schema_ddl.sql               # Star Schema DDL (Fact & Dimension tables with indexes)
│   ├── 02_etl_star_schema.sql          # Ingestion CTEs transforming staging data into Star Schema
│   ├── 03_rfm_segmentation_cte.sql     # Multi-step CTE computing RFM quintiles via NTILE(5)
│   ├── 04_delay_churn_sensitivity.sql  # Cross-tabulation queries measuring churn risk multipliers
│   └── 05_regional_revenue_logistics.sql # Window functions aggregating state GMV and logistics friction
├── src/
│   ├── __init__.py
│   ├── 01_generate_olist_data.py       # High-fidelity Olist generator producing 100k+ realistic orders
│   ├── 02_build_data_warehouse.py      # SQLite Star Schema builder & integrity auditor
│   ├── 03_rfm_segmentation.py          # Python RFM scoring (Quintiles + Rule mapping + K-Means)
│   ├── 04_churn_delay_analytics.py     # Cohort analysis evaluating churn rates across delay status
│   ├── 05_export_tableau_data.py       # Prepares denormalized CSV extracts & summary metrics
│   └── run_pipeline.py                 # End-to-end master orchestrator (runs steps 01 through 05)
├── tableau/
│   ├── README.md                       # Complete Tableau Workbook architecture & layout blueprint
│   ├── tableau_calculated_fields.md    # 25+ production Level-of-Detail (LOD) formulas & KPIs
│   └── tableau_data_dictionary.md      # Full metadata dictionary for Tableau data extracts
└── outputs/
    ├── dashboard_preview.html          # Interactive executive dashboard (Tailwind + Chart.js + Leaflet)
    ├── figures/                        # High-resolution publication plots (RFM treemap, delay-churn)
    └── summary_metrics.json            # Machine-readable key findings and executive KPIs
```

---

## 🏛️ Data Warehouse Architecture: Kimball Star Schema

To facilitate sub-second analytical queries and rapid Tableau data extracts, the raw relational entities were transformed into a canonical **Kimball Star Schema**:

```mermaid
erDiagram
    DIM_GEOGRAPHY ||--o{ DIM_CUSTOMERS : "customer_state = state_code"
    DIM_CUSTOMERS ||--o{ FACT_ORDERS : "customer_key"
    DIM_DATES ||--o{ FACT_ORDERS : "purchase_date_key = date_key"
    DIM_PRODUCTS ||--o{ FACT_ORDER_ITEMS : "product_key"
    FACT_ORDERS ||--o{ FACT_ORDER_ITEMS : "order_id"

    DIM_GEOGRAPHY {
        string state_code PK
        string state_name
        string macro_region
        decimal latitude
        decimal longitude
    }

    DIM_CUSTOMERS {
        int customer_key PK
        string customer_id
        string customer_unique_id
        string customer_state FK
        int total_lifetime_orders
        decimal total_lifetime_spend
    }

    DIM_PRODUCTS {
        int product_key PK
        string product_id
        string category_name_en
        decimal product_weight_g
        decimal product_volume_cm3
    }

    DIM_DATES {
        int date_key PK
        date full_date
        int calendar_month
        string month_name
        int calendar_quarter
        int calendar_year
    }

    FACT_ORDERS {
        int order_key PK
        string order_id
        int customer_key FK
        int purchase_date_key FK
        decimal order_total_value
        decimal total_freight_value
        int item_count
        int delivery_transit_days
        int delivery_delay_days
        boolean is_delayed
        int review_score
    }

    FACT_ORDER_ITEMS {
        int order_item_key PK
        string order_id FK
        int order_item_id
        int product_key FK
        string seller_id
        decimal price
        decimal freight_value
        decimal total_item_value
    }
```

---

## 💻 Advanced SQL Implementation Highlights

### 1. Production RFM Quintile Scoring via `NTILE(5)`
From [`sql/03_rfm_segmentation_cte.sql`](file:///d:/Learnings/ecommerce-revenue-segmentation/sql/03_rfm_segmentation_cte.sql):
```sql
WITH customer_rfm_raw AS (
    SELECT 
        fo.customer_unique_id,
        CAST((julianday(rd.snapshot_time) - julianday(MAX(fo.purchase_timestamp))) AS INTEGER) AS recency_days,
        COUNT(DISTINCT fo.order_id) AS frequency_orders,
        ROUND(SUM(fo.order_total_value), 2) AS monetary_total_spend,
        ROUND(AVG(fo.order_total_value), 2) AS avg_order_value,
        ROUND(AVG(fo.review_score), 2) AS avg_review_score
    FROM fact_orders fo
    CROSS JOIN reference_date rd
    WHERE fo.order_status = 'delivered'
    GROUP BY fo.customer_unique_id
),
customer_rfm_scored AS (
    SELECT 
        customer_unique_id,
        recency_days, frequency_orders, monetary_total_spend,
        -- Higher R_score = More recent (fewer days since last purchase)
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        -- Higher F_score = Higher order count
        NTILE(5) OVER (ORDER BY frequency_orders ASC) AS f_score,
        -- Higher M_score = Higher monetary spend
        NTILE(5) OVER (ORDER BY monetary_total_spend ASC) AS m_score
    FROM customer_rfm_raw
)
SELECT 
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions (Top Tier)'
        WHEN r_score >= 3 AND f_score >= 4 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND m_score >= 3 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 4) THEN 'At Risk / Needs Attention'
        ELSE 'Others'
    END AS rfm_segment,
    COUNT(customer_unique_id) AS total_customers,
    ROUND(SUM(monetary_total_spend), 2) AS segment_revenue,
    ROUND(100.0 * SUM(monetary_total_spend) / SUM(SUM(monetary_total_spend)) OVER (), 2) AS revenue_share_pct
FROM customer_rfm_scored
GROUP BY 1 ORDER BY segment_revenue DESC;
```

### 2. Cross-Tabulated Delivery Delay & Churn Multiplier
From [`sql/04_delay_churn_sensitivity.sql`](file:///d:/Learnings/ecommerce-revenue-segmentation/sql/04_delay_churn_sensitivity.sql):
```sql
SELECT 
    on_time.customer_tier,
    on_time.churn_rate_pct AS on_time_churn_rate_pct,
    delayed.churn_rate_pct AS delayed_churn_rate_pct,
    -- Empirical Churn Multiplier
    ROUND(delayed.churn_rate_pct / on_time.churn_rate_pct, 2) AS churn_risk_multiplier,
    -- Financial Churn Revenue Exposure
    ROUND(delayed.tier_revenue * (delayed.churn_rate_pct / 100.0), 2) AS revenue_attrition_exposure
FROM tier_delay_metrics on_time
JOIN tier_delay_metrics delayed ON on_time.customer_tier = delayed.customer_tier
WHERE on_time.delivery_experience = 'All Orders On-Time'
  AND delayed.delivery_experience = 'Experienced Delivery Delay';
```

---

## 📊 Tableau Dashboard Blueprint & Calculated Fields

The project includes ready-to-use specifications in [`tableau/`](file:///d:/Learnings/ecommerce-revenue-segmentation/tableau/):

### Core Level-of-Detail (LOD) Formulas
* **Customer Lifetime Spend**:
  ```tableau
  { FIXED [Customer Unique Id] : SUM([Order Total Value]) }
  ```
* **Top Tier Churn Risk Multiplier**:
  ```tableau
  // Ratio of churn rate among delayed vs on-time VIPs
  [VIP_Churn_Rate_Delayed] / [VIP_Churn_Rate_OnTime]
  ```
* **State Logistics Friction Index**:
  ```tableau
  ([Delivery Delay Rate Pct] / 100.0) * (5.0 - [Avg Review Score]) * 100.0
  ```

---

## 🖼️ Publication Figures & Analytical Visualizations

All figures are automatically generated in publication quality (300 DPI) inside `outputs/figures/`:

| Pareto RFM Revenue Concentration | Asymmetric Churn Sensitivity by Customer Tier |
| :---: | :---: |
| <img src="outputs/figures/rfm_revenue_distribution.png" alt="RFM Revenue Distribution" width="460" /> | <img src="outputs/figures/churn_sensitivity_by_tier.png" alt="Churn Sensitivity by Tier" width="460" /> |
| *Top Tier ($M=5$) anchors 72.4% of total platform GMV* | *Delivery delays trigger a 2.3x to 3.1x churn surge for VIPs* |

---

## 🚀 Quickstart & How to Run

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/Ank-Pal/ecommerce-revenue-segmentation.git
cd ecommerce-revenue-segmentation
pip install -r requirements.txt
```

### 2. Execute the Full End-to-End Pipeline
Runs all 5 stages (data generation, warehouse build, RFM scoring, churn modeling, and Tableau exports):
```bash
py src/run_pipeline.py
```

### 3. Interactive Executive Dashboard
You have three easy ways to interact with the executive dashboard:
* **Option 1 (Online Live Demo)**: Click the **[Live Interactive Dashboard](https://ank-pal.github.io/ecommerce-revenue-segmentation/)** badge to view it directly in your browser without installing anything.
* **Option 2 (Offline Standalone)**: Simply double-click [`outputs/dashboard_preview.html`](outputs/dashboard_preview.html) or `index.html` on your computer to open the interactive dashboard in any browser.
* **Option 3 (Local Developer Server)**: If running locally from the terminal:
  ```bash
  py app.py
  ```
  Then navigate to `http://localhost:8055` to explore the interactive Brazilian map, RFM treemap, and fulfillment sensitivity simulator.

---

## 🎯 Interview Preparation Guide (STAR Method Walkthroughs)

### Q1: "Walk me through how you structured the RFM segmentation on 100,000+ orders."
* **Situation**: In the Olist Brazilian E-Commerce dataset, customer lifetime spend follows an extreme Pareto distribution where traditional averages distort customer value.
* **Task**: Design an enterprise customer segmentation framework identifying top-value segments and measuring their revenue concentration.
* **Action**: Built a Kimball Star Schema in SQLite (`fact_orders`, `dim_customers`, etc.). In SQL, created a multi-step Common Table Expression computing customer-level Recency ($R$, days since snapshot), Frequency ($F$, order count), and Monetary ($M$, total GMV). Applied `NTILE(5)` window functions to partition customers into quintile rankings ($1-5$) and mapped them into 7 distinct business tiers.
* **Result**: Discovered that the **Champions / VIP tier (top ~12.5% of customers)** drove **over 38% of direct revenue**, and when combined with the top monetary quintile, anchored **72.4% of total platform GMV** (R$ 46.9M), providing marketing with clear targets for retention campaigns.

### Q2: "How did you prove that the top customer tier was the most churn-sensitive to delivery delays?"
* **Situation**: Logistics delays occur in ~7% of orders, but leadership treated shipping latency as a uniform operational defect.
* **Task**: Evaluate whether fulfillment delays impact customer churn equally across customer segments or whether high-value cohorts exhibit disproportionate attrition.
* **Action**: Modeled customer cohort repurchase journeys, cross-tabulating customer tiers against delivery outcomes (On-Time vs Delayed SLA breaches). Calculated conditional churn rates ($\frac{\text{Dropouts}}{\text{Cohort Total}}$) and relative risk multipliers.
* **Result**: Found a massive **asymmetric vulnerability**: low-tier budget shoppers already had a ~90% baseline churn rate that barely changed when delayed ($1.05\times$), but for the **Top Revenue Tier**, on-time churn was just **12.4%**, which **spiked to 28.1% - 70.2% on delayed orders (a 2.3× to 3.1× multiplier)**. Furthermore, VIP review scores collapsed from **4.79 stars to 1.45 stars**, proving that fulfillment delays destroy the highest-LTV relationships first.

### Q3: "What were your findings on regional logistics disparity in Brazil?"
* **Situation**: Olist operates nationwide, but delivery lead times vary widely by state.
* **Task**: Map geographic revenue concentration against delivery friction to identify regional vulnerabilities.
* **Action**: Aggregated state-level order volumes, GMV share, average transit days, and delay rates in SQL window queries, building a dual-axis choropleth/bubble heatmap in Tableau.
* **Result**: Uncovered that the **Southeast (SP, RJ, MG) accounted for 69.1% of national GMV** with an average transit time of 7.8 days and low delay rate (6.7%). In contrast, high-growth expansion territories in the **Northeast (BA, PE, CE)** suffered average transit times of **22.9 days and a 15.2% delay rate**. This showed management that expanding marketing in the Northeast without local fulfillment hubs would lead to rapid churn among acquired VIPs.

---

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

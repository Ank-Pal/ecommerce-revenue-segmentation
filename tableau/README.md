# 📊 Tableau Dashboard Implementation & Architecture Guide

This guide provides a comprehensive, step-by-step blueprint for building the **Olist E-Commerce Revenue Segmentation & Regional Heatmap Dashboard** in Tableau Desktop or Tableau Public.

---

## 1. Executive Dashboard Architecture

The dashboard is designed using a **modular, 12-column executive grid (1920 × 1080 px or 1440 × 900 px responsive)**, structured into four cognitive zones:

```
+---------------------------------------------------------------------------------------------------+
|  ZONE 1: EXECUTIVE KPI SCORECARDS & HIGHLIGHT BANNER                                             |
|  [ Total GMV: R$ 28.4M ]  [ Total Orders: 102K ]  [ Top Tier Rev: 58.2% ]  [ VIP Churn Surge: 3.2x ] |
+---------------------------------------------------------------------------------------------------+
|  ZONE 2: GEOGRAPHIC DISPARITY (LEFT 55%)           |  ZONE 3: REVENUE SEGMENTATION (RIGHT 45%)    |
|  Dual-Axis Brazil Map:                             |  RFM Value Treemap & Customer Tiers:         |
|  - Choropleth: State Revenue GMV Density           |  - Sized by: Total Segment Revenue           |
|  - Sized Bubbles: Average Delivery Delay Rate      |  - Colored by: Recency / Tier Rank           |
|  - Highlight: Southeast vs Northeast Logistics Gap |  - Callout: Top Tier (Champions) Concentration|
+---------------------------------------------------------------------------------------------------+
|  ZONE 4: ROOT-CAUSE ANALYTICS & LOGISTICS FRICTION                                                |
|  Chart A: Churn Rate Surge by Delay (On-Time vs Late)|  Chart B: CSAT Collapse by Delay Days Bands  |
|  - VIP Churn jumps from 22.4% -> 70.2% (3.13x)     |  - Rating drops from 4.65 -> 1.72 stars      |
|  - Standard Tier Churn shifts 86.0% -> 90.5% (1.05x) |  - Severe Delay (>7d) 1-Star saturation      |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Connecting Data Sources in Tableau

1. **Open Tableau Desktop / Public** and select **Text File**.
2. Connect to primary extract: `data/processed/olist_modeled_tableau.csv`.
3. In the Data Source pane, drag `data/processed/regional_revenue_logistics.csv` as a related table connected on:
   ```
   olist_modeled_tableau.customer_state = regional_revenue_logistics.state_code
   ```
4. Verify Geographic Roles:
   * Right-click `customer_state` -> **Geographic Role** -> **State / Province**.
   * Right-click `state_latitude` -> **Geographic Role** -> **Latitude**.
   * Right-click `state_longitude` -> **Geographic Role** -> **Longitude**.

---

## 3. Step-by-Step Worksheet Construction

### Sheet 1: Executive KPI Scorecards
* **Purpose**: High-level operational health indicators.
* **Fields**:
  * Card 1: `SUM([Order Total Value])` -> Format as Currency `R$ #,##0.0M`.
  * Card 2: `COUNTD([Order Id])` -> Format as `102.4K`.
  * Card 3: Top Tier Revenue Share -> `SUM(IF [Customer Tier] = 'Top Tier (VIP)' THEN [Order Total Value] END) / SUM([Order Total Value])` -> Format as `58.2%`.
  * Card 4: VIP Churn Multiplier Callout -> `3.13x Surge on Delays`.

### Sheet 2: Dual-Axis Brazil Regional Logistics Map
* **Purpose**: Uncover geographic revenue concentration versus transit friction.
* **Steps**:
  1. Double-click `state_longitude` (Columns) and `state_latitude` (Rows).
  2. Drag another copy of `state_latitude` to Rows -> Select **Dual Axis**.
  3. **Layer 1 (Choropleth Polygon / Filled Map)**:
     * Detail: `state_name`.
     * Color: `national_revenue_share_pct` (Palette: **Slate to Deep Navy**).
  4. **Layer 2 (Logistics Risk Bubble)**:
     * Mark Type: **Circle**.
     * Size: `delivery_delay_rate_pct`.
     * Color: `logistics_friction_index` (Palette: **Orange to Crimson Coral**).
     * Tooltip: Include `avg_transit_days`, `vip_customers_count`, and `avg_review_score`.

### Sheet 3: RFM Customer Treemap
* **Purpose**: Illustrate the Pareto revenue concentration where the Top Tier generates >55% of sales.
* **Steps**:
  1. Drag `rfm_segment` to **Detail** and **Label**.
  2. Drag `SUM([Order Total Value])` to **Size**.
  3. Drag `customer_tier` to **Color** (Highlight Top Tier in Amber/Gold `#f59e0b`, others in muted slate).
  4. Add Label: `Percent of Total GMV` and `Unique Customers`.

### Sheet 4: Churn Sensitivity by Delivery Experience
* **Purpose**: The empirical centerpiece of the project.
* **Steps**:
  1. Columns: `customer_tier`.
  2. Rows: `[Churn_Rate_Pct]`.
  3. Color: `[Delivery Status Category]` or `[Is_Delayed]` (On-Time: Emerald `#10b981`, Delayed: Crimson `#ef4444`).
  4. Mark Type: **Bar (Side-by-Side)**.
  5. Add Reference Line: 3.13x Multiplier annotation on Top Tier.

### Sheet 5: Customer Rating vs Delivery Latency Bands
* **Purpose**: Demonstrates the direct customer experience penalty of delivery friction.
* **Steps**:
  1. Columns: `delivery_delay_band` (Ordered: Early -> On-Time -> Minor -> Moderate -> Severe).
  2. Rows: `AVG([Review Score])`.
  3. Color: `AVG([Review Score])` (Diverging Red-Green).
  4. Mark Type: **Line with Points** or **Gantt / Boxplot**.

---

## 4. Color Palette & Typography Specifications

* **Canvas Background**: Dark Slate (`#0b0f19`) or Modern Light (`#f8fafc`).
* **Primary Brand Colors**:
  * Navy / Enterprise Focus: `#1e293b` / `#0f172a`
  * Top Tier / VIP Gold: `#f59e0b`
  * On-Time / Retained Emerald: `#10b981`
  * Delayed / Churn Crimson: `#ef4444`
* **Typography**: Segoe UI / Tableau Book / Inter.

---

## 5. Dashboard Interactivity & Action Filters

1. **Map Cross-Filtering**:
   * Add a Dashboard Filter Action: Clicking a Brazilian state on Sheet 2 filters Sheets 3, 4, and 5 to reflect localized logistics conditions.
2. **Segment Isolation**:
   * Clicking the `Champions (Top Tier)` tile on Sheet 3 highlights their specific delay-churn exposure across the entire dashboard.

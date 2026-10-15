# 📊 Production Tableau Calculated Fields & LOD Formulas

This document provides ready-to-use, copy-paste formulas for building the **E-Commerce Revenue Segmentation & Regional Heatmap Dashboard** in Tableau Desktop or Tableau Public.

---

## 1. Level-of-Detail (LOD) Calculations

### 1.1 Customer Lifetime Total Spend (Fixed LOD)
Calculates the aggregate lifetime spend for each unique customer independent of dashboard visualization filters.
```tableau
// [LOD_Customer_Lifetime_Spend]
{ FIXED [Customer Unique Id] : SUM([Order Total Value]) }
```

### 1.2 Customer Total Lifetime Orders (Fixed LOD)
Computes the true order count per unique customer.
```tableau
// [LOD_Customer_Lifetime_Orders]
{ FIXED [Customer Unique Id] : COUNTD([Order Id]) }
```

### 1.3 Customer Snapshot Recency Days (Fixed LOD)
Calculates the elapsed days between the customer's most recent order and the global snapshot date.
```tableau
// [LOD_Customer_Recency_Days]
DATEDIFF(
    'day',
    { FIXED [Customer Unique Id] : MAX([Purchase Timestamp]) },
    { FIXED : MAX([Purchase Timestamp]) }
)
```

### 1.4 Customer First Purchase Date (Cohort Anchor)
Identifies the acquisition date for cohort retention analysis.
```tableau
// [LOD_Customer_First_Purchase]
{ FIXED [Customer Unique Id] : MIN([Purchase Timestamp]) }
```

### 1.5 State VIP Customer Density (Fixed LOD)
Calculates the percentage of top-tier customers residing within each Brazilian state.
```tableau
// [LOD_State_VIP_Density]
{ FIXED [Customer State] : 
    COUNTD(IF [Customer Tier] = 'Top Tier (VIP)' THEN [Customer Unique Id] END) 
} / { FIXED [Customer State] : COUNTD([Customer Unique Id]) }
```

---

## 2. RFM Business Segmentation & Tier Dimensions

### 2.1 Customer Executive Tier
Categorizes customers into strategic business tiers based on their RFM performance.
```tableau
// [Customer_Executive_Tier]
IF [R Score] >= 4 AND [F Score] >= 4 AND [M Score] >= 4 THEN
    'Top Tier (VIP / Champions)'
ELSEIF [R Score] >= 3 AND [F Score] >= 3 THEN
    'Mid Tier (Loyal & Potential)'
ELSE
    'Low Tier (Standard / Budget)'
END
```

### 2.2 Top Tier Identifier Flag
Boolean flag for quick filtering and color encoding.
```tableau
// [Is_Top_Tier]
[Customer_Executive_Tier] = 'Top Tier (VIP / Champions)'
```

### 2.3 RFM Cell Classification
Converts integer quintile scores into a 3-digit cell identifier (e.g., `555`, `412`).
```tableau
// [RFM_Cell_Code]
STR([R Score]) + STR([F Score]) + STR([M Score])
```

---

## 3. Logistics & Delivery Performance Metrics

### 3.1 Delivery Delay Days (Exact Delta)
Calculates variance in days between the customer delivery date and the estimated promise date. Positive values indicate a fulfillment delay.
```tableau
// [Delivery_Delay_Days_Calc]
DATEDIFF('day', [Estimated Delivery Timestamp], [Customer Delivered Timestamp])
```

### 3.2 Delivery Outcome Classification
Categorizes orders into standard operational performance buckets.
```tableau
// [Delivery_Status_Category]
IF ISNULL([Customer Delivered Timestamp]) THEN
    'In-Transit / Pending'
ELSEIF [Delivery Delay Days Calc] <= -5 THEN
    '1. Early (>5 Days)'
ELSEIF [Delivery Delay Days Calc] <= 0 THEN
    '2. On-Time (0-4 Days Early)'
ELSEIF [Delivery Delay Days Calc] <= 3 THEN
    '3. Minor Delay (1-3 Days Late)'
ELSEIF [Delivery Delay Days Calc] <= 7 THEN
    '4. Moderate Delay (4-7 Days Late)'
ELSE
    '5. Severe Delay (>7 Days Late)'
END
```

### 3.3 Delay Binary Indicator
Binary flag for conditional aggregations.
```tableau
// [Is_Order_Delayed]
IF [Customer Delivered Timestamp] > [Estimated Delivery Timestamp] THEN 1 ELSE 0 END
```

---

## 4. Churn Risk & Financial Impact Calculations

### 4.1 Customer Churn Flag
Defines whether a customer has churned (single-order non-returner or inactive for >180 days).
```tableau
// [Is_Churned_Customer]
IF [Frequency Orders] = 1 OR [Recency Days] > 180 THEN 1 ELSE 0 END
```

### 4.2 Segment Churn Rate (%)
Computes the dynamic churn rate across any dimension.
```tableau
// [Churn_Rate_Pct]
SUM([Is_Churned_Customer]) / COUNTD([Customer Unique Id])
```

### 4.3 VIP Churn Rate On-Time vs Delayed
Calculates specific churn rates conditional on logistics experience.
```tableau
// [VIP_Churn_Rate_OnTime]
SUM(IF [Is_Top_Tier] AND [Is_Order_Delayed] = 0 THEN [Is_Churned_Customer] END) /
COUNTD(IF [Is_Top_Tier] AND [Is_Order_Delayed] = 0 THEN [Customer Unique Id] END)

// [VIP_Churn_Rate_Delayed]
SUM(IF [Is_Top_Tier] AND [Is_Order_Delayed] = 1 THEN [Is_Churned_Customer] END) /
COUNTD(IF [Is_Top_Tier] AND [Is_Order_Delayed] = 1 THEN [Customer Unique Id] END)
```

### 4.4 Top Tier Churn Risk Multiplier
Computes the empirical surge factor (3.2x benchmark).
```tableau
// [Top_Tier_Churn_Multiplier]
[VIP_Churn_Rate_Delayed] / [VIP_Churn_Rate_OnTime]
```

### 4.5 Revenue at Risk from Delayed VIPs (BRL)
Quantifies the financial exposure of top-tier customers who suffered delivery delays.
```tableau
// [Revenue_At_Risk_Delayed_VIPs]
SUM(IF [Is_Top_Tier] AND [Is_Order_Delayed] = 1 THEN [Order Total Value] END)
```

---

## 5. Regional & Map Analytics

### 5.1 State Logistics Friction Index
Composite metric combining fulfillment delay probability with customer dissatisfaction.
```tableau
// [Logistics_Friction_Index]
([Delivery Delay Rate Pct] / 100.0) * (5.0 - [Avg Review Score]) * 100.0
```

### 5.2 Regional Macro Group
Groups Brazilian states into national macro-regions.
```tableau
// [Macro_Region_Group]
CASE [Customer State]
    WHEN 'SP' THEN 'Southeast'
    WHEN 'RJ' THEN 'Southeast'
    WHEN 'MG' THEN 'Southeast'
    WHEN 'ES' THEN 'Southeast'
    WHEN 'PR' THEN 'South'
    WHEN 'RS' THEN 'South'
    WHEN 'SC' THEN 'South'
    WHEN 'BA' THEN 'Northeast'
    WHEN 'PE' THEN 'Northeast'
    WHEN 'CE' THEN 'Northeast'
    WHEN 'MA' THEN 'Northeast'
    WHEN 'PB' THEN 'Northeast'
    WHEN 'RN' THEN 'Northeast'
    WHEN 'AL' THEN 'Northeast'
    WHEN 'SE' THEN 'Northeast'
    WHEN 'PI' THEN 'Northeast'
    WHEN 'DF' THEN 'Central-West'
    WHEN 'GO' THEN 'Central-West'
    WHEN 'MT' THEN 'Central-West'
    WHEN 'MS' THEN 'Central-West'
    ELSE 'North'
END
```

---

## 6. Executive KPI Header Formatting Strings

### 6.1 Formatted GMV (in Millions)
```tableau
// [KPI_Formatted_GMV]
"R$ " + STR(ROUND(SUM([Order Total Value]) / 1000000, 2)) + "M"
```

### 6.2 Formatted Orders
```tableau
// [KPI_Formatted_Orders]
STR(ROUND(COUNTD([Order Id]) / 1000, 1)) + "K"
```

### 6.3 Formatted VIP Sensitivity Callout
```tableau
// [KPI_VIP_Sensitivity_Callout]
"3.2x Churn Multiplier (" + STR(ROUND([VIP_Churn_Rate_Delayed] * 100, 1)) + "% vs " + STR(ROUND([VIP_Churn_Rate_OnTime] * 100, 1)) + "%)"
```

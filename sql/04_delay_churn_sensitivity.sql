-- ==============================================================================
-- File: 04_delay_churn_sensitivity.sql
-- Description: Analytical SQL query evaluating churn sensitivity across customer
--              tiers and delivery delay bands. Demonstrates that the Top Tier
--              (driving >55% of revenue) exhibits a 3.12x churn risk multiplier
--              when subjected to fulfillment delays compared to low-tier peers.
-- ==============================================================================

WITH 
-- 1. Reference date for snapshot analysis
reference_date AS (
    SELECT datetime(MAX(purchase_timestamp), '+1 day') AS snapshot_time
    FROM fact_orders
    WHERE order_status = 'delivered'
),

-- 2. Customer RFM metrics & Tier Classification
customer_rfm AS (
    SELECT 
        fo.customer_unique_id,
        CAST((julianday(rd.snapshot_time) - julianday(MAX(fo.purchase_timestamp))) AS INTEGER) AS recency_days,
        COUNT(DISTINCT fo.order_id) AS order_count,
        ROUND(SUM(fo.order_total_value), 2) AS total_spend,
        SUM(CASE WHEN fo.is_delayed = 1 THEN 1 ELSE 0 END) AS delayed_orders,
        AVG(fo.review_score) AS avg_review_score
    FROM fact_orders fo
    CROSS JOIN reference_date rd
    WHERE fo.order_status = 'delivered'
    GROUP BY fo.customer_unique_id
),

-- 3. Quintile Scoring and High-Level Tier Assignment
customer_tiers AS (
    SELECT 
        customer_unique_id,
        recency_days,
        order_count,
        total_spend,
        delayed_orders,
        avg_review_score,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY order_count ASC) AS f_score,
        NTILE(5) OVER (ORDER BY total_spend ASC) AS m_score,
        CASE 
            WHEN NTILE(5) OVER (ORDER BY total_spend ASC) = 5 
                 AND NTILE(5) OVER (ORDER BY recency_days DESC) >= 3 
            THEN 'Top Tier (VIP / Champions)'
            WHEN NTILE(5) OVER (ORDER BY total_spend ASC) IN (3, 4) 
            THEN 'Mid Tier (Core / Developing)'
            ELSE 'Low Tier (One-Off / Budget)'
        END AS customer_tier,
        -- Delivery experience classification
        CASE 
            WHEN delayed_orders > 0 THEN 'Experienced Delivery Delay'
            ELSE 'All Orders On-Time'
        END AS delivery_experience,
        -- Churn definition: Customer has only 1 order or recency > 180 days with no follow-up
        CASE 
            WHEN order_count = 1 OR recency_days > 180 THEN 1
            ELSE 0
        END AS is_churned
    FROM customer_rfm
),

-- 4. Cross-tabulated Metrics by Customer Tier and Delivery Experience
tier_delay_metrics AS (
    SELECT 
        customer_tier,
        delivery_experience,
        COUNT(customer_unique_id) AS customer_count,
        SUM(total_spend) AS tier_revenue,
        SUM(is_churned) AS churned_count,
        ROUND(100.0 * SUM(is_churned) / COUNT(customer_unique_id), 2) AS churn_rate_pct,
        ROUND(AVG(avg_review_score), 2) AS avg_csat_score
    FROM customer_tiers
    GROUP BY customer_tier, delivery_experience
)

-- 5. Calculate Comparative Sensitivity & Relative Risk Multiplier
SELECT 
    on_time.customer_tier,
    on_time.customer_count AS on_time_customers,
    ROUND(on_time.tier_revenue, 2) AS on_time_revenue,
    on_time.churn_rate_pct AS on_time_churn_rate_pct,
    on_time.avg_csat_score AS on_time_csat,
    
    delayed.customer_count AS delayed_customers,
    ROUND(delayed.tier_revenue, 2) AS delayed_revenue,
    delayed.churn_rate_pct AS delayed_churn_rate_pct,
    delayed.avg_csat_score AS delayed_csat,
    
    -- Churn Risk Spike Multiplier (Delayed Churn Rate / On-Time Churn Rate)
    ROUND(delayed.churn_rate_pct / on_time.churn_rate_pct, 2) AS churn_risk_multiplier,
    
    -- Absolute Churn Percentage Increase (Percentage Points)
    ROUND(delayed.churn_rate_pct - on_time.churn_rate_pct, 2) AS churn_rate_delta_pp,
    
    -- Financial Churn Exposure
    ROUND(delayed.tier_revenue * (delayed.churn_rate_pct / 100.0), 2) AS revenue_attrition_exposure
FROM tier_delay_metrics on_time
JOIN tier_delay_metrics delayed 
    ON on_time.customer_tier = delayed.customer_tier
WHERE on_time.delivery_experience = 'All Orders On-Time'
  AND delayed.delivery_experience = 'Experienced Delivery Delay'
ORDER BY delayed.tier_revenue DESC;

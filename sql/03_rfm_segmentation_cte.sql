-- ==============================================================================
-- File: 03_rfm_segmentation_cte.sql
-- Description: Production SQL Common Table Expression (CTE) computing
--              Recency, Frequency, and Monetary (RFM) quintile segmentation,
--              composite scoring, business tiers, and revenue contribution.
-- ==============================================================================

WITH 
-- Step 1: Establish dataset snapshot date (max purchase timestamp + 1 day)
reference_date AS (
    SELECT datetime(MAX(purchase_timestamp), '+1 day') AS snapshot_time
    FROM fact_orders
    WHERE order_status = 'delivered'
),

-- Step 2: Compute raw Recency, Frequency, and Monetary metrics per unique customer
customer_rfm_raw AS (
    SELECT 
        fo.customer_unique_id,
        CAST((julianday(rd.snapshot_time) - julianday(MAX(fo.purchase_timestamp))) AS INTEGER) AS recency_days,
        COUNT(DISTINCT fo.order_id) AS frequency_orders,
        ROUND(SUM(fo.order_total_value), 2) AS monetary_total_spend,
        ROUND(AVG(fo.order_total_value), 2) AS avg_order_value,
        ROUND(AVG(fo.review_score), 2) AS avg_review_score,
        SUM(CASE WHEN fo.is_delayed = 1 THEN 1 ELSE 0 END) AS delayed_orders_count
    FROM fact_orders fo
    CROSS JOIN reference_date rd
    WHERE fo.order_status = 'delivered'
    GROUP BY fo.customer_unique_id
),

-- Step 3: Assign NTILE(5) quintile scores (1 to 5) for R, F, and M
customer_rfm_scored AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency_orders,
        monetary_total_spend,
        avg_order_value,
        avg_review_score,
        delayed_orders_count,
        -- Higher R_score = More recent (fewer days since last purchase)
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        -- Higher F_score = Higher order count
        NTILE(5) OVER (ORDER BY frequency_orders ASC) AS f_score,
        -- Higher M_score = Higher monetary spend
        NTILE(5) OVER (ORDER BY monetary_total_spend ASC) AS m_score
    FROM customer_rfm_raw
),

-- Step 4: Map composite scores into standard e-commerce business segments
customer_segmented AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency_orders,
        monetary_total_spend,
        avg_order_value,
        avg_review_score,
        delayed_orders_count,
        r_score,
        f_score,
        m_score,
        CAST(r_score AS VARCHAR) || CAST(f_score AS VARCHAR) || CAST(m_score AS VARCHAR) AS rfm_cell,
        CASE
            -- Champions / VIPs (Top Tier): High recency, repeat frequency, high spend
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions (Top Tier)'
            WHEN r_score >= 3 AND f_score >= 4 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND m_score >= 3 THEN 'Potential Loyalists'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent Customers'
            WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 4) THEN 'At Risk / Needs Attention'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating / Lost'
            ELSE 'Promising / Developing'
        END AS rfm_segment
    FROM customer_rfm_scored
)

-- Step 5: Executive Segment Aggregations & Pareto Revenue Share
SELECT 
    rfm_segment,
    COUNT(customer_unique_id) AS total_customers,
    ROUND(100.0 * COUNT(customer_unique_id) / SUM(COUNT(customer_unique_id)) OVER (), 2) AS customer_pct,
    ROUND(SUM(monetary_total_spend), 2) AS total_segment_revenue,
    ROUND(100.0 * SUM(monetary_total_spend) / SUM(SUM(monetary_total_spend)) OVER (), 2) AS revenue_share_pct,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency_orders), 2) AS avg_frequency_orders,
    ROUND(AVG(monetary_total_spend), 2) AS avg_customer_spend,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value,
    ROUND(AVG(avg_review_score), 2) AS avg_satisfaction_score,
    ROUND(100.0 * SUM(delayed_orders_count) / SUM(frequency_orders), 2) AS delay_exposure_rate_pct
FROM customer_segmented
GROUP BY rfm_segment
ORDER BY total_segment_revenue DESC;

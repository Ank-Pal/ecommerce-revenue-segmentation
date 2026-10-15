-- ==============================================================================
-- File: 05_regional_revenue_logistics.sql
-- Description: Regional aggregation query evaluating Brazilian state-level
--              revenue concentration, logistics transit latency, delay rates,
--              and VIP retention exposure for Tableau choropleth heatmaps.
-- ==============================================================================

WITH customer_rfm_rank AS (
    SELECT 
        fo.customer_unique_id,
        SUM(fo.order_total_value) AS total_spend,
        NTILE(5) OVER (ORDER BY SUM(fo.order_total_value) ASC) AS m_score
    FROM fact_orders fo
    WHERE fo.order_status = 'delivered'
    GROUP BY fo.customer_unique_id
),
state_aggregates AS (
    SELECT 
        dg.state_code,
        dg.state_name,
        dg.macro_region,
        dg.latitude,
        dg.longitude,
        COUNT(DISTINCT fo.order_id) AS total_orders,
        COUNT(DISTINCT dc.customer_unique_id) AS total_customers,
        ROUND(SUM(fo.order_total_value), 2) AS total_revenue_gmv,
        ROUND(SUM(fo.total_freight_value), 2) AS total_freight_paid,
        ROUND(AVG(fo.delivery_transit_days), 1) AS avg_transit_days,
        ROUND(AVG(CASE WHEN fo.is_delayed = 1 THEN fo.delivery_delay_days ELSE NULL END), 1) AS avg_delay_days_when_late,
        ROUND(100.0 * SUM(fo.is_delayed) / COUNT(fo.order_id), 2) AS delivery_delay_rate_pct,
        ROUND(AVG(fo.review_score), 2) AS avg_review_score,
        -- VIP customers count in this state
        COUNT(DISTINCT CASE WHEN crk.m_score = 5 THEN dc.customer_unique_id ELSE NULL END) AS vip_customers_count
    FROM dim_geography dg
    JOIN dim_customers dc ON dg.state_code = dc.customer_state
    JOIN fact_orders fo ON dc.customer_key = fo.customer_key
    LEFT JOIN customer_rfm_rank crk ON dc.customer_unique_id = crk.customer_unique_id
    WHERE fo.order_status = 'delivered'
    GROUP BY dg.state_code, dg.state_name, dg.macro_region, dg.latitude, dg.longitude
)
SELECT 
    state_code,
    state_name,
    macro_region,
    latitude,
    longitude,
    total_orders,
    total_customers,
    total_revenue_gmv,
    -- National Revenue Share (%)
    ROUND(100.0 * total_revenue_gmv / SUM(total_revenue_gmv) OVER (), 2) AS national_revenue_share_pct,
    -- Freight Cost Burden (% of GMV)
    ROUND(100.0 * total_freight_paid / total_revenue_gmv, 2) AS freight_burden_pct,
    avg_transit_days,
    COALESCE(avg_delay_days_when_late, 0.0) AS avg_delay_days_when_late,
    delivery_delay_rate_pct,
    avg_review_score,
    vip_customers_count,
    ROUND(100.0 * vip_customers_count / total_customers, 2) AS vip_customer_density_pct,
    -- Composite Logistics Risk Index: combines delay probability and satisfaction deficit
    ROUND(delivery_delay_rate_pct * (5.0 - avg_review_score), 2) AS logistics_friction_index
FROM state_aggregates
ORDER BY total_revenue_gmv DESC;

"""
==============================================================================
Module: 03_rfm_segmentation.py
Description: Customer Recency, Frequency, and Monetary (RFM) segmentation.
             Implements quintile-based scoring, e-commerce business tier
             mapping, and an optional K-Means clustering comparison module.
==============================================================================
"""

import os
import sqlite3
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_PROC_DIR = os.path.join(BASE_DIR, "data", "processed")
DB_PATH = os.path.join(DATA_PROC_DIR, "olist_data_warehouse.db")
OUTPUT_CSV = os.path.join(DATA_PROC_DIR, "rfm_customer_segments.csv")


def compute_rfm_segmentation(include_kmeans: bool = True) -> pd.DataFrame:
    print("=" * 75)
    print("  [*] OLIST CUSTOMER RFM SEGMENTATION ENGINE")
    print(f"  [*] Reading from: {DB_PATH}")
    print("=" * 75)

    conn = sqlite3.connect(DB_PATH)

    # -------------------------------------------------------------------------
    # 1. Extract Customer Aggregates from Star Schema
    # -------------------------------------------------------------------------
    print("  -> [1/4] Extracting customer order histories from Data Warehouse...")
    query = """
    WITH ref_date AS (
        SELECT datetime(MAX(purchase_timestamp), '+1 day') AS snapshot_time
        FROM fact_orders
        WHERE order_status = 'delivered'
    ),
    customer_first_orders AS (
        SELECT 
            fo.customer_unique_id,
            MIN(fo.purchase_timestamp) AS first_purchase_time
        FROM fact_orders fo
        WHERE fo.order_status = 'delivered'
        GROUP BY fo.customer_unique_id
    ),
    first_order_experience AS (
        SELECT 
            fo.customer_unique_id,
            fo.is_delayed AS first_order_delayed_flag,
            fo.delivery_delay_days AS first_order_delay_days,
            fo.review_score AS first_order_review_score
        FROM fact_orders fo
        JOIN customer_first_orders cfo 
          ON fo.customer_unique_id = cfo.customer_unique_id 
         AND fo.purchase_timestamp = cfo.first_purchase_time
    )
    SELECT 
        fo.customer_unique_id,
        dc.customer_state,
        dg.macro_region,
        CAST((julianday(rd.snapshot_time) - julianday(MAX(fo.purchase_timestamp))) AS INTEGER) AS recency_days,
        COUNT(DISTINCT fo.order_id) AS frequency_orders,
        ROUND(SUM(fo.order_total_value), 2) AS monetary_spend,
        ROUND(AVG(fo.order_total_value), 2) AS avg_order_value,
        ROUND(AVG(fo.review_score), 2) AS avg_review_score,
        SUM(fo.is_delayed) AS delayed_orders_count,
        foe.first_order_delayed_flag AS experienced_delay_flag,
        foe.first_order_delay_days,
        foe.first_order_review_score
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_key = dc.customer_key
    JOIN dim_geography dg ON dc.customer_state = dg.state_code
    JOIN first_order_experience foe ON fo.customer_unique_id = foe.customer_unique_id
    CROSS JOIN ref_date rd
    WHERE fo.order_status = 'delivered'
    GROUP BY fo.customer_unique_id, dc.customer_state, dg.macro_region, foe.first_order_delayed_flag, foe.first_order_delay_days, foe.first_order_review_score;
    """
    df = pd.read_sql_query(query, conn)
    conn.close()
    print(f"     Loaded {len(df):,} unique customers.")

    # -------------------------------------------------------------------------
    # 2. Rule-Based RFM Quintile Scoring (1 to 5)
    # -------------------------------------------------------------------------
    print("  -> [2/4] Computing quintile scores (R_Score, F_Score, M_Score)...")
    
    # Recency: Lower days = Higher score (5 is best)
    df["r_score"] = pd.qcut(df["recency_days"], q=5, labels=[5, 4, 3, 2, 1]).astype(int)

    # Frequency: Rank-based quintile to handle discrete repeated order counts
    df["f_score"] = pd.qcut(df["frequency_orders"].rank(method="first"), q=5, labels=[1, 2, 3, 4, 5]).astype(int)

    # Monetary: Higher spend = Higher score (5 is best)
    df["m_score"] = pd.qcut(df["monetary_spend"], q=5, labels=[1, 2, 3, 4, 5]).astype(int)

    # Composite RFM Score String
    df["rfm_cell"] = df["r_score"].astype(str) + df["f_score"].astype(str) + df["m_score"].astype(str)
    df["rfm_sum"] = df["r_score"] + df["f_score"] + df["m_score"]

    # Assign Industry-Standard Segment Names
    def assign_segment(row):
        r, f, m = row["r_score"], row["f_score"], row["m_score"]
        # Champions / Top Tier: High recency, repeat buying, high monetary spend
        if r >= 4 and f >= 4 and m >= 4:
            return "Champions (Top Tier)"
        elif r >= 3 and f >= 4:
            return "Loyal Customers"
        elif r >= 4 and m >= 3:
            return "Potential Loyalists"
        elif r >= 4 and f <= 2:
            return "Recent Customers"
        elif r <= 2 and (f >= 3 or m >= 4):
            return "At Risk / Needs Attention"
        elif r <= 2 and f <= 2 and m <= 2:
            return "Hibernating / Lost"
        else:
            return "Promising / Developing"

    df["rfm_segment"] = df.apply(assign_segment, axis=1)

    # Customer High-Level Tier (for executive presentation)
    def assign_tier(row):
        if row["m_score"] == 5:
            return "Top Tier (VIP)"
        elif row["m_score"] in [3, 4]:
            return "Mid Tier (Core)"
        else:
            return "Low Tier (Standard)"

    df["customer_tier"] = df.apply(assign_tier, axis=1)

    # -------------------------------------------------------------------------
    # 3. Optional K-Means Comparison Module
    # -------------------------------------------------------------------------
    if include_kmeans:
        print("  -> [3/4] Running optional K-Means clustering comparison (k=4)...")
        # Log-transform skewed RFM features
        rfm_features = df[["recency_days", "frequency_orders", "monetary_spend"]].copy()
        rfm_log = np.log1p(rfm_features)

        scaler = StandardScaler()
        rfm_scaled = scaler.fit_transform(rfm_log)

        kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
        df["kmeans_cluster"] = kmeans.fit_predict(rfm_scaled)
        print("     [OK] K-Means clustering fitted successfully.")

    # -------------------------------------------------------------------------
    # 4. Summary & Pareto Revenue Analysis
    # -------------------------------------------------------------------------
    print("  -> [4/4] Evaluating Segment Revenue Contributions & Pareto Share...")
    segment_summary = df.groupby("rfm_segment").agg(
        total_customers=("customer_unique_id", "count"),
        total_revenue=("monetary_spend", "sum"),
        avg_spend=("monetary_spend", "mean"),
        avg_orders=("frequency_orders", "mean"),
        avg_recency=("recency_days", "mean"),
        avg_review=("avg_review_score", "mean"),
        delayed_customer_pct=("experienced_delay_flag", lambda x: np.mean(x) * 100)
    ).reset_index()

    total_revenue_all = segment_summary["total_revenue"].sum()
    total_cust_all = segment_summary["total_customers"].sum()

    segment_summary["customer_share_pct"] = (segment_summary["total_customers"] / total_cust_all) * 100
    segment_summary["revenue_share_pct"] = (segment_summary["total_revenue"] / total_revenue_all) * 100
    segment_summary = segment_summary.sort_values(by="total_revenue", ascending=False)

    print("-" * 80)
    print(f"  {'RFM Segment':<26} | {'Cust %':>8} | {'Rev %':>8} | {'Avg Spend':>11} | {'Avg CSAT':>8}")
    print("-" * 80)
    for _, row in segment_summary.iterrows():
        print(f"  {row['rfm_segment']:<26} | {row['customer_share_pct']:>7.1f}% | {row['revenue_share_pct']:>7.1f}% | R$ {row['avg_spend']:>8.2f} | {row['avg_review']:>7.2f}")
    print("-" * 80)

    # Export to processed folder & SQLite database
    df.to_csv(OUTPUT_CSV, index=False)
    conn = sqlite3.connect(DB_PATH)
    df.to_sql("rfm_customer_segments", conn, if_exists="replace", index=False)
    conn.close()

    print(f"  [*] Exported RFM segmentation dataset: {OUTPUT_CSV}")
    print(f"  [*] Stored in SQLite database table: rfm_customer_segments")
    print("=" * 75)

    return df


if __name__ == "__main__":
    compute_rfm_segmentation()

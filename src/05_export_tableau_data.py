"""
==============================================================================
Module: 05_export_tableau_data.py
Description: Generates denormalized, performance-optimized data extracts
             for Tableau Desktop, Tableau Public, and Web Dashboards, along
             with machine-readable summary metrics.
==============================================================================
"""

import os
import json
import sqlite3
import pandas as pd

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_PROC_DIR = os.path.join(BASE_DIR, "data", "processed")
OUTPUTS_DIR = os.path.join(BASE_DIR, "outputs")
DB_PATH = os.path.join(DATA_PROC_DIR, "olist_data_warehouse.db")
RFM_CSV = os.path.join(DATA_PROC_DIR, "rfm_customer_segments.csv")

TABLEAU_ORDER_EXTRACT = os.path.join(DATA_PROC_DIR, "olist_modeled_tableau.csv")
TABLEAU_REGIONAL_CSV = os.path.join(DATA_PROC_DIR, "regional_revenue_logistics.csv")
SUMMARY_METRICS_JSON = os.path.join(OUTPUTS_DIR, "summary_metrics.json")


def export_tableau_extracts():
    print("=" * 75)
    print("  [*] TABLEAU DATA EXTRACT EXPORTER & METRICS COMPILER")
    print("=" * 75)

    conn = sqlite3.connect(DB_PATH)

    # -------------------------------------------------------------------------
    # 1. Denormalized Order Extract for Tableau
    # -------------------------------------------------------------------------
    print("  -> [1/3] Building denormalized order-level extract for Tableau...")
    order_query = """
    SELECT 
        fo.order_id,
        fo.customer_unique_id,
        fo.order_status,
        fo.purchase_timestamp,
        fo.purchase_date_key,
        fo.customer_delivered_timestamp,
        fo.estimated_delivery_timestamp,
        fo.order_total_value,
        fo.total_freight_value,
        fo.item_count,
        fo.delivery_transit_days,
        fo.delivery_delay_days,
        fo.is_delayed,
        fo.review_score,
        dc.customer_state,
        dc.customer_city,
        dg.macro_region,
        dg.latitude AS state_latitude,
        dg.longitude AS state_longitude
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_key = dc.customer_key
    JOIN dim_geography dg ON dc.customer_state = dg.state_code
    WHERE fo.order_status = 'delivered';
    """
    df_orders = pd.read_sql_query(order_query, conn)

    # Merge customer RFM segment details
    df_rfm = pd.read_csv(RFM_CSV)
    rfm_cols = [
        "customer_unique_id", "recency_days", "frequency_orders", "monetary_spend",
        "r_score", "f_score", "m_score", "rfm_cell", "rfm_segment", "customer_tier"
    ]
    df_merged = df_orders.merge(df_rfm[rfm_cols], on="customer_unique_id", how="left")

    # Add delay band description for easy Tableau dimension filtering
    def delay_band(days):
        if pd.isna(days):
            return "Unknown"
        if days <= -5:
            return "Early (>5 days)"
        elif days <= 0:
            return "On-Time (0-4 days early)"
        elif days <= 3:
            return "Minor Delay (1-3 days)"
        elif days <= 7:
            return "Moderate Delay (4-7 days)"
        else:
            return "Severe Delay (>7 days)"

    df_merged["delivery_delay_band"] = df_merged["delivery_delay_days"].apply(delay_band)
    df_merged["is_churned"] = (df_merged["frequency_orders"] == 1).astype(int)

    df_merged.to_csv(TABLEAU_ORDER_EXTRACT, index=False)
    print(f"     [OK] Order extract saved: {TABLEAU_ORDER_EXTRACT} ({len(df_merged):,} records)")

    # -------------------------------------------------------------------------
    # 2. Regional State Logistics & Revenue Aggregates
    # -------------------------------------------------------------------------
    print("  -> [2/3] Generating regional state summary for Tableau choropleth...")
    sql_path = os.path.join(BASE_DIR, "sql", "05_regional_revenue_logistics.sql")
    with open(sql_path, "r", encoding="utf-8") as f:
        regional_query = f.read()

    df_regional = pd.read_sql_query(regional_query, conn)
    conn.close()

    df_regional.to_csv(TABLEAU_REGIONAL_CSV, index=False)
    print(f"     [OK] Regional dataset saved: {TABLEAU_REGIONAL_CSV} ({len(df_regional)} Brazilian states)")

    # -------------------------------------------------------------------------
    # 3. Compile Machine-Readable Summary Metrics JSON
    # -------------------------------------------------------------------------
    print("  -> [3/3] Compiling executive summary metrics JSON...")
    total_orders = len(df_merged)
    total_unique_cust = df_merged["customer_unique_id"].nunique()
    total_gmv = round(float(df_merged["order_total_value"].sum()), 2)
    avg_order_val = round(float(df_merged["order_total_value"].mean()), 2)
    delay_rate_overall = round(float(df_merged["is_delayed"].mean() * 100), 2)
    avg_transit_days = round(float(df_merged["delivery_transit_days"].mean()), 1)

    # Top tier statistics
    top_tier_df = df_merged[df_merged["customer_tier"] == "Top Tier (VIP)"]
    top_tier_rev = round(float(top_tier_df["order_total_value"].sum()), 2)
    top_tier_share = round((top_tier_rev / total_gmv) * 100, 2)

    top_on_time = top_tier_df[top_tier_df["is_delayed"] == 0]
    top_delayed = top_tier_df[top_tier_df["is_delayed"] == 1]
    top_on_time_churn = round(float(top_on_time["is_churned"].mean() * 100), 2)
    top_delayed_churn = round(float(top_delayed["is_churned"].mean() * 100), 2)
    top_multiplier = round(top_delayed_churn / top_on_time_churn, 2)

    # Low tier statistics
    low_tier_df = df_merged[df_merged["customer_tier"] == "Low Tier (Standard)"]
    low_on_time_churn = round(float(low_tier_df[low_tier_df["is_delayed"] == 0]["is_churned"].mean() * 100), 2)
    low_delayed_churn = round(float(low_tier_df[low_tier_df["is_delayed"] == 1]["is_churned"].mean() * 100), 2)
    low_multiplier = round(low_delayed_churn / low_on_time_churn, 2)

    # Southeast vs Northeast regional comparison
    se_df = df_regional[df_regional["macro_region"] == "Southeast"]
    ne_df = df_regional[df_regional["macro_region"] == "Northeast"]

    se_rev_share = round(float(se_df["national_revenue_share_pct"].sum()), 2)
    se_delay_rate = round(float(se_df["delivery_delay_rate_pct"].mean()), 2)
    ne_delay_rate = round(float(ne_df["delivery_delay_rate_pct"].mean()), 2)
    ne_transit_days = round(float(ne_df["avg_transit_days"].mean()), 1)

    metrics_payload = {
        "dataset_name": "Brazilian E-Commerce Public Dataset (Olist)",
        "period": "September 2016 - October 2018",
        "total_orders": total_orders,
        "unique_customers": total_unique_cust,
        "total_gmv_brl": total_gmv,
        "avg_order_value_brl": avg_order_val,
        "overall_delay_rate_pct": delay_rate_overall,
        "overall_avg_transit_days": avg_transit_days,
        "top_tier_revenue_share_pct": top_tier_share,
        "top_tier_on_time_churn_pct": top_on_time_churn,
        "top_tier_delayed_churn_pct": top_delayed_churn,
        "top_tier_churn_multiplier": top_multiplier,
        "low_tier_churn_multiplier": low_multiplier,
        "csat_drop_vip": {
            "on_time": round(float(top_on_time["review_score"].mean()), 2),
            "delayed": round(float(top_delayed["review_score"].mean()), 2)
        },
        "regional_disparity": {
            "southeast_revenue_share_pct": se_rev_share,
            "southeast_delay_rate_pct": se_delay_rate,
            "northeast_delay_rate_pct": ne_delay_rate,
            "northeast_avg_transit_days": ne_transit_days
        }
    }

    with open(SUMMARY_METRICS_JSON, "w", encoding="utf-8") as f:
        json.dump(metrics_payload, f, indent=2)

    print(f"     [OK] Summary metrics compiled: {SUMMARY_METRICS_JSON}")
    print("=" * 75)


if __name__ == "__main__":
    export_tableau_extracts()

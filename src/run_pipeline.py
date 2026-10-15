"""
==============================================================================
Module: run_pipeline.py
Description: Master end-to-end orchestrator for the E-Commerce Revenue
             Segmentation & Logistics Sensitivity project.
==============================================================================
"""

import os
import sys
import time

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(BASE_DIR, "src")
DATA_RAW_DIR = os.path.join(BASE_DIR, "data", "raw")

sys.path.append(SRC_DIR)

import importlib


def execute_pipeline(force_generate: bool = False):
    total_start = time.time()
    print("=" * 80)
    print("   BRAZILIAN E-COMMERCE (OLIST) REVENUE SEGMENTATION & LOGISTICS PIPELINE")
    print("=" * 80)
    print("  Repository:  ecommerce-revenue-segmentation")
    print("  Author:      Ankur Pal")
    print("  Target:      Python · SQL · Tableau")
    print("=" * 80)

    # -------------------------------------------------------------------------
    # Step 1: Check / Generate Raw Data
    # -------------------------------------------------------------------------
    raw_orders_path = os.path.join(DATA_RAW_DIR, "olist_orders_dataset.csv")
    if force_generate or not os.path.exists(raw_orders_path):
        print("\n>>> [STEP 1/5] Synthesizing 100,000+ Olist Orders across 7 Tables...")
        step1 = importlib.import_module("01_generate_olist_data")
        step1.generate_dataset()
    else:
        print("\n>>> [STEP 1/5] Verified Raw Olist datasets present in data/raw/ (Skipping generation).")

    # -------------------------------------------------------------------------
    # Step 2: Build Kimball Star Schema in SQLite
    # -------------------------------------------------------------------------
    print("\n>>> [STEP 2/5] Building Kimball Star Schema Data Warehouse...")
    step2 = importlib.import_module("02_build_data_warehouse")
    step2.build_warehouse()

    # -------------------------------------------------------------------------
    # Step 3: Compute RFM Segmentation
    # -------------------------------------------------------------------------
    print("\n>>> [STEP 3/5] Computing Customer RFM Quantiles & Segment Mapping...")
    step3 = importlib.import_module("03_rfm_segmentation")
    step3.compute_rfm_segmentation(include_kmeans=True)

    # -------------------------------------------------------------------------
    # Step 4: Churn & Delivery Delay Sensitivity Analytics
    # -------------------------------------------------------------------------
    print("\n>>> [STEP 4/5] Running Logistics Delay & Churn Sensitivity Modeling...")
    step4 = importlib.import_module("04_churn_delay_analytics")
    step4.analyze_churn_delay_dynamics()

    # -------------------------------------------------------------------------
    # Step 5: Export Tableau Extracts & Summaries
    # -------------------------------------------------------------------------
    print("\n>>> [STEP 5/5] Exporting Denormalized Tableau Extracts & Visual Data...")
    step5 = importlib.import_module("05_export_tableau_data")
    step5.export_tableau_extracts()

    elapsed = time.time() - total_start
    print("\n" + "=" * 80)
    print(f"  [SUCCESS] End-to-End Pipeline Completed Successfully in {elapsed:.2f}s!")
    print("  Processed outputs ready in:")
    print("    - data/processed/olist_data_warehouse.db (SQLite Star Schema)")
    print("    - data/processed/rfm_customer_segments.csv")
    print("    - data/processed/olist_modeled_tableau.csv")
    print("    - data/processed/regional_revenue_logistics.csv")
    print("    - outputs/figures/ (Analytical Plots)")
    print("    - outputs/summary_metrics.json (Executive KPI Payloads)")
    print("=" * 80)


if __name__ == "__main__":
    force_gen = "--force-gen" in sys.argv
    execute_pipeline(force_generate=force_gen)

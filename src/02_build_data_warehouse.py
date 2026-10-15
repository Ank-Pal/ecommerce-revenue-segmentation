"""
==============================================================================
Module: 02_build_data_warehouse.py
Description: Ingests raw Olist relational CSVs, constructs the Kimball Star
             Schema in SQLite, executes ETL transformations, and validates
             dimensional integrity and record counts.
==============================================================================
"""

import os
import time
import sqlite3
import pandas as pd

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
DATA_PROC_DIR = os.path.join(BASE_DIR, "data", "processed")
SQL_DIR = os.path.join(BASE_DIR, "sql")
DB_PATH = os.path.join(DATA_PROC_DIR, "olist_data_warehouse.db")

os.makedirs(DATA_PROC_DIR, exist_ok=True)


def build_warehouse():
    start_time = time.time()
    print("=" * 75)
    print("  [*] OLIST DATA WAREHOUSE ETL & STAR SCHEMA PIPELINE")
    print(f"  [*] Database Path: {DB_PATH}")
    print("=" * 75)

    # Ensure clean slate
    if os.path.exists(DB_PATH):
        try:
            os.remove(DB_PATH)
        except Exception:
            pass

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # -------------------------------------------------------------------------
    # Step 1: Load Raw Staging Tables
    # -------------------------------------------------------------------------
    print("  -> [1/4] Staging raw relational CSVs into SQLite staging tables...")
    staging_files = [
        ("stg_orders", "olist_orders_dataset.csv"),
        ("stg_order_items", "olist_order_items_dataset.csv"),
        ("stg_payments", "olist_order_payments_dataset.csv"),
        ("stg_customers", "olist_customers_dataset.csv"),
        ("stg_reviews", "olist_order_reviews_dataset.csv"),
        ("stg_products", "olist_products_dataset.csv"),
        ("stg_geolocation", "olist_geolocation_dataset.csv"),
    ]

    for table_name, csv_name in staging_files:
        csv_path = os.path.join(DATA_RAW_DIR, csv_name)
        if not os.path.exists(csv_path):
            raise FileNotFoundError(f"Missing required raw file: {csv_path}")

        df = pd.read_csv(csv_path)
        df.to_sql(table_name, conn, if_exists="replace", index=False)
        print(f"     Loaded {table_name:<16}: {len(df):>8,} records")

    # -------------------------------------------------------------------------
    # Step 2: Execute Schema DDL
    # -------------------------------------------------------------------------
    print("  -> [2/4] Executing Kimball Star Schema DDL (01_schema_ddl.sql)...")
    ddl_path = os.path.join(SQL_DIR, "01_schema_ddl.sql")
    with open(ddl_path, "r", encoding="utf-8") as f:
        ddl_script = f.read()
    cursor.executescript(ddl_script)
    conn.commit()
    print("     [OK] Dimensions & Fact tables created with indexes.")

    # -------------------------------------------------------------------------
    # Step 3: Execute Dimensional ETL Transformations
    # -------------------------------------------------------------------------
    print("  -> [3/4] Transforming and populating Star Schema (02_etl_star_schema.sql)...")
    etl_path = os.path.join(SQL_DIR, "02_etl_star_schema.sql")
    with open(etl_path, "r", encoding="utf-8") as f:
        etl_script = f.read()
    cursor.executescript(etl_script)
    conn.commit()
    print("     [OK] Data warehouse facts & dimensions successfully populated.")

    # -------------------------------------------------------------------------
    # Step 4: Verification & Audit Queries
    # -------------------------------------------------------------------------
    print("  -> [4/4] Auditing Data Warehouse integrity & record counts...")
    audit_tables = [
        "dim_geography",
        "dim_dates",
        "dim_customers",
        "dim_products",
        "fact_orders",
        "fact_order_items"
    ]
    
    print("-" * 55)
    print(f"  {'Table Name':<20} | {'Record Count':>15} | Status")
    print("-" * 55)
    for tbl in audit_tables:
        cursor.execute(f"SELECT COUNT(*) FROM {tbl};")
        count = cursor.fetchone()[0]
        status = "[PASSED]" if count > 0 else "[FAILED]"
        print(f"  {tbl:<20} | {count:>15,} | {status}")
    print("-" * 55)

    # Clean up staging tables to optimize warehouse size
    for table_name, _ in staging_files:
        cursor.execute(f"DROP TABLE IF EXISTS {table_name};")
    conn.commit()
    cursor.execute("VACUUM;")
    conn.close()

    elapsed = time.time() - start_time
    print(f"  [ETL COMPLETE] Data warehouse built in {elapsed:.2f} seconds.")
    print("=" * 75)


if __name__ == "__main__":
    build_warehouse()

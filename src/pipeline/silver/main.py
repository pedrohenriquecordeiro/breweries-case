import sys
import os
import logging
from delta.tables import DeltaTable
from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp
from pyspark.sql.utils import AnalysisException


logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

if __name__ == "__main__":
    
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/app/.secrets/gke-service-account.json"

    spark = (
        SparkSession.builder
        .appName("ETL Silver Job")
        .config("spark.sql.parquet.datetimeRebaseModeInRead", "CORRECTED")
        .config("spark.sql.parquet.datetimeRebaseModeInWrite", "CORRECTED")
        .config("spark.hadoop.fs.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem")
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
        .config("spark.databricks.delta.retentionDurationCheck.enabled", "false")
        .config("spark.dynamicAllocation.shuffleTracking.enabled", "true")  # Kubernetes-safe
        .config("spark.sql.adaptive.enabled", "true")  # Boost performance on joins and skewed data
        .getOrCreate()
    )

    # ------------------------------------------------------------------------------
    # Define GCS paths for bronze and silver layers
    # ------------------------------------------------------------------------------
    bronze_path = "gs://bees-storage/bronze/data/"
    silver_path = "gs://bees-storage/silver/"

    # ------------------------------------------------------------------------------
    # Read bronze data from GCS (JSON), handle missing data
    # ------------------------------------------------------------------------------
    try:
        df_bronze = spark.read.option("multiLine", True).json(bronze_path)
        df_bronze.createOrReplaceTempView("bronze")
        
    except AnalysisException as e:
        logging.error(f"Bronze path not found or unreadable at {bronze_path}: {e}")
        sys.exit(1)

    logging.info(df_bronze.printSchema())
    
    # ------------------------------------------------------------------------------
    # Read silver Delta table, or initialize if missing
    # ------------------------------------------------------------------------------
    try:
        df_silver = spark.read.format("delta").load(silver_path)
        df_silver.createOrReplaceTempView("silver")
        
    except AnalysisException:
        logging.warning(f"Silver table not found at {silver_path}. Initializing empty Delta table.")
        
        # create an empty Delta table using bronze schema
        empty_silver = spark.createDataFrame([], df_bronze.schema)
        empty_silver.write.format("delta").mode("overwrite").partitionBy("country","state", "city").save(silver_path)
        empty_silver.createOrReplaceTempView("silver")

    logging.info("Successfully loaded bronze and silver data.")
    
    # ------------------------------------------------------------------------------
    # Identify new records using LEFT ANTI JOIN (bronze - silver)
    # ------------------------------------------------------------------------------
    new_records_df = spark.sql("""
        SELECT 
            CAST(bronze.id             AS STRING) AS id,
            CAST(bronze.name           AS STRING) AS name,
            CAST(bronze.brewery_type   AS STRING) AS brewery_type,
            CAST(bronze.address_1      AS STRING) AS address_1,
            CAST(bronze.address_2      AS STRING) AS address_2,
            CAST(bronze.address_3      AS STRING) AS address_3,
            CAST(bronze.city           AS STRING) AS city,
            CAST(bronze.state_province AS STRING) AS state_province,
            CAST(bronze.postal_code    AS STRING) AS postal_code,
            CAST(bronze.country        AS STRING) AS country,
            CAST(bronze.longitude      AS DOUBLE) AS longitude,
            CAST(bronze.latitude       AS DOUBLE) AS latitude,
            CAST(bronze.phone          AS STRING) AS phone,
            CAST(bronze.website_url    AS STRING) AS website_url,
            CAST(bronze.state          AS STRING) AS state,
            CAST(bronze.street         AS STRING) AS street
        FROM 
            bronze
            LEFT ANTI JOIN silver
                ON bronze.id = silver.id
    """)

    # ------------------------------------------------------------------------------
    # Add ingestion timestamp and repartition new records
    # ------------------------------------------------------------------------------
    logging.info(f"Add ingestion timestamp to new records and repartition by country, state and city.")
    new_records_df = new_records_df.withColumn("ingestion_at", current_timestamp())
    new_records_df = new_records_df.repartition("country", "state", "city")

    # ------------------------------------------------------------------------------
    # Append new records to silver Delta table (partitioned)
    # ------------------------------------------------------------------------------
    if new_records_df.take(1):
        (
            new_records_df
                .write
                .format("delta")
                .option("mergeSchema", "true")
                .partitionBy("country", "state", "city")
                .mode("append")
                .save(silver_path)
        )
        logging.info("Appended new records to silver table.")
        
    else:
        logging.info("No new records to append.")

    spark.stop()
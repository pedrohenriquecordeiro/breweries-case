# Silver Layer ETL

This folder contains the "silver" layer ETL job for the Bees Data Platform. The silver job is responsible for transforming and deduplicating raw data ingested by the bronze layer, producing curated Delta Lake tables in Google Cloud Storage (GCS). This job is designed to run as a containerized Spark application on Kubernetes.

## Overview

The silver ETL job reads raw brewery data from the bronze layer (stored as JSON in GCS), enforces schema consistency, deduplicates records and performs incremental loading. It writes the cleaned, partitioned data as a Delta Lake table to the silver layer in GCS. The process ensures that only new records are appended, maintaining data integrity and supporting efficient downstream analytics.

## Codebase Breakdown

- **main.py**  
  The main Spark application script. It:
  - Configures the Spark session for GCS and Delta Lake integration.
  - Reads raw JSON data from the bronze layer in GCS.
  - Loads or initializes the silver Delta table.
  - Identifies new records using a left anti join (bronze minus silver).
  - Adds ingestion timestamps and repartitions data for optimized storage.
  - Appends new records to the silver Delta table, partitioned by country, state and city.
  - Performs Delta Lake vacuuming to remove obsolete data files.

- **Dockerfile**  
  Defines the container image for the silver ETL job. It:
  - Uses a Bitnami Spark base image.
  - Installs required Python packages and Spark JARs for Delta Lake and GCS integration.
  - Copies the application code and service account credentials.
  - Sets up the execution environment for running the Spark job.

- **gke-service-account.json**  
  Google Cloud service account key file used for authenticating with GCS.  
  **Note:** This file should be kept secure and never committed to public repositories.

## Key Libraries and Tools

- **Apache Spark:** Distributed data processing engine for scalable ETL and analytics.
- **Delta Lake (`delta-spark`):** Provides ACID transactions and efficient data management on top of Parquet files in GCS.
- **Google Cloud Storage (GCS):** Cloud object storage for bronze and silver data layers.
- **google-cloud-storage:** Python client for GCS operations.
- **Py4J:** Enables Python-Java integration for Spark.
- **Docker:** Containerizes the ETL job for reproducible, scalable execution.
- **Bitnami Spark Image:** Production-ready Spark runtime with OpenJDK.

## Folder and File Structure

```
silver/
├── Dockerfile                  # Container definition for the Spark ETL job
├── gke-service-account.json    # GCP service account key (keep secure)
└── main.py                     # Main Spark ETL script for the silver layer
```

- **Dockerfile:** Builds the Spark job image, installs dependencies and sets up secrets.
- **main.py:** Orchestrates the ETL process, including reading from bronze, deduplicating and writing to silver.
- **gke-service-account.json:** Credentials for GCS access (should be injected securely in production).

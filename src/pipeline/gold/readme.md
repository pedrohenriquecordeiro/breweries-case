# Gold Layer ETL

This folder contains the "gold" layer ETL job for the Bees Data Platform. The gold job is responsible for transforming and aggregating curated data from the silver layer, producing analytics-ready datasets stored in Delta Lake format on Google Cloud Storage (GCS). This job is designed to run as a containerized Spark application on Kubernetes.

## Overview

The gold ETL job reads processed data from the silver Delta table in GCS, performs aggregations (such as brewery counts by type, country, state and city) and writes the results to the gold Delta table. It ensures that the analytics layer is always up-to-date and optimized for downstream consumption. The job also manages Delta Lake housekeeping tasks, such as vacuuming old data versions.

## Codebase Breakdown

- **main.py**  
  The main Spark application script. It:
  - Configures the Spark session for GCS and Delta Lake integration.
  - Reads the silver Delta table from GCS.
  - Aggregates brewery data by relevant dimensions.
  - Writes the aggregated results to the gold Delta table in overwrite mode.
  - Performs Delta Lake vacuuming to remove obsolete data files.

- **Dockerfile**  
  Defines the container image for the gold ETL job. It:
  - Uses a Bitnami Spark base image.
  - Installs required Python packages and Spark JARs for Delta Lake and GCS integration.
  - Copies the application code and service account credentials.
  - Sets up the execution environment for running the Spark job.

- **gke-service-account.json**  
  Google Cloud service account key file used for authenticating with GCS.  
  **Note:** This file should be kept secure and never committed to public repositories.

## Key Libraries and Tools

- **Apache Spark:** Distributed data processing engine for large-scale ETL and analytics.
- **Delta Lake (`delta-spark`):** Enables ACID transactions and efficient data management on top of Parquet files in GCS.
- **Google Cloud Storage (GCS):** Cloud object storage for Delta tables and data files.
- **google-cloud-storage:** Python client for GCS operations.
- **Py4J:** Enables Python-Java integration for Spark.
- **Docker:** Containerizes the ETL job for reproducible, scalable execution.
- **Bitnami Spark Image:** Provides a production-ready Spark runtime with OpenJDK.

## Folder and File Structure

```
gold/
├── Dockerfile                  # Container definition for the Spark ETL job
├── gke-service-account.json    # GCP service account key (keep secure)
└── main.py                     # Main Spark ETL script for the gold layer
```

- **Dockerfile:** Builds the Spark job image, installs dependencies and sets up secrets.
- **main.py:** Orchestrates the ETL process, including reading from silver, aggregating and writing to gold.
- **gke-service-account.json:** Credentials for GCS access (should be injected securely in production).

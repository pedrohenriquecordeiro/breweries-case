# Bees Data Platform: Pipeline Jobs

This folder contains the ETL pipeline jobs for the Bees Data Platform, organized by data lakehouse layer: bronze (raw ingestion), silver (curation and deduplication) and gold (analytics and aggregation). Each job is containerized for scalable execution on Kubernetes and interacts with Google Cloud Storage (GCS) for data persistence.

## Key Components

- **Bronze:** Ingests raw data from the Open Brewery DB API, stores it as JSON in GCS and manages incremental or full loads with metadata.
- **Silver:** Reads raw data from bronze, applies schema enforcement and deduplication and writes curated Delta Lake tables to GCS.
- **Gold:** Aggregates curated data from silver, producing analytics-ready Delta tables for downstream consumption.

## Main Libraries and Tools

- **Python & Apache Spark:** Core technologies for ETL logic and distributed processing.
- **Delta Lake:** Provides ACID-compliant, scalable storage on GCS.
- **Docker:** Containerizes each ETL job for reproducibility.
- **Kubernetes:** Orchestrates job execution in the cloud.

## Usage

1. Build Docker images for each layer (`bronze/`, `silver/`, `gold/`).
2. Deploy and run jobs on Kubernetes with appropriate GCP credentials.
3. Ensure service account keys are securely managed and not committed to version control.

## Details

- For details on the bronze layer job, see [bronze/readme](bronze/readme.md).
- For details on the silver layer job, see [silver/readme](silver/readme.md).
- For details on the gold layer job, see [gold/readme](gold/readme.md).
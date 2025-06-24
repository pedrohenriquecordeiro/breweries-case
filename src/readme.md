# Bees Data Platform: Source Code

This folder contains the core source code for the Bees Data Platform, a modular and cloud-native data pipeline built on Google Cloud Platform (GCP). The platform ingests, processes, validates and orchestrates data using a layered lakehouse architecture (bronze, silver, gold) and leverages Kubernetes for scalable execution.

## Structure and Key Components

- **pipeline/**: ETL jobs for each data layer:
  - **bronze/**: Ingests raw data from external APIs into GCS.
  - **silver/**: Cleans, deduplicates and curates data as Delta Lake tables.
  - **gold/**: Aggregates and transforms curated data for analytics.
- **dags/**: Apache Airflow DAGs for orchestrating ETL workflows on Kubernetes.
- **tests/**: Data quality validation jobs using PyDeequ and Spark.

## Main Libraries and Tools

- **Python & Apache Spark**: Core languages for ETL and analytics.
- **Delta Lake**: ACID-compliant storage on GCS.
- **Docker**: Containerizes jobs for reproducibility.
- **Kubernetes**: Orchestrates job execution.
- **Apache Airflow**: Workflow scheduling and orchestration.
- **PyDeequ**: Automated data quality checks.

## Details

- To view the pipeline code, refer to [pipeline/readme.md](pipeline/readme.md).
- For DAGs, see [dags/readme.md](dags/readme.md).
- For data quality validation jobs, refer to [tests/readme.md](tests/readme.md).
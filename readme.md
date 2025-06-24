# Breweries Case

## Overview

**Breweries Case** is a modular, cloud-native data platform designed for ingesting, processing, validating and analyzing brewery data at scale. Built on Google Cloud Platform (GCP), it implements a layered data lakehouse architecture (Bronze, Silver, Gold) and orchestrates ETL workflows using Apache Airflow and Kubernetes. The platform ensures data quality, reproducibility and scalability, making it ideal for analytics and reporting use cases.

## Codebase Breakdown

### Core Components

- **ETL Pipelines (`src/pipeline/`)**  
  - **bronze/**: Ingests raw data from the Open Brewery DB API, stores it as JSON in GCS and manages incremental or full loads with metadata.
  - **silver/**: Reads raw data from bronze, applies schema enforcement and deduplication and writes curated Delta Lake tables to GCS.
  - **gold/**: Aggregates curated data from silver, producing analytics-ready Delta tables for downstream consumption.

- **Orchestration (`src/dags/`)**  
  Contains Apache Airflow DAGs that coordinate ETL tasks across Kubernetes workloads, including Python-based ETL jobs and Spark applications.

- **Data Quality Tests (`src/tests/`)**  
  Containerized Spark jobs using PyDeequ to validate the integrity, completeness and correctness of curated data (silver layer).

- **Infrastructure (`infra/`)**  
  Infrastructure-as-code for provisioning GCP resources (Terraform), Kubernetes manifests and Helm charts for deploying Airflow and the Spark Operator.

- **Notebooks (`notebooks/`)**  
  Jupyter notebooks for data exploration and analytics using the processed data. Users can visualize and analyze brewery data interactively.

- **Setup Scripts (`setup/`)**  
  Shell scripts for environment setup on macOS and Ubuntu.

- **Documentation (`docs/`)**  
  Detailed architecture, setup and usage guides.

## Key Libraries and Tools

- **Google Cloud Platform (GCP):** Cloud infrastructure, storage (GCS) and managed Kubernetes (GKE).
- **Apache Airflow:** Orchestrates and schedules ETL workflows.
- **Apache Spark & Delta Lake:** Distributed ETL and ACID-compliant data storage.
- **PyDeequ:** Automated data quality validation on Spark DataFrames.
- **Terraform:** Infrastructure-as-code for reproducible cloud resource provisioning.
- **Helm:** Kubernetes package manager for deploying Airflow and the Spark Operator.
- **Docker:** Containerization for ETL and validation jobs.
- **Kubernetes:** Orchestrates containerized workloads for scalability and reliability.

## Folder and File Structure

```
breweries-case/
├── .gitignore
├── readme.md
├── docs/                       # Documentation for architecture and setup
│   ├── architecture.md
│   ├── setup.md
│   └── images/
├── infra/                      # Infrastructure-as-code and deployment configs
│   ├── .env
│   ├── readme.md
│   ├── terraform/              # Terraform code for GCP resources
│   └── kubernetes/             # Kubernetes manifests and Helm charts
│       ├── airflow/
│       └── spark-operator/
├── notebooks/                  # Jupyter notebooks for analytics
│   └── show.ipynb
├── setup/                      # Environment setup scripts
│   ├── macos.sh
│   └── ubuntu.sh
├── src/                        # Core source code
│   ├── readme.md
│   ├── dags/                   # Airflow DAGs for pipeline orchestration
│   ├── pipeline/               # ETL jobs for each data layer
│   │   ├── bronze/
│   │   ├── silver/
│   │   └── gold/
│   └── tests/                  # Data quality validation jobs
```

### Details

- For infrastructure setup, see [infra/readme.md](infra/readme.md).
- For the main source code, refer to [src/readme.md](src/readme.md).
- For setup scripts, see [setup/readme.md](setup/readme.md).
- For documentation, see the `docs/` folder.

# Breweries Case

## Overview

**Breweries Case** is a modular, cloud-native data platform for ingesting, processing, validating and analyzing brewery data at scale. Built on Google Cloud Platform (GCP), it leverages a layered data lakehouse architecture (Bronze, Silver, Gold) and orchestrates ETL workflows using Apache Airflow and Kubernetes. The platform emphasizes data quality, reproducibility and scalability, making it ideal for analytics and reporting.

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

- **Notebooks (`src/notebooks/`)**  
  Jupyter notebooks for interactive data exploration and analytics using the processed data.

- **Infrastructure (`infra/`)**  
  Infrastructure-as-code for provisioning GCP resources (Terraform), Kubernetes manifests and Helm charts for deploying Airflow and the Spark Operator.

- **Documentation (`docs/`)**  
  Comprehensive architecture, setup and usage guides.

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

## Data Catalog

The Breweries Case platform ingests data from the public Open Brewery DB API, which provides structured, machine-readable JSON data. The ETL pipeline retrieves this data via HTTP requests, handling pagination, rate limits and network errors to ensure reliable and complete extraction. Raw API data is stored in the bronze layer, preserving its original structure for traceability and future reprocessing.

| Column           | Type      | Description                                                                 |
|------------------|-----------|-----------------------------------------------------------------------------|
| id               | string    | Unique identifier (UUID) for the brewery                                    |
| name             | string    | Name of the brewery                                                         |
| brewery_type     | string    | Type of brewery (e.g., micro, brewpub, planning, contract)                  |
| address_1        | string    | Primary street address                                                      |
| address_2        | string    | Secondary address line (optional)                                           |
| address_3        | string    | Tertiary address line (optional)                                            |
| city             | string    | City where the brewery is located                                           |
| state_province   | string    | State or province                                                           |
| postal_code      | string    | Postal or ZIP code                                                          |
| country          | string    | Country                                                                     |
| longitude        | float     | Longitude coordinate (nullable)                                             |
| latitude         | float     | Latitude coordinate (nullable)                                              |
| phone            | string    | Contact phone number (nullable)                                             |
| website_url      | string    | Website URL (nullable)                                                      |
| state            | string    | State name                                                                  |
| street           | string    | Street address                                                               |

### Additional Resources

- For infrastructure setup, see [infra/readme.md](infra/readme.md).
- For the main source code, refer to [src/readme.md](src/readme.md).
- For setup scripts, see [setup/readme.md](setup/readme.md).
- For documentation, see the `docs/` folder.


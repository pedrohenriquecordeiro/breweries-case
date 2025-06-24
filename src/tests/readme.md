# Data Quality Tests

This folder contains the data quality validation suite for the Bees Data Platform. The tests are designed to ensure the integrity, consistency and correctness of data processed through the ETL pipeline, with a focus on validating the silver-layer Delta tables stored in Google Cloud Storage (GCS). The tests are implemented as a containerized Spark job using PySpark and PyDeequ and are intended to run on Kubernetes.

## Overview

The data quality job reads the curated silver Delta table from GCS, validates its schema and runs a series of automated data quality checks using PyDeequ. These checks include schema validation, completeness, uniqueness and custom business rules. The results help maintain high data quality standards and provide early detection of data issues.

## Codebase Breakdown

- **main.py**  
  The main entry point for the data quality job. It:
  - Configures the Spark session for GCS and Delta Lake.
  - Loads the silver Delta table from GCS.
  - Validates the schema against expected field names and types.
  - Runs PyDeequ checks for completeness, uniqueness and other constraints.
  - Logs results and highlights any detected data quality issues.

- **Dockerfile**  
  Defines the container image for the data quality job. It:
  - Uses a Bitnami Spark base image.
  - Installs required JARs for Delta Lake, Iceberg and Deequ.
  - Installs Python dependencies, including PyDeequ.
  - Copies the application code and service account credentials.

- **gke-service-account.json**  
  Google Cloud service account key file for authenticating with GCS.  
  **Note:** This file should be kept secure and never committed to public repositories.

## Key Libraries and Tools

- **Apache Spark:** Distributed data processing engine for scalable validation.
- **Delta Lake:** ACID-compliant storage layer for reliable data management on GCS.
- **PyDeequ:** Python wrapper for Deequ, enabling declarative data quality checks on Spark DataFrames.
- **Deequ:** Library for defining and running data quality checks on large datasets.
- **google-cloud-storage:** Python client for GCS operations.
- **Docker:** Containerizes the test job for reproducible execution.
- **Bitnami Spark Image:** Provides a production-ready Spark runtime with OpenJDK.

## Folder and File Structure

```
tests/
├── Dockerfile                  # Container definition for the data quality job
├── gke-service-account.json    # GCP service account key (keep secure)
├── main.py                     # Main data quality validation script
└── readme.md                   # References and documentation links
```

- **Dockerfile:** Builds the test job image, installs dependencies and sets up secrets.
- **main.py:** Orchestrates data quality validation, including schema and business rule checks.
- **gke-service-account.json:** Credentials for GCS access (should be injected securely in production).
- **readme.md:** Provides links to PyDeequ and Deequ documentation.

## References

- [PyDeequ Documentation – README](https://pydeequ.readthedocs.io/en/latest/README.html)  
- [AWS Labs Deequ GitHub Repository](https://github.com/awslabs/deequ)

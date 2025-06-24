# Bronze Layer ETL

This folder contains the "bronze" layer ETL job for the Bees Data Platform. The bronze job is responsible for ingesting raw data from the Open Brewery DB API, storing it in Google Cloud Storage (GCS) and maintaining metadata for both incremental and full data loads. This job is designed to run as a containerized workload on Kubernetes.

## Overview

The bronze ETL job fetches brewery data from a public API, saves new or updated records as JSON files in a GCS bucket and tracks the latest processed record using a metadata file stored in the same bucket. It supports both incremental and full loads, ensuring efficient and reliable ingestion of external data into the platform's data lake.

## Codebase Breakdown

- **main.py**  
  The entry point for the ETL job. Handles orchestration, including:
  - Loading metadata to determine whether to perform an incremental or full load
  - Fetching data from the API
  - Filtering and saving new records to GCS
  - Updating metadata after each run

- **functions.py**  
  Contains utility functions for:
  - Loading and saving metadata from/to GCS
  - Saving JSON files to GCS
  - Logging and error handling for GCS operations

- **Dockerfile**  
  Defines the container image for the ETL job. Installs dependencies, copies code and sets up the environment for secure execution with GCP credentials.

- **gke-service-account.json**  
  Service account key file for authenticating with Google Cloud Storage. **(Should be kept secure and never committed to public repositories.)**

## Key Libraries and Tools

- **Python 3.12:** Main programming language for the ETL logic.
- **google-cloud-storage:** Python client for interacting with GCS.
- **requests:** For making HTTP requests to the Open Brewery DB API.
- **logging:** Standard Python logging for observability.
- **Docker:** Containerizes the ETL job for reproducible and scalable execution.

## Folder and File Structure

```
bronze/
├── Dockerfile                  # Container definition for the ETL job
├── functions.py                # Utility functions for GCS and metadata operations
├── gke-service-account.json    # GCP service account key (keep secure)
└── main.py                     # Main ETL orchestration script
```

- **Dockerfile:** Builds the ETL job image, installs dependencies and sets up secrets.
- **main.py:** Orchestrates the ETL process, including API interaction and GCS operations.
- **functions.py:** Provides reusable functions for file and metadata management in GCS.
- **gke-service-account.json:** Credentials for GCS access (should be injected securely in production).

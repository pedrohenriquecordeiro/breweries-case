# Setup Scripts for Breweries Case

This folder contains automated setup scripts for initializing the infrastructure and environment required by the **Breweries Case** data platform on macOS and Ubuntu systems.

## Purpose

The scripts streamline the installation of dependencies, provisioning of Google Cloud Platform (GCP) resources, and deployment of core services (Airflow, Spark Operator) on Kubernetes. They automate Docker image builds, service account configuration, and the upload of Airflow DAGs, enabling a fast and reproducible project setup.

## Tools Used

- **Google Cloud SDK:** CLI for managing GCP resources.
- **Terraform:** Infrastructure-as-code for provisioning cloud resources.
- **kubectl:** Kubernetes cluster management.
- **Helm:** Kubernetes package manager for deploying Airflow and Spark Operator.
- **Docker:** Containerization and image management.

## Usage

1. Ensure you have the required permissions and a valid `.env` file in `infra/`.
2. Run `macos.sh` (for macOS) or `ubuntu.sh` (for Ubuntu) from the project root:
   ```sh
   bash setup/macos.sh
   # or
   bash setup/ubuntu.sh
   ```
3. Follow any prompts for authentication or manual steps.

For detailed setup instructions, see
# Airflow Kubernetes Deployment

This folder contains configuration files for deploying Apache Airflow on Kubernetes using Helm. The setup leverages Google Cloud Storage (GCS) for persistent DAGs and logs and is designed for scalable, cloud-native workflow orchestration.

## Key Components

- **Apache Airflow:** An open-source platform for orchestrating complex data workflows.
- **Helm:** A package manager for Kubernetes, used to deploy and manage Airflow (`values_helm.yaml`).
- **Kubernetes:** Orchestrates Airflow components and ensures high availability.
- **GCSFuse:** Mounts Google Cloud Storage buckets as persistent volumes for DAGs and logs.
- **PostgreSQL & PgBouncer:** Provide Airflow metadata storage and connection pooling.

## Usage

1. Customize `values_helm.yaml` for your environment (SMTP, service accounts, etc.).
2. Apply the RBAC and persistent volume manifests:
   ```sh
   kubectl apply -f infra/kubernetes/airflow/rbac.yaml
   kubectl apply -f infra/kubernetes/airflow/pv-gcs-fuse-dags.yaml
   kubectl apply -f infra/kubernetes/airflow/pvc-gcs-fuse-dags.yaml
   kubectl apply -f infra/kubernetes/airflow/pv-gcs-fuse-logs.yaml
   kubectl apply -f infra/kubernetes/airflow/pvc-gcs-fuse-logs.yaml
   ```
3. Deploy Airflow with Helm:
   ```sh
   helm upgrade --install airflow apache-airflow/airflow \
     -f infra/kubernetes/airflow/values_helm.yaml --namespace airflow
   ```

For more details, see the main project README.
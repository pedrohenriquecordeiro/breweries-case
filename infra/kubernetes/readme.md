# Kubernetes Infrastructure Configurations

This folder contains Kubernetes manifests and Helm configuration files for deploying key data platform components on Google Kubernetes Engine (GKE). It enables scalable, cloud-native orchestration of data workflows and Spark jobs.

## Components

- **airflow/**: Helm and manifest files for deploying Apache Airflow, including persistent storage for DAGs/logs via GCSFuse and RBAC for secure operation.
- **spark-operator/**: Helm values and RBAC for deploying the Spark Operator, enabling native management of Apache Spark jobs on Kubernetes.

## Tools Used

- **Kubernetes**: Container orchestration platform for scalable deployments.
- **Helm**: Package manager for Kubernetes, used to install and configure Airflow and Spark Operator.
- **GCSFuse**: Mounts Google Cloud Storage buckets as persistent volumes.
- **RBAC**: Ensures secure access and operation of platform components.

## Usage

1. Customize the values in `infra/kubernetes/airflow/values_helm.yaml` and `infra/kubernetes/spark-operator/values_helm.yaml` as needed.
2. Apply RBAC and persistent volume manifests using `kubectl`.
3. Deploy Airflow and Spark Operator with Helm.

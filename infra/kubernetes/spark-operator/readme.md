# Spark Operator Kubernetes Deployment

This folder contains configuration files for deploying the Spark Operator on Kubernetes using Helm. The Spark Operator simplifies running and managing Apache Spark applications natively on Kubernetes clusters.

## Key Components

- **Spark Operator:** Extends Kubernetes to manage the lifecycle of Spark applications as custom resources.
- **Helm:** Used to install and configure the Spark Operator with custom settings (`values_helm.yaml`).
- **RBAC (rbac.yaml):** Defines the necessary permissions for the Spark Operator to manage Spark jobs securely within the cluster.

## Usage

1. Apply the RBAC configuration:
   ```sh
   kubectl apply -f infra/kubernetes/spark-operator/rbac.yaml
   ```
2. Add the Spark Operator Helm repository and install the operator:
   ```sh
   helm repo add spark-operator https://kubeflow.github.io/spark-operator --force-update
   helm upgrade --install spark-operator spark-operator/spark-operator \
     --wait \
     -f infra/kubernetes/spark-operator/values_helm.yaml \
     --namespace spark
   ```

Refer to the main project documentation for more details on submitting Spark jobs and advanced configuration.
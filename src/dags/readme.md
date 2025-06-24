
# Airflow DAGs for Bees Data Platform

This folder contains Apache Airflow DAGs that orchestrate the end-to-end data pipeline for the Bees Data Platform. The DAGs coordinate ETL tasks across multiple Kubernetes workloads, including Python-based ETL jobs and Spark applications, to process and analyze data efficiently.

## Key Components

- **Apache Airflow:** Manages and schedules data workflows using Python DAGs.
- **KubernetesPodOperator:** Runs containerized ETL jobs (e.g., bronze layer) on Kubernetes.
- **SparkKubernetesOperator:** Submits and manages Spark jobs on Kubernetes via the Spark Operator.
- **Google Kubernetes Engine (GKE):** Hosts all containerized workloads for scalability and reliability.

## Usage

1. Ensure Airflow is deployed with access to the required Kubernetes namespaces and service accounts.
2. Update Docker image references in the DAGs as needed for your environment.
3. Upload DAG files to your Airflow DAGs folder or sync with a GCS bucket if using GCSFuse.
4. Monitor and manage pipeline execution via the Airflow UI.

For more details on writing SparkApplication manifests and configuring Kubernetes resources, see the references in [readme.md](readme.md).

## References

- [Kubeflow Spark Operator User Guide: Writing SparkApplication Manifests](https://www.kubeflow.org/docs/components/spark-operator/user-guide/writing-sparkapplication/)  
    Guidance on defining and configuring Spark jobs for Kubernetes using the Spark Operator.

- [Airflow Kubernetes Operators Documentation](https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/operators.html)  
    Details on using Kubernetes-related operators in Airflow, including usage examples.

- [SparkKubernetesOperator API Reference](https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/_api/airflow/providers/cncf/kubernetes/operators/spark_kubernetes/index.html)  
    API documentation for the SparkKubernetesOperator in Airflow.


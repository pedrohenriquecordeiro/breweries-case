# Infrastructure for Bees Data Platform

This folder contains all infrastructure-as-code and deployment configuration for the Bees Data Platform. It enables automated, reproducible provisioning and management of cloud resources, Kubernetes workloads and supporting services on Google Cloud Platform (GCP).



## Overview

The infra codebase provisions and configures the foundational cloud and Kubernetes infrastructure required to run data pipelines, orchestrate workflows and manage analytics workloads. It leverages Terraform for declarative infrastructure management and Kubernetes manifests/Helm charts for deploying and configuring platform components such as Apache Airflow and the Spark Operator.



## Codebase Breakdown

- **terraform/**  
  Contains all Terraform code for provisioning GCP resources, including networking, IAM, GKE clusters, storage buckets and artifact registries. This is the entry point for infrastructure provisioning.

- **kubernetes/**  
  Contains Kubernetes manifests and Helm configuration for deploying and managing platform services on GKE, including Airflow and Spark Operator. Subfolders organize resources by component.

- **.env**  
  Environment variable file for Terraform and deployment scripts (never commit secrets).



## Key Libraries and Tools

- **Terraform:**  
  Infrastructure as code tool for declarative provisioning and management of cloud resources.

- **Google Cloud Platform (GCP):**  
  Cloud provider for compute, storage, IAM and managed Kubernetes (GKE).

- **Kubernetes:**  
  Container orchestration platform for scalable, resilient deployment of platform components.

- **Helm:**  
  Kubernetes package manager, used to deploy and configure Airflow and Spark Operator.

- **GCSFuse:**  
  Mounts Google Cloud Storage buckets as persistent volumes for Airflow DAGs and logs.

- **RBAC:**  
  Role-Based Access Control for secure operation of Kubernetes workloads.



## Folder and File Structure

```
infra/
├── .env                           # Environment variables for Terraform and deployment
├── terraform/                     # Terraform code for GCP resource provisioning
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Input variables for Terraform modules
│   ├── outputs.tf                 # Outputs from Terraform resources
│   ├── network.tf                 # VPC and networking resources
│   ├── gke.tf                     # GKE cluster configuration
│   ├── gke_node_pool.tf           # Node pool definitions for GKE
│   ├── iam.tf                     # IAM roles and service accounts
│   ├── storage.tf                 # GCS buckets and storage resources
│   └── artifact_registry.tf       # Artifact Registry for Docker images
├── kubernetes/                    # Kubernetes manifests and Helm configs
│   ├── airflow/                   # Airflow deployment configs
│   │   ├── pv-gcs-fuse-dags.yaml  # Persistent volume for DAGs
│   │   ├── pv-gcs-fuse-logs.yaml  # Persistent volume for logs
│   │   ├── pvc-gcs-fuse-dags.yaml # Persistent volume claim for DAGs
│   │   ├── pvc-gcs-fuse-logs.yaml # Persistent volume claim for logs
│   │   ├── rbac.yaml              # RBAC for Airflow
│   │   ├── values_helm.yaml       # Helm values for Airflow deployment
│   │   └── readme.md              # Airflow deployment instructions
│   ├── spark-operator/            # Spark Operator deployment configs
│   │   ├── rbac.yaml              # RBAC for Spark Operator
│   │   ├── values_helm.yaml       # Helm values for Spark Operator
│   │   └── readme.md              # Spark Operator deployment instructions
│   └── readme.md                  # Overview of Kubernetes configs
└── readme.md                      # This documentation file
```

---

## Details
- For see terraform details, see the [terraform/readme](terraform/readme.md).
- For see kubernetes details, see the [kubernetes/readme](kubernetes/readme.md).
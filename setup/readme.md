# Setup Scripts for Breweries Case

This folder contains automated setup scripts for initializing the infrastructure and environment required by the **Breweries Case** data platform on macOS and Ubuntu systems.

## Purpose

These scripts streamline the installation of dependencies, provisioning of Google Cloud Platform (GCP) resources and deployment of core services (Airflow, Spark Operator) on Kubernetes. They automate Docker image builds, service account configuration and the upload of Airflow DAGs, enabling a fast and reproducible project setup.

# Required GCP Permissions to Execute the Script

If you're bootstrapping quickly, assigning the following roles is usually sufficient:
 - `roles/resourcemanager.projectCreator` (to create projects)
 - `roles/billing.user` (to link to billing)
 - `roles/owner` on the target project

Below is a breakdown of GCP IAM roles and permissions needed per script section:


| **Recommended IAM Role(s)**                            | **Key Permissions**                                                                 |
|--------------------------------------------------------|--------------------------------------------------------------------------------------|
| `roles/resourcemanager.projectCreator`                 | `resourcemanager.projects.create`                                                   |
| `roles/billing.user`                                   | `billing.resourceAssociations.create`                                               |
| `roles/viewer` or `roles/resourcemanager.projectViewer`| `resourcemanager.projects.get`, `resourcemanager.projects.list`                     |
| `roles/iam.serviceAccountKeyAdmin`                     | `iam.serviceAccountKeys.create`, `iam.serviceAccountKeys.list`                      |
| `roles/iam.serviceAccountAdmin`                        | `iam.serviceAccounts.setIamPolicy`, `iam.serviceAccounts.actAs`                     |
| `roles/iam.workloadIdentityUser`                       | `iam.serviceAccounts.setIamPolicy`, `iam.serviceAccounts.actAs`                     |
| `roles/storage.objectAdmin`                            | `storage.objects.create`, `storage.objects.get`, `storage.objects.list`             |
| `roles/artifactregistry.writer`                        | `artifactregistry.repositories.uploadArtifacts`, `artifactregistry.repositories.get`|
| `roles/container.clusterViewer`                        | `container.clusters.get`, `container.clusters.getCredentials`                       |
| `roles/container.developer` + Kubernetes RBAC          | `container.*` API access + Kubernetes cluster-admin (or scoped) permissions         |
| `roles/owner` (for Terraform bootstrap)                | Varies: permissions for GKE, IAM, Storage, Artifact Registry, etc.                  |





## Usage

1. Ensure you have the required permissions and a valid `.env` file in the `infra/` directory.
2. Run `macos.sh` (for macOS) or `ubuntu.sh` (for Ubuntu) from the project root:
   ```sh
   bash setup/macos.sh
   # or
   bash setup/ubuntu.sh
   ```
3. Follow any prompts for authentication or manual steps.

For detailed setup instructions, see the project documentation.
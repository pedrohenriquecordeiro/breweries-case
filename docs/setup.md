# Breweries-Case Project: Step-by-Step Reproducible Guide

This guide provides a detailed walkthrough of all critical setup and execution steps for the `breweries-case` project. 



## 1. Create a GCP Project

```bash
gcloud projects create <your-gcp-project-id> --name="Bees Project" --set-as-default
gcloud billing projects link <your-gcp-project-id> --billing-account=<your-billing-account-id>
```

## 2. Load Environment Variables

```plaintext
PROJECT_ID=<your-gcp-project-id>
TF_VAR_project_id=<your-gcp-project-id>
SMTP_PASSWORD=<your-smtp-password>
```

```bash
export $(grep -v '^#' infra/.env | xargs)
```

## 3. Install Google Cloud SDK

Install the Google Cloud SDK to interact with GCP services. This is required for managing GCP resources, authenticating and deploying applications.

```bash
brew install --cask google-cloud-sdk
```

**Dependencies:** Homebrew (macOS), curl (Linux).



## 4. Initialize and Authenticate with Google Cloud

```bash
gcloud init
gcloud auth login
gcloud auth list
gcloud components install gke-gcloud-auth-plugin
gcloud components update
```


- `gcloud init`: Set up project and auth.
- `auth login`: Authenticate your user.
- `auth list`: List all authenticated accounts.
- `components install`: Required for GKE cluster auth.



## 5. Create and Link GCP Project
Creates a new GCP project and links it to a billing account. Preferencially you need to be the owner of the billing account or have the necessary permissions to link projects to billing accounts.

```bash
gcloud projects create $PROJECT_ID --name="Bees Project" --set-as-default
gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
```


## 6. Install Developer Tools
Installs Terraform, kubectl and Helm.

```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install kubectl
brew install kubectx
brew install helm

# Linux -> can be installed via package manager or manually (check the file /setup/ubuntu.sh)

```



## 7. Provision Infrastructure with Terraform
Initializes and deploys infrastructure as code.
```bash
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform plan
terraform -chdir=infra/terraform apply --auto-approve
```




## 8. Create and Distribute GKE Service Account Key
Creates and distributes a service account key across different pipeline components. You need to have the necessary permissions to create service accounts and keys in your GCP project.
```bash
gcloud iam service-accounts keys create src/pipeline/bronze/gke-service-account.json --iam-account=gke-service-account@$PROJECT_ID.iam.gserviceaccount.com
cp src/pipeline/bronze/gke-service-account.json src/pipeline/silver/
cp src/pipeline/bronze/gke-service-account.json src/pipeline/gold/
cp src/pipeline/bronze/gke-service-account.json src/tests/
```



## 9. Configure Docker for Artifact Registry
Allows Docker to authenticate and push images to GCP Artifact Registry.

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## 10. Build and Push Docker Images
Builds and pushes Docker images for each ETL pipeline (bronze, silver, gold) and tests.

```bash
docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/$PROJECT_ID/bees-docker-repo/bronze/bees-etl-bronze-job:latest \
  --push src/pipeline/bronze/

docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/$PROJECT_ID/bees-docker-repo/silver/bees-etl-silver-job:latest  \
  --push src/pipeline/silver/

docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/$PROJECT_ID/bees-docker-repo/gold/bees-etl-gold-job:latest \
  --push src/pipeline/gold/

docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/$PROJECT_ID/bees-docker-repo/tests/bees-test-data-quality:latest \
  --push src/tests/
```



## 11. Upload Airflow DAGs to GCS
Copies Airflow DAGs to the DAGs bucket.

```bash
gsutil cp src/dags/*.py gs://bees-airflow-dags/
```


## 12. Configure GKE Context and Namespace
Connects to cluster and creates namespace.
```bash

gcloud container clusters get-credentials airflow-cluster --zone us-central1-c --project $PROJECT_ID
kubectl create namespace airflow
```

## 13. Apply Secrets and Permissions for Airflow
Sets up secrets and role bindings required for Airflow.
```bash
kubectl create secret generic gke-service-account-secret \
  --from-file=key.json=src/pipeline/silver/gke-service-account.json \
  -n airflow
kubectl apply -f infra/kubernetes/airflow/rbac.yaml
```

## 14. Grant Storage Access to GSA (Google Service Account)
Allows Airflow access to read/write logs and DAGs in GCS.

```bash
gcloud storage buckets add-iam-policy-binding gs://bees-airflow-logs \
  --member="serviceAccount:gke-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud storage buckets add-iam-policy-binding gs://bees-airflow-dags \
  --member="serviceAccount:gke-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```


## 15. Configure Workload Identity (Airflow)
Allows Airflow to use GKE service account for Google Cloud API access.

```bash
gcloud iam service-accounts add-iam-policy-binding \
  gke-service-account@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[airflow/airflow-service-account]"

kubectl annotate serviceaccount \
  airflow-service-account \
  --namespace airflow \
  iam.gke.io/gcp-service-account=gke-service-account@$PROJECT_ID.iam.gserviceaccount.com
```



## 16. Configure Persistent Volumes for DAGs and Logs
Sets up persistent volumes using GCS Fuse for Airflow DAGs and logs.

```bash
kubectl apply -f infra/kubernetes/airflow/pv-gcs-fuse-dags.yaml
kubectl apply -f infra/kubernetes/airflow/pvc-gcs-fuse-dags.yaml
kubectl apply -f infra/kubernetes/airflow/pv-gcs-fuse-logs.yaml
kubectl apply -f infra/kubernetes/airflow/pvc-gcs-fuse-logs.yaml
```



## 17. Install Airflow via Helm

```bash
helm repo add apache-airflow https://airflow.apache.org/ --force-update

helm upgrade --install airflow apache-airflow/airflow \
  --version 1.16.0 \
  -f infra/kubernetes/airflow/airflow_helm.yaml \
  --namespace airflow \
  --set config.smtp.smtp_password="$SMTP_PASSWORD"
```


## 18. Add Airflow Kubernetes Connection
Adds a Kubernetes in-cluster connection for Airflow.

```bash
kubectl exec -it $(kubectl get pod -n airflow -l "component=webserver" -o jsonpath="{.items[0].metadata.name}") -n airflow -- \
    airflow connections add in_cluster_configuration_kubernetes_cluster \
    --conn-type kubernetes \
    --conn-extra '{"in_cluster": true}'
```

## 19. Set Up Spark Operator
Deploys Spark Operator for running Spark jobs.
```bash
kubectl create namespace spark
kubectl apply -f infra/kubernetes/spark-operator/rbac.yaml
helm repo add spark-operator https://kubeflow.github.io/spark-operator --force-update
helm upgrade --install spark-operator spark-operator/spark-operator \
  --wait \
  -f infra/kubernetes/spark-operator/values_helm.yaml \
  --namespace spark
```


## 20. Configure Workload Identity (Spark)
Allows Spark jobs to use GKE service account for Google Cloud API access.

```bash
gcloud iam service-accounts add-iam-policy-binding \
  gke-service-account@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[spark/spark-service-account]"

kubectl annotate serviceaccount \
  spark-service-account \
  --namespace spark \
  iam.gke.io/gcp-service-account=gke-service-account@$PROJECT_ID.iam.gserviceaccount.com
```



## 21. Access Airflow Web UI
Makes the Airflow UI available at `http://localhost:8080`.


```bash
kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow
```

#!/bin/bash

# To run this script, ensure you already have a project id and owner account or a account with permissions.
# Ajust the .env file to set the PROJECT_ID and TF_VAR_project_id.

# Export environment variables from .env file (ignoring comments)
export $(grep -v '^#' infra/.env | xargs)

# Install gcloud CLI using Homebrew
brew install --cask google-cloud-sdk

# Initialize gcloud CLI
gcloud init
# Authenticate with Google Cloud (owner of billing account)
gcloud auth login
# List authenticated accounts
gcloud auth list 
# Install GKE auth plugin for gcloud
gcloud components install gke-gcloud-auth-plugin
# Update gcloud components
gcloud components update

# Add HashiCorp tap for Terraform
brew tap hashicorp/tap
# Install Terraform
brew install hashicorp/tap/terraform
# Install kubectl (Kubernetes CLI)
brew install kubectl
# Install kubectx (Kubernetes context switcher)
brew install kubectx
# Install Helm (Kubernetes package manager)
brew install helm

# List all GCP projects
gcloud projects list

# Initialize, plan and apply Terraform configuration in infra/terraform
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform plan
terraform -chdir=infra/terraform apply --auto-approve

# Create GCP service account key for GKE and copy to multiple locations
gcloud iam service-accounts keys create src/pipeline/bronze/gke-service-account.json --iam-account=gke-service-account@$PROJECT_ID.iam.gserviceaccount.com
cp src/pipeline/bronze/gke-service-account.json src/pipeline/silver/gke-service-account.json
cp src/pipeline/bronze/gke-service-account.json src/pipeline/gold/gke-service-account.json
cp src/pipeline/bronze/gke-service-account.json src/tests/gke-service-account.json

# Configure Docker to authenticate with Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build and push Docker images for bronze, silver, gold and tests to Artifact Registry
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

# Copy Airflow DAGs to GCS bucket
gsutil cp src/dags/*.py gs://bees-airflow-dags/
# (Optional) Delete Airflow webserver pod to force restart
# kubectl delete pod -l component=webserver -n airflow

# Set gcloud project context
gcloud config set project $PROJECT_ID
# Get GKE cluster credentials for kubectl
gcloud container clusters get-credentials airflow-cluster --zone us-central1-c --project $PROJECT_ID

# Create Kubernetes namespace for Airflow
kubectl create namespace airflow

# Create Kubernetes secret with GKE service account key in Airflow namespace
kubectl create secret generic gke-service-account-secret \
  --from-file=key.json=src/pipeline/silver/gke-service-account.json \
  -n airflow
# Apply Airflow RBAC configuration
kubectl apply -f infra/kubernetes/airflow/rbac.yaml

# Grant storage.objectAdmin role on logs bucket to GKE service account
gcloud storage buckets add-iam-policy-binding gs://bees-airflow-logs \
  --member="serviceAccount:gke-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Grant storage.objectAdmin role on DAGs bucket to GKE service account
gcloud storage buckets add-iam-policy-binding gs://bees-airflow-dags \
  --member="serviceAccount:gke-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Allow Kubernetes service account (KSA) to impersonate GCP service account (GSA)
gcloud iam service-accounts add-iam-policy-binding \
  gke-service-account@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[airflow/airflow-service-account]"

# Annotate KSA with GSA email for Workload Identity
kubectl annotate serviceaccount \
  airflow-service-account \
  --namespace airflow \
  iam.gke.io/gcp-service-account=gke-service-account@$PROJECT_ID.iam.gserviceaccount.com

# Apply PersistentVolume and PersistentVolumeClaim for DAGs (GCS Fuse)
kubectl apply -f infra/kubernetes/airflow/pv-gcs-fuse-dags.yaml
kubectl apply -f infra/kubernetes/airflow/pvc-gcs-fuse-dags.yaml

# Apply PersistentVolume and PersistentVolumeClaim for logs (GCS Fuse)
kubectl apply -f infra/kubernetes/airflow/pv-gcs-fuse-logs.yaml
kubectl apply -f infra/kubernetes/airflow/pvc-gcs-fuse-logs.yaml

# Add Airflow Helm repository (force update)
helm repo add apache-airflow https://airflow.apache.org/ --force-update

# Install or upgrade Airflow via Helm with custom values and SMTP password
helm upgrade --install airflow apache-airflow/airflow \
  --version 1.16.0 \
  -f infra/kubernetes/airflow/airflow_helm.yaml \
  --namespace airflow \
  --set config.smtp.smtp_password="$SMTP_PASSWORD"

# Add Airflow Kubernetes connection inside the webserver pod
kubectl exec -it $(kubectl get pod -n airflow -l "component=webserver" -o jsonpath="{.items[0].metadata.name}") -n airflow -- \
    airflow connections add in_cluster_configuration_kubernetes_cluster \
    --conn-type kubernetes \
    --conn-extra '{"in_cluster": true}'

# Create Kubernetes namespace for Spark
kubectl create namespace spark
# Apply Spark Operator RBAC configuration
kubectl apply -f infra/kubernetes/spark-operator/rbac.yaml

# Add Spark Operator Helm repository (force update)
helm repo add spark-operator https://kubeflow.github.io/spark-operator --force-update

# Install or upgrade Spark Operator via Helm with custom values (wait for completion)
helm upgrade --install spark-operator spark-operator/spark-operator \
  --wait \
  -f infra/kubernetes/spark-operator/values_helm.yaml \
  --namespace spark

# Allow Spark KSA to impersonate GKE GSA
gcloud iam service-accounts add-iam-policy-binding \
  gke-service-account@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[spark/spark-service-account]"

# Annotate Spark KSA with GSA email for Workload Identity
kubectl annotate serviceaccount \
  spark-service-account \
  --namespace spark \
  iam.gke.io/gcp-service-account=gke-service-account@$PROJECT_ID.iam.gserviceaccount.com

# Port-forward Airflow webserver service to localhost:8080
kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow
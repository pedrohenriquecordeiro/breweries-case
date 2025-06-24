#!/bin/bash

set -euo pipefail

# ------------------------------------------------------------------------
# Load environment variables from .env file
# ------------------------------------------------------------------------
set -a
source infra/.env
set +a

# ------------------------------------------------------------------------
# Install required packages (Google Cloud SDK, Terraform, kubectl, Helm)
# ------------------------------------------------------------------------

echo "[INFO] Installing required tools..."

# Install dependencies
sudo apt-get update && sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  unzip \
  software-properties-common

# Install Google Cloud SDK
if ! command -v gcloud &> /dev/null; then
  echo "[INFO] Installing Google Cloud SDK..."
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
  sudo apt-get update && sudo apt-get install -y google-cloud-sdk
fi

# Install Terraform
if ! command -v terraform &> /dev/null; then
  echo "[INFO] Installing Terraform..."
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install -y terraform
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
  echo "[INFO] Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/
fi

# Install helm
if ! command -v helm &> /dev/null; then
  echo "[INFO] Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# ------------------------------------------------------------------------
# Initialize Google Cloud project and billing
# ------------------------------------------------------------------------

echo "[INFO] Setting up GCP project..."

gcloud auth activate-service-account --key-file=".secrets/$GCP_AUTH_FILE"
gcloud config set project "$PROJECT_ID"

gcloud projects create "$PROJECT_ID" --name="Bees Project" --set-as-default || echo "[WARN] Project may already exist"
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"

gcloud components install gke-gcloud-auth-plugin --quiet
gcloud components update --quiet

# ------------------------------------------------------------------------
# Terraform infrastructure provisioning
# ------------------------------------------------------------------------

echo "[INFO] Running Terraform..."

terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform apply --auto-approve

# ------------------------------------------------------------------------
# Create service account key and copy to all pipelines
# ------------------------------------------------------------------------

echo "[INFO] Creating service account key..."

gcloud iam service-accounts keys create src/pipeline/bronze/gke-service-account.json \
  --iam-account="gke-service-account@$PROJECT_ID.iam.gserviceaccount.com"

for env in silver gold tests; do
  cp src/pipeline/bronze/gke-service-account.json src/pipeline/$env/gke-service-account.json
done

# ------------------------------------------------------------------------
# Docker image builds
# ------------------------------------------------------------------------

echo "[INFO] Building Docker images..."

gcloud auth configure-docker us-central1-docker.pkg.dev

docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/$PROJECT_ID/bees-docker-repo/bronze/bees-etl-bronze-job:latest \
  --push src/pipeline/bronze/

docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/$PROJECT_ID/bees-docker-repo/silver/bees-etl-silver-job:latest \
  --push src/pipeline/silver/

docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/$PROJECT_ID/bees-docker-repo/gold/bees-etl-gold-job:latest \
  --push src/pipeline/gold/

docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/$PROJECT_ID/bees-docker-repo/tests/bees-test-data-quality:latest \
  --push src/tests/

# ------------------------------------------------------------------------
# Upload DAGs
# ------------------------------------------------------------------------

echo "[INFO] Uploading DAGs..."
gsutil cp src/dags/*.py gs://bees-airflow-dags/

# ------------------------------------------------------------------------
# Kubernetes & Airflow Setup
# ------------------------------------------------------------------------

echo "[INFO] Configuring Kubernetes..."

gcloud container clusters get-credentials airflow-cluster --zone us-central1-c --project "$PROJECT_ID"

kubectl create namespace airflow || true

kubectl create secret generic gke-service-account-secret \
  --from-file=key.json=src/pipeline/silver/gke-service-account.json \
  -n airflow

kubectl apply -f infra/kubernetes/airflow/rbac.yaml

# GCS bucket permissions
for bucket in bees-airflow-logs bees-airflow-dags; do
  gcloud storage buckets add-iam-policy-binding gs://$bucket \
    --member="serviceAccount:gke-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"
done

# Workload Identity setup for Airflow
gcloud iam service-accounts add-iam-policy-binding \
  gke-service-account@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[airflow/airflow-service-account]"

kubectl annotate serviceaccount airflow-service-account \
  --namespace airflow \
  iam.gke.io/gcp-service-account=gke-service-account@$PROJECT_ID.iam.gserviceaccount.com

kubectl apply -f infra/kubernetes/airflow/pv-gcs-fuse-dags.yaml
kubectl apply -f infra/kubernetes/airflow/pvc-gcs-fuse-dags.yaml

kubectl apply -f infra/kubernetes/airflow/pv-gcs-fuse-logs.yaml
kubectl apply -f infra/kubernetes/airflow/pvc-gcs-fuse-logs.yaml

helm repo add apache-airflow https://airflow.apache.org/ --force-update

helm upgrade --install airflow apache-airflow/airflow \
  --version 1.16.0 \
  -f infra/kubernetes/airflow/airflow_helm.yaml \
  --namespace airflow \
  --set config.smtp.smtp_password="$SMTP_PASSWORD"

# Wait for Airflow webserver to be ready
kubectl wait --for=condition=ready pod -l component=webserver -n airflow --timeout=300s

kubectl exec -it "$(kubectl get pod -n airflow -l 'component=webserver' -o jsonpath='{.items[0].metadata.name}')" -n airflow -- \
  airflow connections add in_cluster_configuration_kubernetes_cluster \
  --conn-type kubernetes \
  --conn-extra '{"in_cluster": true}'

# ------------------------------------------------------------------------
# Spark Operator setup
# ------------------------------------------------------------------------

echo "[INFO] Deploying Spark Operator..."

kubectl create namespace spark || true
kubectl apply -f infra/kubernetes/spark-operator/rbac.yaml

helm repo add spark-operator https://kubeflow.github.io/spark-operator --force-update

helm upgrade --install spark-operator spark-operator/spark-operator \
  --wait \
  -f infra/kubernetes/spark-operator/values_helm.yaml \
  --namespace spark

gcloud iam service-accounts add-iam-policy-binding \
  gke-service-account@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:$PROJECT_ID.svc.id.goog[spark/spark-service-account]"

kubectl annotate serviceaccount spark-service-account \
  --namespace spark \
  iam.gke.io/gcp-service-account=gke-service-account@$PROJECT_ID.iam.gserviceaccount.com

# ------------------------------------------------------------------------
# Optional: Port-forward Airflow webserver (interactive use only)
# ------------------------------------------------------------------------
# echo "[INFO] Forwarding Airflow UI to localhost:8080..."
# kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow
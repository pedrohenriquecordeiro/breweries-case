from datetime import timedelta
import pendulum
from airflow.decorators import dag
from kubernetes.client import models as k8s
from airflow.operators.dummy_operator import DummyOperator
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator


PROJECT_ID = "bees-463419"  # Replace with your GCP project ID

# Default arguments for the DAG
DEFAULT_ARGS = {
  "owner"            : "Pedro Jesus",
  "start_date"       : pendulum.datetime(2025, 6, 17, tz = pendulum.timezone("America/Sao_Paulo")),
  "email"            : ["pedrohcordeiroj@gmail.com"],
  "email_on_failure" : True,
  "email_on_retry"   : True,
  "max_active_runs"  : 1,
  "retries"          : 3,
  "retry_delay"      : timedelta(minutes = 1)
}

# SparkApplication manifest template for SparkKubernetesOperator
SPARK_APPLICATION_MANIFEST = '''
  apiVersion: sparkoperator.k8s.io/v1beta2
  kind: SparkApplication
  metadata:
  name: spark-job                            # Name of the Spark application
  namespace: spark                           # Kubernetes namespace
  spec:
  type: Python                               # Type of Spark job
  pythonVersion: "3"
  sparkVersion: "3.5.3"                      # Spark version to use
  mode: cluster                              # Run in cluster mode
  image: {IMAGE_SPARK}                       # Docker image with your Spark job
  imagePullSecrets:
    - gke-service-account-secret
  imagePullPolicy: Always                    # Always pull image (only for development)
  mainApplicationFile: local:///app/main.py  # Entry point for your Spark app
  driver:
    serviceAccount: spark-service-account
    coreRequest: 500m                        # CPU request for the driver
    coreLimit: 2000m                         # CPU limit for the driver
    memory: 3906m                            # aprox 4GB
    labels:
    app: spark-driver
  executor:
    serviceAccount: spark-service-account
    coreRequest: 500m
    coreLimit: 2000m
    memory: 3906m                            # aprox 4GB
    labels:
    app: spark-executor
  dynamicAllocation:
    enabled: true
    initialExecutors: 3
    minExecutors: 1
    maxExecutors: 6
'''

@dag(
  dag_id            = "data-pipeline-breweries",
  default_args      = DEFAULT_ARGS,
  schedule_interval = "@once",
  catchup           = False,
  tags              = ["bees"],
)
def pipeline_dag():
  # Dummy start task
  start = DummyOperator(task_id="start")

  # Bronze layer: Run ETL job in a Kubernetes Pod
  bronze_task = KubernetesPodOperator(
    task_id                = "bronze_task",
    namespace              = "airflow",
    image                  = f"us-central1-docker.pkg.dev/{PROJECT_ID}/bees-docker-repo/bronze/bees-etl-bronze-job:latest",
    image_pull_secrets     = [k8s.V1LocalObjectReference("gke-service-account-secret")],
    image_pull_policy      = "Always", # only for development
    get_logs               = True,
    in_cluster             = True,
    service_account_name   = "airflow-service-account",
    container_resources    = k8s.V1ResourceRequirements(
      limits   = {"memory": "1000M", "cpu": "500m"},
    )
  )

  # Silver layer: Run Spark job using SparkKubernetesOperator
  silver_task = SparkKubernetesOperator(
    task_id                 = "silver_task",
    namespace               = "spark",
    get_logs                = True,
    startup_timeout_seconds = 600,
    delete_on_termination   = True,
    application_file        = SPARK_APPLICATION_MANIFEST.replace("{IMAGE_SPARK}", f"us-central1-docker.pkg.dev/{PROJECT_ID}/bees-docker-repo/silver/bees-etl-silver-job:latest"),
    kubernetes_conn_id      = "in_cluster_configuration_kubernetes_cluster"
  )
  
  # Data quality test: Run Spark job for data quality checks
  test_data_quality_test = SparkKubernetesOperator(
    task_id                 = "test_data_quality_test",
    namespace               = "spark",
    get_logs                = True,
    startup_timeout_seconds = 600,
    delete_on_termination   = True,
    application_file        = SPARK_APPLICATION_MANIFEST.replace("{IMAGE_SPARK}", f"us-central1-docker.pkg.dev/{PROJECT_ID}/bees-docker-repo/tests/bees-test-data-quality:latest"),
    kubernetes_conn_id      = "in_cluster_configuration_kubernetes_cluster"
  )
  
  # Gold layer: Run Spark job for gold layer ETL
  gold_task = SparkKubernetesOperator(
    task_id                 = "gold_task",
    namespace               = "spark",
    get_logs                = True,
    startup_timeout_seconds = 600,
    delete_on_termination   = True,
    application_file        = SPARK_APPLICATION_MANIFEST.replace("{IMAGE_SPARK}", f"us-central1-docker.pkg.dev/{PROJECT_ID}/bees-docker-repo/gold/bees-etl-gold-job:latest"),
    kubernetes_conn_id      = "in_cluster_configuration_kubernetes_cluster"
  )

  # Define task dependencies
  start >> bronze_task >> silver_task >> [ gold_task , test_data_quality_test ]

pipeline_dag()
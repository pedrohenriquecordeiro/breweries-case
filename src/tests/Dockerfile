# Apache Spark 3.5.5, compilado com Scala 2.12.18 e rodando no OpenJDK 17.0.14.
FROM bitnami/spark:3.5.5

USER root

RUN apt-get update && \
    apt-get install -y wget && \
    apt-get install -y tree && \
    pip install --no-cache-dir py4j==0.10.9.7 google-cloud-storage==3.1.0 delta-spark==3.3.0 pydeequ==1.5.0 pandas==2.1.3 numpy==1.26.4

# JARs obrigatórios
RUN wget -P /opt/bitnami/spark/jars/ https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-latest.jar
RUN wget -P /opt/bitnami/spark/jars/ https://search.maven.org/remotecontent?filepath=org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.8.1/iceberg-spark-runtime-3.5_2.12-1.8.1.jar
RUN wget -P /opt/bitnami/spark/jars/ https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.1.0/delta-spark_2.12-3.1.0.jar
RUN wget -P /opt/bitnami/spark/jars/ https://repo1.maven.org/maven2/io/delta/delta-storage/3.1.0/delta-storage-3.1.0.jar
RUN wget -P /opt/bitnami/spark/jars/ https://repo1.maven.org/maven2/com/amazon/deequ/deequ/2.0.11-spark-3.5/deequ-2.0.11-spark-3.5.jar

ENV SPARK_HOME=/opt/bitnami/spark
ENV SPARK_VERSION=3.5.5
ENV PATH=$SPARK_HOME/bin:$PATH
ENV PYTHONPATH="${PYTHONPATH}:/app"

WORKDIR /app

COPY main.py .

RUN mkdir -m 700 /app/.secrets
COPY gke-service-account.json /app/.secrets/gke-service-account.json

#RUN pip freeze
#RUN ls /opt/bitnami/spark/jars/
RUN tree .

CMD ["python3", "main.py"]

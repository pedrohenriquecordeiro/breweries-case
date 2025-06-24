FROM python:3.12-slim

USER root
WORKDIR /app

RUN pip install --no-cache-dir google-cloud-storage==2.8.0

COPY main.py .
COPY functions.py .

RUN mkdir -m 700 .secrets
COPY gke-service-account.json .secrets/

CMD ["python", "main.py"] 
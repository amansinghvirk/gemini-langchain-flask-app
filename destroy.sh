#!/bin/bash

# Script to deploy a Flask application to Google Cloud Run, leveraging Vertex AI and Secret Manager.

# --- Environment Variables ---
# Set environment variables for the project, region, service accounts, and application specifics.
export PROJECT_ID=<your-gcp-project-id>                  # Google Cloud Project ID.
export REGION="us-central1"                         # Google Cloud Region to deploy resources in.
export SVC_ACCOUNT=<sevice-account-name>      # Service account name for the application.
export REPO="gemini-flask-app-repo"                 # Artifact Registry repository name for docker images.
export SECRET_ID="GEMINI_FLASK_APP"                 # Secret Manager secret ID to store service account credentials.
export APP_NAME="gemini-flask-app"                  # Name of the Cloud Run application.

# --- Google Cloud Configuration ---
# Set the current Google Cloud project.
gcloud config set project $PROJECT_ID

# Delete the service account
export SVC_ACCOUNT_EMAIL=$SVC_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $SVC_ACCOUNT_EMAIL  --quiet

# Delete the artifacts registry
gcloud artifacts repositories delete $REPO \
    --location=$REGION \
     --quiet

# Delete secret manager to store credentials
gcloud secrets delete $SECRET_ID --quiet

# Delete deployed Cloud Run App
gcloud run services delete $APP_NAME --region=$REGION --quiet
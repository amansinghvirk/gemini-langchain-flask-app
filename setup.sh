
#!/bin/bash

# Script to deploy a Flask application to Google Cloud Run, leveraging Vertex AI and Secret Manager.

# --- Environment Variables ---
# Set environment variables for the project, region, service accounts, and application specifics.
export PROJECT_ID=<your-gcp-project-id>                # Google Cloud Project ID.
export REGION="us-central1"                         # Google Cloud Region to deploy resources in.
export SVC_ACCOUNT="gemini-langchain-flask-app"     # Service account name for the application.
export REPO=<sevice-account-name>                # Artifact Registry repository name for docker images.
export SECRET_ID="GEMINI_FLASK_APP"                 # Secret Manager secret ID to store service account credentials.
export APP_NAME="gemini-flask-app"                  # Name of the Cloud Run application.
export APP_VERSION="0.1"                            # Version of the application being deployed.
export CREDENTIALS_FILE="gemini-credentials.json"   # Name of the credentials file within the container.
export LANGUAGE_MODEL="gemini-2.0-flash-exp"        # Language model to be used in the application
export VISION_MODEL="imagegeneration@006"           # Vision model to be used in the application

# Get the project number.
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")

# --- Google Cloud Configuration ---
# Set the current Google Cloud project.
gcloud config set project $PROJECT_ID

# --- Service Account Setup ---
# Create a service account to be used for Vertex AI authorization.
gcloud iam service-accounts create $SVC_ACCOUNT

# Export the service account email for later use.
export SVC_ACCOUNT_EMAIL=$SVC_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
echo $SVC_ACCOUNT_EMAIL

# Create and save the service account's JSON credentials key to a local path.
# IMPORTANT: Ensure the path `<local-path-to-save-json-file>` is accessible and secure
gcloud iam service-accounts keys create '<local-path-to-save-json-file>' \
  --iam-account=$SVC_ACCOUNT_EMAIL

# Grant the service account the `aiplatform.user` role to access Vertex AI resources
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SVC_ACCOUNT_EMAIL" \
  --role="roles/aiplatform.user"

# --- Artifact Registry Setup ---
# Create an Artifact Registry repository to store the Docker image.
gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION

# Configure Docker authentication for the Artifact Registry.
gcloud auth configure-docker $REGION-docker.pkg.dev

# --- Build and Push Docker Image ---
# Build the Docker image and push it to the Artifact Registry.
gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$APP_NAME:v$APP_VERSION .

# --- Secret Manager Setup ---
# Create a Secret Manager secret to store the service account credentials.
gcloud secrets create $SECRET_ID --replication-policy="automatic"

# Add the service account's JSON credentials to the Secret Manager.
# The `-` indicates reading the data from the standard input, which is piped from the cat command
cat '<local-path-to-save-json-file>' | gcloud secrets versions add $SECRET_ID --data-file=-

# Grant the service account the `secretmanager.secretAccessor` role to access the secret.
gcloud secrets add-iam-policy-binding $SECRET_ID \
    --member serviceAccount:$SVC_ACCOUNT_EMAIL \
    --role='roles/secretmanager.secretAccessor'

# --- Cloud Run Deployment ---
# Deploy the application to Cloud Run.
gcloud run deploy $APP_NAME \
	--image $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$APP_NAME:v$APP_VERSION \
	--service-account $SVC_ACCOUNT_EMAIL \
	--region=$REGION     \
	--allow-unauthenticated \
	--set-env-vars LANGUAGE_MODEL=$LANGUAGE_MODEL,VISION_MODEL=$VISION_MODEL,CREDENTIALS_FILE=$CREDENTIALS_FILE \
	--set-secrets=/secrets/$CREDENTIALS_FILE=projects/$PROJECT_NUMBER/secrets/$SECRET_ID:1

echo "Deployment complete for $APP_NAME version $APP_VERSION"
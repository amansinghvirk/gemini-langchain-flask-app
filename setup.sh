export PROJECT_ID=prj-smart-news
export REGION=us-central1
export SVC_ACCOUNT=gemini-langchain-flask-app
export REPO=gemini-flask-app-repo
export SECRET_ID=GEMINI_FLASK_APP
export APP_NAME=gemini-flask-app
export APP_VERSION=0.1
export CREDENTIALS_FILE=gemini-credentials.json
export LANGUAGE_MODEL=gemini-2.0-flash-exp
export VISION_MODEL=imagegeneration@006

export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")

# Set the current project
gcloud config set project $PROJECT_ID

gcloud iam service-accounts create $SVC_ACCOUNT
export SVC_ACCOUNT_EMAIL=$SVC_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
echo $SVC_ACCOUNT_EMAIL

gcloud iam service-accounts keys create <key-file-path> \
  --iam-account=$SVC_ACCOUNT_EMAIL

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SVC_ACCOUNT_EMAIL" \
  --role="roles/aiplatform.user"

gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION

gcloud auth configure-docker $REGION-docker.pkg.dev

gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$APP_NAME:v$APP_VERSION .

gcloud secrets create $SECRET_ID --replication-policy="automatic"

cat <key-file-path> | gcloud secrets versions add $SECRET_ID --data-file=-

gcloud secrets add-iam-policy-binding $SECRET_ID \
    --member serviceAccount:$SVC_ACCOUNT_EMAIL \
    --role='roles/secretmanager.secretAccessor'

gcloud run deploy gemini-flask-app \
	--image $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$APP_NAME:v$APP_VERSION \
	--service-account $SVC_ACCOUNT_EMAIL \
	--region=$REGION     \
	--allow-unauthenticated \
	--set-env-vars LANGUAGE_MODEL=$LANGUAGE_MODEL,VISION_MODEL=$VISION_MODEL,CREDENTIALS_FILE=$CREDENTIALS_FILE \
	--set-secrets=/secrets/$CREDENTIALS_FILE=projects/$PROJECT_NUMBER/secrets/$SECRET_ID:1
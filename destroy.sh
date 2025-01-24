export PROJECT_ID=prj-smart-news
export REGION=us-central1
export SVC_ACCOUNT=gemini-langchain-flask-app
export REPO=gemini-flask-app-repo
export SECRET_ID=GEMINI_FLASK_APP
export APP_NAME=gemini-flaks-app

# Set the current project
gcloud config set project $PROJECT_ID

export SVC_ACCOUNT_EMAIL=$SVC_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $SVC_ACCOUNT_EMAIL  --quiet


gcloud artifacts repositories delete $REPO \
    --location=$REGION \
     --quiet

gcloud secrets delete $SECRET_ID --quiet

gcloud run services delete $APP_NAME --region=$REGION --quiet
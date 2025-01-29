# Gemini-Langchain Flask App

This application demonstrates the use of Google's Gemini language and vision models to generate a random joke and an image based on it. It utilizes Flask for the web framework, Langchain for enhanced language model interaction, and Google Cloud services for deployment.

For a detailed walkthrough and deeper understanding of the project, please refer to the following articles on Medium:

[Deploy a flask app with Langchain and Google Cloud Run](https://medium.com/@aman.virk.ds/gemini-jests-deploy-a-flask-app-with-langchain-and-google-cloud-run-24fa07c640f7)

## App Description

The application does the following:

1.  **Random Joke Topic:** Uses the Gemini language model to generate a random topic (e.g., "cats," "coding").
2.  **Joke Generation:** Uses Langchain in conjunction with Gemini to create a joke based on the chosen topic. The response is parsed to extract the joke text as JSON response.
3.  **Image Generation:** Generates an image based on the joke text using Google's Vision model.
4.  **Display:** Renders all this on a simple HTML page.

## Architecture

The project structure is as follows:

```
gemini-langchain-flask-app/
├── src/
│   ├── gemini.py    #  Logic for interacting with Gemini Language and Vision Models  
├── static/
│   └── images/      # location to store image generated using vision model
├── templates/
│   └── home.html    # HTML template for the web page
├── main.py          # Flask Application logic
├── .env             # Environment variables (local setup)
├── Dockerfile       # Docker configuration file
├── requirements.txt # Project dependencies
└── setup.sh         # Script for Cloud Run deployment
└── destroy.sh        # Script to delete the resources
```

## Setup

### Prerequisites

*   **Google Cloud Project:**  You need a Google Cloud project with the necessary APIs enabled (e.g., Vertex AI API, Secret Manager API, Artifact Registry API, Cloud Run API).
*   **gcloud CLI:** Install and configure the Google Cloud SDK.
*   **Docker:** Install Docker to build and run the container.
*   **Python:** Ensure Python 3.12 is installed.
*   **venv or virtual environment:** recommended to manage dependencies locally

### Local Setup

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/amansinghvirk/gemini-langchain-flask-app.git
    cd gemini-langchain-flask-app
    ```

2.  **Create a virtual environment**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Environment Variables:**
    *   Create a `.env` file in the root directory with the following variables. Replace placeholders with your Google Cloud Project details and desired model names:
        ```
        PROJECT_ID=<your-gcp-project-id>
        REGION=us-central1
        GOOGLE_APPLICATION_CREDENTIALS=<path-to-your-service-account-json-file>  # Local path to service account credentials json file. Required to use google models
        SVC_ACCOUNT=<sevice-account-name>
        LANGUAGE_MODEL=gemini-2.0-flash-exp
        VISION_MODEL=imagegeneration@006
        ```
        *Note: GOOGLE_APPLICATION_CREDENTIALS is used when run locally. When deployed to Cloud Run, application default credentials is set for authentication. In cloud run the service account json is stored in secret manager and loaded.*
        *To get the GOOGLE_APPLICATION_CREDENTIALS, you can create a service account and download the key json file. Follow the steps mentioned in Cloud Run Deployment under Step 1 (Service Account Setup)*.

4.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
    
5.  **Run the Application:**
    ```bash
    python main.py
    ```

    The application will now be running at `http://0.0.0.0:5000/`

### Cloud Run Deployment

The `setup.sh` script automates the deployment process to Google Cloud Run.  Follow the below steps to setup and deploy.

1.  **Service Account Setup**
    *   Modify the `setup.sh` script as per your Project ID, Region, and other configurations in the **Environment Variables** section.
    *   **Important:** In the script, replace  `'<local-path-to-save-json-file>'`  with the path on your local system where the service account's JSON credentials key will be saved. This will be used for uploading the key to Google secret manager. Make sure the path is accessible and secure.
    *   Run the `setup.sh` script. This creates a service account, generate keys, saves locally, sets necessary policies and grants permissions for Vertex AI, Artifact Registry and Cloud Run for the service account.
        ```bash
        chmod +x setup.sh
        ./setup.sh
        ```
2.  **Build and Deploy**
    *   The `setup.sh` script performs the following actions:
        *   Creates a Google Cloud service account for the application and assigns roles
        *   Creates an Artifact Registry to store the docker image
        *   Builds a docker image using dockerfile and pushes it to Artifact Registry
        *   Creates a Secret Manager secret to store service account credentials, grants the service account access.
        *   Deploys the application to Google Cloud Run, configuring the secrets and environment variables.

3.  **Access the Application**
    *   Once deployed, the script will provide the service URL of your Cloud Run app. You can access it via a web browser.

## Troubleshooting

*   **Authentication Issues:** If you encounter authentication errors, make sure the service account has the necessary permissions and that the `GOOGLE_APPLICATION_CREDENTIALS` environment variable is correctly set in the local setup or you have set application default credentials in case of deployment.
*   **Model Errors:** Ensure that the models specified in the environment variables are valid and available for your project. Check GCP console for any errors.
*   **Image Generation Issues:** If images do not load, ensure the directory `/static/images` is created in root directory and that your application has permissions to save the image.
*   **Cloud Run Deployment:** If deployment fails, review the logs in the GCP Console or check the output of the `setup.sh` script 

## Important

*   Make sure the service account used has the `aiplatform.user` role to access Vertex AI and `secretmanager.secretAccessor` role to access the secret stored in secret manager.
*   The service account's JSON key is securely managed. The `setup.sh`  script stores the key in Secret Manager which will be accessed via the service account itself.
*   The docker image generated by setup.sh is stored in Artifact Registry. Make sure to delete images if no longer used to avoid cost.
*   Ensure that the necessary APIs are enabled in your Google Cloud project before running the script.
```

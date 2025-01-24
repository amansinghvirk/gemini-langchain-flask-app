import os
import logging
from flask import Flask, render_template
from src.gemini import get_joke_topic, get_joke, get_image_for_joke

app = Flask(__name__)

# set logging
logging.basicConfig(
    format="{asctime} - {levelname} - {message}",
    style="{",
    datefmt="%Y-%m-%d %H:%M",
    level=logging.DEBUG,
)

# check if app is running locally or on Google Cloud Run
# if running locally load the environment variables 
# else set Application Default Credentials for vertexai authentication
if 'K_REVISION' in os.environ:
    os.environ['GOOGLE_APPLICATION_CREDENTIALS']=f'/secrets/{os.getenv("CREDENTIALS_FILE")}'
    logging.info("Runnning app in Cloud Run")
else:
    from dotenv import load_dotenv
    load_dotenv()
    logging.info("Runnning app locally..")


@app.route("/")
def home():

    # get random joke topic using google Gemini model
    joke_topic = get_joke_topic()

    # get joke on the topic using langchain and Gemini
    joke = get_joke(joke_topic)["joke"]
    
    # get image based on joke as description using google Vision model
    img_path = get_image_for_joke(joke)

    return render_template(
        "home.html", 
        topic=joke_topic, 
        joke=joke, 
        img_path=img_path
    )

if __name__ == "__main__":
    
    app.run(debug=True, host='0.0.0.0')
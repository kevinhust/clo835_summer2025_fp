from flask import Flask, render_template, request
from pymysql import connections
import os
import random
import argparse
import boto3
import logging
from botocore.exceptions import NoCredentialsError, ClientError


app = Flask(__name__)

# Database configuration
DBHOST = os.environ.get("DBHOST") or "localhost"
DBUSER = os.environ.get("DBUSER") or "root"
DBPWD = os.environ.get("DBPWD") or "passwors"
DATABASE = os.environ.get("DATABASE") or "employees"
DBPORT = int(os.environ.get("DBPORT"))

# Application configuration
COLOR_FROM_ENV = os.environ.get('APP_COLOR') or "lime"
BACKGROUND_IMAGE_URL = os.environ.get('BACKGROUND_IMAGE_URL')
GROUP_NAME = os.environ.get('GROUP_NAME') or "Default Group"
GROUP_SLOGAN = os.environ.get('GROUP_SLOGAN') or "Default Slogan"

# AWS configuration
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.environ.get('AWS_REGION') or 'us-east-1'

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize S3 client
s3_client = None
if AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY:
    try:
        s3_client = boto3.client(
            's3',
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
            region_name=AWS_REGION
        )
        logger.info("S3 client initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize S3 client: {e}")
else:
    logger.warning("AWS credentials not provided, S3 functionality will be disabled")

# Log the background image URL
if BACKGROUND_IMAGE_URL:
    logger.info(f"Background image URL: {BACKGROUND_IMAGE_URL}")
else:
    logger.warning("Background image URL not provided")

# Create a connection to the MySQL database
db_conn = connections.Connection(
    host= DBHOST,
    port=DBPORT,
    user= DBUSER,
    password= DBPWD, 
    db= DATABASE
    
)
output = {}
table = 'employee';

# Define the supported color codes
color_codes = {
    "red": "#e74c3c",
    "green": "#16a085",
    "blue": "#89CFF0",
    "blue2": "#30336b",
    "pink": "#f4c2c2",
    "darkblue": "#130f40",
    "lime": "#C1FF9C",
}


# Create a string of supported colors
SUPPORTED_COLORS = ",".join(color_codes.keys())

# Generate a random color
COLOR = random.choice(["red", "green", "blue", "blue2", "darkblue", "pink", "lime"])

def download_background_image():
    """Download background image from S3 bucket and save locally"""
    if not s3_client or not BACKGROUND_IMAGE_URL:
        logger.warning("S3 client not available or background image URL not provided")
        return None
    
    try:
        # Parse S3 URL to extract bucket and key
        # Expecting format: s3://bucket-name/key or https://bucket-name.s3.region.amazonaws.com/key
        if BACKGROUND_IMAGE_URL.startswith('s3://'):
            url_parts = BACKGROUND_IMAGE_URL[5:].split('/', 1)
            bucket_name = url_parts[0]
            object_key = url_parts[1] if len(url_parts) > 1 else ''
        elif 's3.amazonaws.com' in BACKGROUND_IMAGE_URL or 's3.' in BACKGROUND_IMAGE_URL:
            # Handle https://bucket-name.s3.region.amazonaws.com/key format
            url_parts = BACKGROUND_IMAGE_URL.split('/')
            bucket_name = url_parts[2].split('.')[0]
            object_key = '/'.join(url_parts[3:])
        else:
            logger.error(f"Invalid S3 URL format: {BACKGROUND_IMAGE_URL}")
            return None
        
        # Create static directory if it doesn't exist
        os.makedirs('static', exist_ok=True)
        local_file_path = 'static/background.jpg'
        
        # Download file from S3
        s3_client.download_file(bucket_name, object_key, local_file_path)
        logger.info(f"Successfully downloaded background image from {BACKGROUND_IMAGE_URL} to {local_file_path}")
        return '/static/background.jpg'
        
    except NoCredentialsError:
        logger.error("AWS credentials not found")
        return None
    except ClientError as e:
        logger.error(f"Error downloading file from S3: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error downloading background image: {e}")
        return None

# Download background image on startup
background_image_path = download_background_image()


@app.route("/", methods=['GET', 'POST'])
def home():
    return render_template('addemp.html', 
                         color=color_codes[COLOR],
                         background_image=background_image_path,
                         group_name=GROUP_NAME,
                         group_slogan=GROUP_SLOGAN)

@app.route("/about", methods=['GET','POST'])
def about():
    return render_template('about.html', 
                         color=color_codes[COLOR],
                         background_image=background_image_path,
                         group_name=GROUP_NAME,
                         group_slogan=GROUP_SLOGAN)
    
@app.route("/addemp", methods=['POST'])
def AddEmp():
    emp_id = request.form['emp_id']
    first_name = request.form['first_name']
    last_name = request.form['last_name']
    primary_skill = request.form['primary_skill']
    location = request.form['location']

  
    insert_sql = "INSERT INTO employee VALUES (%s, %s, %s, %s, %s)"
    cursor = db_conn.cursor()

    try:
        
        cursor.execute(insert_sql,(emp_id, first_name, last_name, primary_skill, location))
        db_conn.commit()
        emp_name = "" + first_name + " " + last_name

    finally:
        cursor.close()

    print("all modification done...")
    return render_template('addempoutput.html', 
                         name=emp_name, 
                         color=color_codes[COLOR],
                         background_image=background_image_path,
                         group_name=GROUP_NAME,
                         group_slogan=GROUP_SLOGAN)

@app.route("/getemp", methods=['GET', 'POST'])
def GetEmp():
    return render_template("getemp.html", 
                         color=color_codes[COLOR],
                         background_image=background_image_path,
                         group_name=GROUP_NAME,
                         group_slogan=GROUP_SLOGAN)


@app.route("/fetchdata", methods=['GET','POST'])
def FetchData():
    emp_id = request.form['emp_id']

    output = {}
    select_sql = "SELECT emp_id, first_name, last_name, primary_skill, location from employee where emp_id=%s"
    cursor = db_conn.cursor()

    try:
        cursor.execute(select_sql,(emp_id))
        result = cursor.fetchone()
        
        # Add No Employee found form
        output["emp_id"] = result[0]
        output["first_name"] = result[1]
        output["last_name"] = result[2]
        output["primary_skills"] = result[3]
        output["location"] = result[4]
        
    except Exception as e:
        print(e)

    finally:
        cursor.close()

    return render_template("getempoutput.html", 
                         id=output["emp_id"], 
                         fname=output["first_name"],
                         lname=output["last_name"], 
                         interest=output["primary_skills"], 
                         location=output["location"], 
                         color=color_codes[COLOR],
                         background_image=background_image_path,
                         group_name=GROUP_NAME,
                         group_slogan=GROUP_SLOGAN)

if __name__ == '__main__':
    
    # Check for Command Line Parameters for color
    parser = argparse.ArgumentParser()
    parser.add_argument('--color', required=False)
    args = parser.parse_args()

    if args.color:
        print("Color from command line argument =" + args.color)
        COLOR = args.color
        if COLOR_FROM_ENV:
            print("A color was set through environment variable -" + COLOR_FROM_ENV + ". However, color from command line argument takes precendence.")
    elif COLOR_FROM_ENV:
        print("No Command line argument. Color from environment variable =" + COLOR_FROM_ENV)
        COLOR = COLOR_FROM_ENV
    else:
        print("No command line argument or environment variable. Picking a Random Color =" + COLOR)

    # Check if input color is a supported one
    if COLOR not in color_codes:
        print("Color not supported. Received '" + COLOR + "' expected one of " + SUPPORTED_COLORS)
        exit(1)

    app.run(host='0.0.0.0',port=81,debug=True)

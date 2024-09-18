#!/bin/bash

# Update the instance
sudo yum update -y  # For Amazon Linux 2
# sudo apt-get update -y && sudo apt-get upgrade -y  # For Ubuntu

# Install Python 3 and pip
sudo yum install python3 python3-pip -y  # For Amazon Linux 2
# sudo apt-get install python3 python3-pip -y  # For Ubuntu

# Upgrade pip and setuptools using sudo to ensure system-wide effect
sudo pip3 install --upgrade pip setuptools

# Create a Python virtual environment in our app directory
mkdir -p /opt/myflaskapp
cd /opt/myflaskapp
python3 -m venv venv
source venv/bin/activate

# Install Flask inside the virtual environment
pip install Flask

# Write the Flask app to a file
cat > app.py << EOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, PrivateLink World!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF


# Run the app with the virtual environment activated
FLASK_APP=app.py flask run --host=0.0.0.0 --port=8080
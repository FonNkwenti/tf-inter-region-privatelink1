#!/bin/bash

# Install necessary packages
yum update -y
yum install -y httpd curl

# Start the web server
systemctl start httpd
systemctl enable httpd

# Get instance metadata
INSTANCE_NAME=$(curl http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
# PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="No public IP assigned"
fi

# Create a simple HTML file to display the instance information
cat <<EOF > /var/www/html/index.html
<html>
<head>
    <title>Instance Information</title>
</head>
<body>
    <h1>Instance Information</h1>
    <p><strong>Instance Name:</strong> $INSTANCE_NAME</p>
    <p><strong>Private IP:</strong> $PRIVATE_IP</p>
    <p><strong>Public IP:</strong> $PUBLIC_IP</p>
    <p><strong>Availability Zone:</strong> $AVAILABILITY_ZONE</p>
    <p><strong>Region:</strong> $REGION</p>
</body>
</html>
EOF
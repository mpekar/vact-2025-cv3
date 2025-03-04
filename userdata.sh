#!/bin/bash

yum -y update
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum -y install httpd mariadb-server

systemctl enable httpd
systemctl start httpd

systemctl enable mariadb
systemctl start mariadb

echo '<html><h1>Hello From Your Web Server!</h1></html>' > /var/www/html/index.html
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php

usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www

#Check /var/log/cloud-init-output.log after this runs to see errors, if any.

#
# Download and unzip the Mom & Pop Cafe application files.
#

# Database scripts
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/ILT-TF-200-ACSOPS-1/activity-3/momPopDb.tar.gz
tar -zxvf momPopDb.tar.gz

# Web application files
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/ILT-TF-200-ACSOPS-1/activity-3/mompopcafe.tar.gz
tar -zxvf mompopcafe.tar.gz -C /var/www/html/

#
# Run the scripts to set the database root password, and create and populate the application database.
# Check the following logs to make sure there are no errors:
#
#       /momPopDb/set-root-password.log
#       /momPopDb/create-db.log
#
cd momPopDb
./set-root-password.sh
./create-db.sh
hostnamectl set-hostname web-server

#
# Custom modifications for course IIKS
#

# Enable serverInfo.php page and fix missing info
find /var/www/html/mompopcafe/ -type f -name "*.php" -exec sed 's/\/\/include(/include(/' -i {} \;
sed 's/showServerInfo = \"false\"/showServerInfo = \"true\"/' -i /var/www/html/mompopcafe/getAppParameters.php
sed 's/public-ipv4/local-ipv4/' -i /var/www/html/mompopcafe/serverInfo.php
sed "9i\\\t\$az = file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');" -i /var/www/html/mompopcafe/serverInfo.php

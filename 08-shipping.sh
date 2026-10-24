#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="mvvsnm.online"
scripts_dir=$(dirname $(realpath $0))
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "Please run this script with sudo access.."
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date "+%F %T" 
}

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] ==== Script started Execution =====" | tee -a $logs_file

# Enable the Maven module and install Maven and Java Development Kit (JDK) packages.
dnf module enable maven:3.9 -y &>> $logs_file
dnf install maven java-25-openjdk-devel -y &>> $logs_file
validate $? "Installing Maven and Java"

# Set Java 25 as the default version using the alternatives command.
alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java" &>> $logs_file
validate $? "Setting Java 25 as the default version"

# set the JAVA_HOME environment variable to Maven should know which Java version to use. 
# This is done by creating a new file in the /etc/profile.d/ directory and adding the JAVA_HOME variable to it. 
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
validate $? "Setting JAVA_HOME environment variable for Maven"

# Verify if the roboshop user already exist or not. If not then create the user.
id roboshop &>> $logs_file
if [ $? == 0 ]; then
    echo -e "$(timestamp) [INFO] Roboshop user already exists...${Y}SKIPPING${N}"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
    validate $? "Creating Roboshop system user" 
fi

# Remove the existing code from the /app directory to ensure a clean installation of the catalogue application.
rm -rf /app/* &>> $logs_file
validate $? "Removing old code from /app directory"

# Create the /app directory if it does not exist. This is the home directory for the roboshop user.
mkdir -p /app
validate $? "Creating /app directory"

# Download the shipping application code from the GitHub repository.
curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>> $logs_file
validate $? "Downloading shipping application code"

# Unzip the downloaded code into the /app directory.
cd /app
unzip -o /tmp/shipping.zip &>> $logs_file
validate $? "Unzipping shipping application code"

# Install the required Maven dependencies for the shipping application.
mvn clean package &>> $logs_file
validate $? "Installing Maven dependencies for shipping application"

# Move the generated shipping.jar file to the /app directory. 
mv target/shipping.jar shipping.jar
validate $? "Moving shipping.jar to /app directory"

# Install MySQL client to connect to the MySQL database server. This is required for the shipping application to interact with the database.
dnf install mysql -y &>> $logs_file
validate $? "Installing MySQL client"

# Load the master-data.sql script to create the necessary database schema and tables for the shipping application.
mysql -h mysql.$domain_name -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $logs_file
validate $? "Loading master-data.sql script"


# Replace the placeholder DOMAIN_NAME in the shipping.service file with the actual domain name.
sed -i -e "s/DOMAIN_NAME/${domain_name}/" $scripts_dir/shipping.service
cp $scripts_dir/shipping.service /etc/systemd/system/shipping.service

# Reload the systemd daemon to recognize the new service, enable it to start on boot, and start the service.
systemctl daemon-reload  &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl start shipping  &>> $logs_file
validate $? "Starting and enabling shipping service"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
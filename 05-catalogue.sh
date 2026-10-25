#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="mvvsnm.online"
scripts_dir=$(dirname $(realpath $0)) # get the directory path of the current script
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# check if the script is run as sudo or not. if not then exit the script with error message
if [ $user_id -ne 0 ]; then
    echo "Please run this script with sudo access.."
    exit 1
fi

# create the logs folder if not exists
mkdir -p $logs_folder

# timestamp function to get the current date and time in the format YYYY-MM-DD HH:MM:SS
timestamp(){
    date "+%F %T" 
}

# validate function to check the exit status of the command and log the result in the log file
validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

# start the script execution and log the start time
echo "$(timestamp) [INFO] ==== Script started Execution =====" | tee -a $logs_file

# Disable the existing nodejs module and enable the required version of nodejs module and install nodejs
dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "Installing NodeJS"


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

# Download the catalogue application code from the GitHub repository.
curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>> $logs_file
validate $? "Downloading catalogue application code"

# Unzip the downloaded code into the /app directory.
cd /app
unzip -o /tmp/catalogue.zip &>> $logs_file
validate $? "Unzipping catalogue application code"

# Install the required nodejs dependencies for the catalogue application.
npm install &>> $logs_file
validate $? "Installing nodejs dependencies for catalogue application"

# Replace the placeholder DOMAIN_NAME in the catalogue.service file with the actual domain name.
sed -i -e "s/DOMAIN_NAME/${domain_name}/" $scripts_dir/catalogue.service
cp $scripts_dir/catalogue.service /etc/systemd/system/catalogue.service

# Reload the systemd daemon to recognize the new service, enable it to start on boot, and start the service.
systemctl daemon-reload  &>> $logs_file
systemctl enable catalogue &>> $logs_file
systemctl start catalogue  &>> $logs_file
validate $? "Starting and enabling catalogue service"

# Add the MongoDB repository to the system's package manager and install the MongoDB client.
sed -i -e "s/DOMAIN_NAME/${domain_name}/" $scripts_dir/mongo.repo
cp $scripts_dir/mongo.repo /etc/yum.repos.d/mongo.repo &>> $logs_file
validate $? "Adding MongoDB repo"


# Install the MongoDB shell client to allow interaction with the MongoDB database.
dnf install mongodb-mongosh -y &>> $logs_file
validate $? "Installing MongoDB client"

# Check if the products collection in the catalogue database already has data. If not, load the master data into the collection using the provided master-data.js script.
product_count=$(mongosh --host mongodb.${domain_name} --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()')
validate $? "Checking if the products collection already has data"

# If the products collection is empty, load the master data into it using the master-data.js script. Otherwise, skip this step.
if [ $product_count -eq 0 ]; then
    mongosh --host mongodb.${domain_name} </app/db/master-data.js
    validate $? "Loading master data into products collection"
else
    echo -e "$(timestamp) [INFO] Products collection already has data...${Y}SKIPPING${N}"
    
fi

# Restart the catalogue service to ensure that all changes take effect and the application is running with the latest configuration and data.
systemctl restart catalogue &>> $logs_file
validate $? "Restarting catalogue service"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
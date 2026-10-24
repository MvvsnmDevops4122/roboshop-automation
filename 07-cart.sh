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

# Download the cart application code from the GitHub repository.
curl -L -o /tmp/cart.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/cart-v4.zip &>> $logs_file
validate $? "Downloading cart application code"

# Unzip the downloaded code into the /app directory.
cd /app
unzip -o /tmp/cart.zip &>> $logs_file
validate $? "Unzipping cart application code"

# Install the required nodejs dependencies for the cart application.
npm install &>> $logs_file
validate $? "Installing nodejs dependencies for cart application"

# Replace the placeholder DOMAIN_NAME in the cart.service file with the actual domain name.
sed -i -e "s/DOMAIN_NAME/${domain_name}/" $scripts_dir/cart.service
cp $scripts_dir/cart.service /etc/systemd/system/cart.service

# Reload the systemd daemon to recognize the new service, enable it to start on boot, and start the service.
systemctl daemon-reload  &>> $logs_file
systemctl enable cart &>> $logs_file
systemctl start cart  &>> $logs_file
validate $? "Starting and enabling cart service"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
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

# 
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


dnf install python3.14 python3.14-pip -y &>> $logs_file
validate $? "Installing Python 3.14"


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

# Download the payment application code from the GitHub repository.
curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/payment-v4.zip &>> $logs_file
validate $? "Downloading payment application code"

# Unzip the downloaded code into the /app directory.
cd /app
unzip -o /tmp/payment.zip &>> $logs_file
validate $? "Unzipping payment application code"

python3.14 -m venv /app/.venv &>> $logs_file
validate $? "Creating virtual directory"

/app/.venv/bin/pip install -r requirements.txt &>> $logs_file
validate $? "Installing dependences"

# Replace the placeholder DOMAIN_NAME in the payment.service file with the actual domain name.
sed -i -e "s/DOMAIN_NAME/${domain_name}/" $scripts_dir/payment.service
cp $scripts_dir/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload &>> $logs_file
systemctl enable payment &>> $logs_file
systemctl start payment
validate $? "Enable and start payment service"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
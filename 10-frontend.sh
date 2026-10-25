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


dnf module disable nginx -y &>> $logs_file
dnf module enable nginx:1.26 -y &>> $logs_file
dnf install nginx -y &>> $logs_file
validate $? "Installing Ngnix"

systemctl enable nginx &>> $logs_file
systemctl start nginx  &>> $logs_file
validate $? "Enable and start Ngnix"
 
rm -rf /usr/share/nginx/html/*  &>> $logs_file
validate $? "Removing default code Ngnix"

curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/frontend-v4.zip &>> $logs_file
cd /usr/share/nginx/html &>> $logs_file
unzip /tmp/frontend.zip &>> $logs_file
validate $? "Download and Extract frontend code"

# Replace the placeholder DOMAIN_NAME in the roboshop.conf file with the actual domain name.
sed -i -e "s/DOMAIN_NAME/${domain_name}/" $scripts_dir/roboshop.conf 
cp $scripts_dir/roboshop.conf /etc/systemd/system/roboshop.conf

nginx -t &>> $logs_file
validate $? "Nginx configuration"
 
systemctl restart nginx 
validate $? "Nginx restart"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
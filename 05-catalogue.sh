#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
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

dnf module disable nodejs -y
dnf module enable nodejs:24 -y
dnf install nodejs -y

validate $? "Installing NodeJS"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
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

# enable the MySQL module and install the MySQL server package
dnf module enable mysql:8.4 -y &>> $logs_file
dnf install mysql-server -y  &>> $logs_file
validate $? "Installing MySQL server"

# enable and start the MySQL service
systemctl enable mysqld  &>> $logs_file
systemctl start mysqld
validate $? "Start and Enable MySQL"

# run the MySQL secure installation command to set the root password and secure the installation
mysql_secure_installation --set-root-pass RoboShop@1  &>> $logs_file
validate $? "Setup MySQL root password"

# Time taken to complete the script execution and log the end time
echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"

# complete the script execution and log the end time
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
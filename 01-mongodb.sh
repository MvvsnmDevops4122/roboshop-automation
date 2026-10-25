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

# start the script execution 
echo "Script started execution at $(date +"%F %T")" &>> $logs_file

# validate function to check the exit status of the command 
validate(){
    if [ $1 -ne 0 ]; then
        echo -e "${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

# copy the mongo repo file to /etc/yum.repos.d/
cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $logs_file
validate $? "Adding MongoDB repo"

# install the mongodb-org package
dnf install mongodb-org -y &>> $logs_file
validate $? "MongoDB installation"

# enable and start the mongodb service
systemctl enable mongod &>> $logs_file
systemctl start mongod &>> $logs_file
validate $? "Enable and start Mongodb"

# update the mongodb config file to allow remote connections
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "Updating remote connections to MongoDB"

# restart the mongodb service to apply the changes
systemctl restart mongod
validate $? "Restarting MongoDB"
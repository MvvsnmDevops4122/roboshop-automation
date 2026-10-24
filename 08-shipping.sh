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
# The source command is then used to load the new environment variable into the current shell session.
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "Setting JAVA_HOME environment variable for Maven"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
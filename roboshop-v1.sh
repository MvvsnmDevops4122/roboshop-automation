#!/bin/bash

# This script is used to launch the EC2 instance and update R53 records
# First lanuch instance and get the instance id of the launched instance
# Then get the IP address(public or private) of the instance
# Then update the R53 records with the new IP address

ami_id="ami-0055977a6e828a4f4"
instance_type="t2.micro"
domain_name="mvvsnm.online"
hosted_zone_id="Z076746614D87GD4SF3TG"

echo "The start time of the script is: $(date +"%F %T")"

# Lanch ec2 instance and resove the instance id of the launched instance

for instance in $@  # Lanch ec2 instance and resove the instance id of the launched instance
do
    echo "Going to launch the instance : $instance"
    instance_id=$(aws ec2 run-instances \
            --image-id $ami_id \
            --instance-type $instance_type \
            --security-groups "roboshop-common-sg" "roboshop-${instance}-sg" \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-${instance}}]" \
            --query 'Instances[0].InstanceId' \
            --output text)

    echo "The instance id of the launched instance is: $instance_id"
done


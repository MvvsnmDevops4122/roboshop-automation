#!/bin/bash

# This script is used to launch the EC2 instance and update R53 records
# First get the instance Id 
# Then get the IP address of the instance
# Then update the R53 records with the new IP address

ami_id="ami-0055977a6e828a4f4"
instance_type="t2.micro"
domain_name="mvvsnm.online"
hosted_zone_id="Z076746614D87GD4SF3TG"

echo "The start time of the script is: $(date +"%F %T")"

for instance in $@
do
    echo "Going to launch the instance : $instance"
    instance_id=$(aws ec2 run-instances \
            --image-id $ami_id \
            --instance-type $instance_type \
            --security-groups "roboshop-common-sg","roboshop-$instance-sg" \
            --query 'Instances[0].InstanceId' \
            --output text)

    echo "The instance id of the launched instance is: $instance_id"
done


#!/bin/bash

# This script is used to launch the EC2 instance and update R53 records
# First lanuch instance and get the instance id of the launched instance
# Then get the IP address(public or private) of the instance
# Then update the R53 records with the new IP address
# Already SG and R53 records are created for the instance

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="mvvsnm.online"
hosted_zone_id="Z076746614D87GD4SF3TG"

# Launch ec2 instance and resolve the instance id of the launched instance

for instance in "$@"
do
    echo "Going to launch the instance: $instance"

    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --security-groups "roboshop-common-sg" "roboshop-${instance}-sg" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-${instance}}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    echo "The instance ID of $instance : $instance_id"

    # Get the public IP or private IP address of the launched instance

    if [ "$instance" == "frontend" ]; then
        ip_address=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
       
        r53_record_name=$domain_name     

    else
        ip_address=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
        r53_record_name=$instance.$domain_name
    fi

    # Update the R53 records with the new IP address

    echo "dns_record_name: $r53_record_name"

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$hosted_zone_id" \
        --change-batch '{
            "Comment": "Update record to reflect new IP address",
            "Changes": [{
                "Action": "UPSERT", 
                "ResourceRecordSet": {
                    "Name": "'"$r53_record_name"'",
                    "Type": "A",
                    "TTL": 60,
                    "ResourceRecords": [{"Value": "'"$ip_address"'"}]
                }
            }]
        }'
done

echo "The R53 records updated successfully for $instance."

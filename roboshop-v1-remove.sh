#!/bin/bash

# This is a automation script to remove all running instances from  the aws account

aws ec2 terminate-instances --region us-east-1 --instance-ids $(aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId" --output text)

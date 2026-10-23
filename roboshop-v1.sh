#!/bin/bash

# This script is used to launch the EC2 instance and update R53 records
# First get the instance Id 
# Then get the IP address of the instance
# Then update the R53 records with the new IP address

echo "The start time of the script is: $(date +%F %T)"


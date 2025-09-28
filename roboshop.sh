#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0cd87d6ca0bdc2016"
ZONE_ID="Z021089227RC5GG538AO4"
DOMAIN_NAME="gskdaws.fun"

for instance in "$@"
do
  # Launch EC2 instance
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
  echo "Launched instance ID: $INSTANCE_ID"

  # Wait until the instance is running
  echo "Waiting for instance $INSTANCE_ID to be in running state..."
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID
  echo "Instance $INSTANCE_ID is now running."

  # Fetch IP depending on instance type
  if [ "$instance" = "frontend" ]; then
      IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
      RECORD_NAME="$DOMAIN_NAME"
  else
      IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)
      RECORD_NAME="$instance.$DOMAIN_NAME"
  fi     

  echo "Updating DNS record: $RECORD_NAME -> $IP"

  # Update Route53 DNS record (fixed quoting)
  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{
      "Comment": "Updating record set",
      "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "'"$RECORD_NAME"'",
          "Type": "A",
          "TTL": 60,
          "ResourceRecords": [{
            "Value": "'"$IP"'"
          }]
        }
      }]
    }'

  if [ $? -eq 0 ]; then
    echo "DNS record for $RECORD_NAME updated successfully."
  else
    echo "Failed to update DNS record for $RECORD_NAME."
  fi

done

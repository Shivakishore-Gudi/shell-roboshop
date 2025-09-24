#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0cd87d6ca0bdc2016"

for instance in $@
do
  INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0cd87d6ca0bdc2016 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId'--output text)

  if [ $instance != "frontend" ]; then
     
done      
#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0bb49640c5f48feab"
ZONE_ID="Z0365586HY4DMG76QJ9E" #replace with your hosted zone ID ND aws -> route 53 -> hostedzones-> copy the zone id
DOMAIN_NAME="daw86s.space"
for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0bb49640c5f48feab --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]"  --query 'Instances[0].InstanceId' --output text)
    # akkada resources deggara double quotes vadali

#get private ip address of the instance
    if [ $instance != "frontend" ]; then # ; this symbol is impotant as it ends the if condition
     IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
     RECORD_NAME="$instance.$DOMAIN_NAME" #mangodb.daw86s.space
    else  
     IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)   
        RECORD_NAME="$DOMAIN_NAME" #daw86s.space
    fi

    echo "Instance $instance launched with IP address: $IP"
# create route53 entry
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID   \
  --change-batch '
  {
     "Comment": "Updating record set"
     ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
     }
    }]
  }  
  '
done 
    
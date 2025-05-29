#!/bin/bash
set -euo pipefail

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=kafka-setup" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)
echo $INSTANCE_ID

REGION="ap-northeast-2"
TFVAR_FILE="terraform.tfvars"
AMI_NAME="kafka-broker-ami-$(date -u +'%Y%m%d%H%M')"  

AMI_JSON=$(aws ec2 create-image \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --description "Kafka Broker AMI" \
  --no-reboot \
  --region "$REGION" \
  --output json)

AMI_ID=$(echo "$AMI_JSON" | jq -r '.ImageId')

if grep -q '^ami_id' "$TFVAR_FILE"; then
  sed -i "s|^ami_id.*|ami_id = \"$AMI_ID\"|" "$TFVAR_FILE"
else
  echo "ami_id = \"$AMI_ID\"" >> "$TFVAR_FILE"
fi

# terraform apply -auto-approve -var="ami_id=$AMI_ID"
# terraform apply -auto-approve -var="ami_id=ami-06deb310349777b5b"

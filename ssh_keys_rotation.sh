#!/bin/bash

# Check that an IP has been provided
if [ $# -ne 1 ]; then
    echo "Please provide an IP address"
    exit 5
fi

PRIVATE_IP=$1
NEW_KEY_NAME="RotatedKey"
KEY_PATH=$HOME/.ssh/SRubinKeys

# Step 1: Create a new pair of keys
ssh-keygen -t rsa -b 2048 -f ~/.ssh/$NEW_KEY_NAME -q -N ""

# Step 2: Copy the new public key to the private instance
ssh-copy-id -i ~/.ssh/${NEW_KEY_NAME}.pub -o "IdentitiesOnly=yes" -i $KEY_PATH ubuntu@"$PRIVATE_IP"

#Retrieve the old public key from the private instance
OLD_KEY=$(ssh -i $KEY_PATH ubuntu@"$PRIVATE_IP" "cat ~/.ssh/authorized_keys")

#Remove the old public key from the private instance
ssh ubuntu@"$PRIVATE_IP" "grep -v '$OLD_KEY' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys"


#!/bin/bash

#check that an IP has provided
if [ $# -ne 1 ]; then
    echo "please provide an IP address"
    exit 5
fi

PRIVATE_EC2_IP=$1

#Dedine so valuables for key rotation
NEW_KEY_NAME="new_key"
NEW_KEY_PATH="$HOME/.ssh/$NEW_KEY_NAME"
OLD_KEY_PATH="$HOME/.ssh/SRubinPrivateKey.pem"

#Creating a new pair keys1
ssh-keygen -t rsa -b 2048 -f $NEW_KEY_PATH -q -N ""

#Adding the new pub key to Private EC2
ssh-copy-id -i ${NEW_KEY_PATH}.pub ubuntu@"$PRIVATE_EC2_IP"

#Remove the old public key from the private instance
ssh -i $OLD_KEY_PATH ubuntu@"$PRIVATE_INSTANCE_IP" "sed -i '/$(cat ${OLD_KEY_PATH}.pub)/d' ~/.ssh/authorized_keys"


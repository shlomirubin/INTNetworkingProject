#!/bin/bash

#check that an IP has provided
if [ $# -ne 1 ]; then
    echo "please provide an IP address"
    exit 5
fi

PRIVATE_EC2_IP=$1

#logging to public EC2
ssh -i "KEY_PATH" Ubuntu@"PRIVATE_EC2_IP"

#Dedine so valuables for key rotation
NEW_KEY_NAME="new_key"
NEW_KEY_PATH="$HOME/.ssh/$NEW_KEY_NAME"
OLD_KEY_PATH="$HOME/.ssh/SRubinPrivateKey.pem"

#Creating a new pair keys1
ssh-keygen -t rsa -b 2048 -f $NEW_KEY_PATH -q -N ""

#Adding the new pub key to Private EC2
ssh-copy-id -i ${NEW_KEY_PATH}.pub ubuntu@"$PRIVATE_EC2_IP"

#Check if copy was succsful to private EC2.
if [ $? -ne 0 ]; then
  echo "Copy is failed"
  exit 1
fi

#Remove the old public key from the private instance
ssh -i $OLD_KEY_PATH ubuntu@$PRIVATE_INSTANCE_IP "sed -i '/$(cat ${OLD_KEY_PATH}.pub)/d' ~/.ssh/authorized_keys"

#check the new key is working
ssh -i @NEW_KEY_PATH ubuntu@$PRIVATE_EC2_IP

#check if key removed as expected.
if [ $? -ne 0 ]; then
  echo "failed to remove key"
  exit 1
fi

#Check that old key isn't working anymore.
ssh -i $OLD_KEY_PATH ubuntu@$PRIVATE_EC2_IP

#end of key rotations scenario
if [ $? -eq 0 ]; then
  echo 'old key still works'
  exit 1
else
  echo 'key rotation worked'
fi

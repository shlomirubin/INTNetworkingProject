#!/bin/bash
# Check that an IP has been provided
if [ $# -ne 1 ]; then
    echo "Please provide an IP address"
    exit 5
fi

PRIVATE_IP=$1
NEW_KEY_NAME="RotatedKey"
KEY_PATH2=$HOME/.ssh/SRubinKeyPrivate.pem
PUB_KEY_PATH=~/.ssh/$NEW_KEY_NAME.pub
NEW_PRIVATE_KEY=~/.ssh/RotatedKey

# Step 1: Create a new pair of keys
ssh-keygen -t rsa -b 2048 -f ~/.ssh/$NEW_KEY_NAME -q -N ""
# Step 2: Copy the public key to the private instance
scp -i "$KEY_PATH2" "$PUB_KEY_PATH" ubuntu@"$PRIVATE_IP":/home/ubuntu/
# Append the new public key to the authorized_keys file
ssh -i "$KEY_PATH2" ubuntu@"$PRIVATE_IP" "cat /home/ubuntu/RotatedKey.pub > ~/.ssh/authorized_keys && rm /home/ubuntu/RotatedKey.pub"

mv "$NEW_PRIVATE_KEY" "$KEY_PATH2"


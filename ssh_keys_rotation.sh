#!/bin/bash

# Check that an IP has been provided
if [ $# -ne 1 ]; then
    echo "Please provide an IP address"
    exit 5
fi

PRIVATE_IP=$1
NEW_KEY_NAME="RotatedKey"

# Step 1: Create a new pair of keys
ssh-keygen -t rsa -b 2048 -f ~/.ssh/$NEW_KEY_NAME -q -N ""

# Step 2: Copy the new public key to the private instance
ssh-copy-id -i ~/.ssh/${NEW_KEY_NAME}.pub ubuntu@"$PRIVATE_IP"

# Step 3: Remove the old public key from the private instance
OLD_KEY=$(cat $KEY_PATH.pub)  # Use the key defined in the test script
ssh ubuntu@"$PRIVATE_IP" "sed -i '/$OLD_KEY/d' ~/.ssh/authorized_keys"

# Step 4: Test connection with the new key
ssh -i ~/.ssh/${NEW_KEY_NAME} ubuntu@"$PRIVATE_IP" "echo 'Successfully connected with the new key!'"

# Step 5: Test connection with the old key (should fail)
if ssh -i $KEY_PATH ubuntu@"$PRIVATE_IP"; then
  exit 1  # Exit with error if the old key still works
fi

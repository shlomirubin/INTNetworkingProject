#!/bin/bash

#check that an IP has provided
if [ $# -ne 1 ]; then
    echo "please provide an IP address"
    exit 5
fi

PRIVATE_IP=$1

#Dedine so valuables for key rotation
NEW_KEY_NAME="RotatedKey"

#Creating a new pair keys1
ssh-keygen -t rsa -b 2048 -f ~/.ssh/$NEW_KEY_NAME -q -N ""
echo "New SSH key pair generated: ~/.ssh/${NEW_KEY_NAME} and ~/.ssh/${KEY_NAME}.pub"

# Copy the new public key to the private instance's authorized_keys
ssh-copy-id -i ~/.ssh/${NEW_KEY_NAME}.pub ubuntu@"$PRIVATE_IP"

# Step 3: Remove the old public key from the private instance
export OLD_KEY=$(cat ~/.ssh/id_rsa.pub)  # Assuming id_rsa is the old key

ssh ubuntu@"$PRIVATE_IP" "sed -i '/$OLD_KEY/d' ~/.ssh/authorized_keys"
echo "Old SSH key removed from the private instance."

# Step 4: Test connection with the new key
ssh -i ~/.ssh/${NEW_KEY_NAME} ubuntu@"$PRIVATE_IP" "echo 'Successfully connected with the new key!'"

# Step 5: Test connection with the old key (should fail)
if ssh -i ~/.ssh/id_rsa ubuntu@"$PRIVATE_IP"; then
  echo "Error: Old key still works! Rotation failed."
else
  echo "Old key no longer works. Key rotation successful."
fi
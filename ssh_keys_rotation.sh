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

# Step 1: Create a new pair of keys
ssh-keygen -t rsa -b 2048 -f ~/.ssh/$NEW_KEY_NAME -q -N ""
# Step 2: Copy the public key to the private instance
scp -i "$KEY_PATH2" "$PUB_KEY_PATH" ubuntu@"$PRIVATE_IP":/home/ubuntu/
# Append the new public key to the authorized_keys file
ssh -i "$KEY_PATH2" ubuntu@"$PRIVATE_IP" "cat /home/ubuntu/RotatedKey.pub >> ~/.ssh/authorized_keys && rm /home/ubuntu/RotatedKey.pub"

ssh -i "$KEY_PATH2" ubuntu@"$PRIVATE_IP" "grep -v 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCBYg6dkTTYhaUxhnwNSjyIJit6ExdhF1ZdSkajR7GbCCARZ+J3l37l5iElN/XOSWu6+1dnQoTSMDWvAR8eXhs727NLYj35BD3euAfWnrLTl93TQSEnbl04G9EjKZJ25C4VeI2hO3g/63yO4INKOWjVaT2SzSFFdgj39WmoiEqPZpJ53ComHkFJ+SWhwttNEebBCf/mTOBNVQnLBo9ur0ng729DnWg6fDvu4pz/cDF31gF8FFE/NE8KT47a8FiQ5jUBC3aVa4bIbi85ZRpT/sEuQ1JRoO81IF8E9Tz46bdJCP3Zsim072uSF/APt93DRiy7ZxdJowHeTHUqYimlKf8Z SRubinKeys'  ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys"


#!/bin/bash

# Check if KEY_PATH environment variable is set
if [ -z "$KEY_PATH" ]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi

# Check if any IP is provided
if [ $# -lt 1 ]; then
  echo "please provide an IP address"
  exit 5
fi

PUBLIC_IP=$1

# Case 2: Connect to the public instance
if [ $# -eq 1 ]; then
  ssh -i "$KEY_PATH" ubuntu@"$PUBLIC_IP"
  exit $?
fi

PRIVATE_IP=$2

# Case 1 or Case 3: Connect to the private instance via the public instance
if [ $# -ge 2 ]; then
  if [ $# -eq 2 ]; then
    ssh -i "$KEY_PATH" -J ubuntu@"$PUBLIC_IP" ubuntu@"$PRIVATE_IP"
  else
    # Case 3: Run a command on the private instance
    shift 2
    ssh -i "$KEY_PATH" -J ubuntu@"$PUBLIC_IP" ubuntu@"$PRIVATE_IP" "$@"
  fi
  exit $?
fi
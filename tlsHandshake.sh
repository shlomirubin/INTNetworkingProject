#!/bin/bash

# Check if the server IP is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <server-ip>"
    exit 5
fi

SERVER_IP=$1
CERT_CA_URL="https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/networking_project/cert-ca-aws.pem"
CERT_CA_FILE="cert-ca-aws.pem"
SERVER_CERT_FILE="cert.pem"
KEY_FILE="master_key.txt"
ENCRYPTED_KEY_FILE="encrypted_master_key.bin"
SESSION_ID=""
ENCRYPTED_SAMPLE_MESSAGE=""

# Function to print and exit on error
error_exit() {
    echo "$1"
    exit "$2"
}

# Step 1: Send Client Hello
echo "Sending Client Hello..."
RESPONSE=$(curl -s -X POST http://$SERVER_IP:8080/clienthello -H "Content-Type: application/json" -d '{
    "version": "1.3",
    "ciphersSuites": [
        "TLS_AES_128_GCM_SHA256",
        "TLS_CHACHA20_POLY1305_SHA256"
    ],
    "message": "Client Hello"
}')
if [ $? -ne 0 ]; then
    error_exit "Failed to send Client Hello request." 5
fi

# Step 2: Process Server Hello response
echo "Processing Server Hello response..."
SERVER_VERSION=$(echo $RESPONSE | jq -r '.version')
CIPHER_SUITE=$(echo $RESPONSE | jq -r '.cipherSuite')
SESSION_ID=$(echo $RESPONSE | jq -r '.sessionID')
SERVER_CERT_CONTENT=$(echo $RESPONSE | jq -r '.serverCert')
echo "$SERVER_CERT_CONTENT" > $SERVER_CERT_FILE

if [ -z "$SESSION_ID" ] || [ -z "$SERVER_CERT_CONTENT" ]; then
    error_exit "Invalid Server Hello response." 5
fi

# Step 3: Verify Server Certificate
echo "Verifying Server Certificate..."
wget -q -O $CERT_CA_FILE $CERT_CA_URL
openssl verify -CAfile $CERT_CA_FILE $SERVER_CERT_FILE > /dev/null
if [ $? -ne 0 ]; then
    error_exit "Server Certificate is invalid." 5
fi

# Step 4: Generate and Encrypt Master Key
echo "Generating Master Key..."
openssl rand -base64 32 > $KEY_FILE
MASTER_KEY=$(cat $KEY_FILE)
echo "Encrypting Master Key..."
openssl smime -encrypt -aes-256-cbc -in $KEY_FILE -outform DER $SERVER_CERT_FILE | base64 -w 0 > $ENCRYPTED_KEY_FILE

# Step 5: Send Encrypted Master Key
echo "Sending Encrypted Master Key..."
RESPONSE=$(curl -s -X POST http://$SERVER_IP:8080/keyexchange -H "Content-Type: application/json" -d "{
    \"sessionID\": \"$SESSION_ID\",
    \"masterKey\": \"$(cat $ENCRYPTED_KEY_FILE)\",
    \"sampleMessage\": \"Hi server, please encrypt me and send to client!\"
}")
if [ $? -ne 0 ]; then
    error_exit "Failed to send Encrypted Master Key." 5
fi

# Step 6: Process and Verify Server Response
echo "Processing Server Response..."
ENCRYPTED_SAMPLE_MESSAGE=$(echo $RESPONSE | jq -r '.encryptedSampleMessage')
echo "$ENCRYPTED_SAMPLE_MESSAGE" | base64 -d > encrypted_sample_message.bin

# Decrypt the sample message
echo "Decrypting Sample Message..."
DECRYPTED_MESSAGE=$(openssl enc -d -aes-256-cbc -pbkdf2 -in encrypted_sample_message.bin -k "$MASTER_KEY")
if [ "$DECRYPTED_MESSAGE" != "Hi server, please encrypt me and send to client!" ]; then
    error_exit "Server symmetric encryption using the exchanged master-key has failed." 6
fi

echo "Client-Server TLS handshake has been completed successfully"
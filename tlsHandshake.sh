#!/bin/bash

# Variables
SERVER_IP=$1
CERT_FILE="cert.pem"
CA_CERT_FILE="cert-ca-aws.pem"
MASTER_KEY_FILE="master_key.txt"
ENCRYPTED_KEY_FILE="encrypted_key.txt"
SESSION_ID=""
MASTER_KEY=""
ENC_SAMPLE_MESSAGE=""

# Check if server IP is provided
if [ -z "$SERVER_IP" ]; then
    echo "Usage: bash tlsHandshake.sh <server-ip>"
    exit 1
fi

# Step 1: Send Client Hello
echo "Starting TLS handshake with server at $SERVER_IP..."
echo "Sending Client Hello..."

CLIENT_HELLO_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{
   "version": "1.3",
   "ciphersSuites": [
      "TLS_AES_128_GCM_SHA256",
      "TLS_CHACHA20_POLY1305_SHA256"
   ],
   "message": "Client Hello"
}' http://$SERVER_IP:8080/clienthello)

# Debug - Show server response
echo "Server response: $CLIENT_HELLO_RESPONSE"

# Parse Server Hello response
SESSION_ID=$(echo "$CLIENT_HELLO_RESPONSE" | jq -r '.sessionID')
SERVER_CERT=$(echo "$CLIENT_HELLO_RESPONSE" | jq -r '.serverCert')

if [[ -z "$SESSION_ID" || -z "$SERVER_CERT" ]]; then
    echo "Error: Failed to parse Server Hello response."
    exit 2
fi

echo "Server version: $(echo "$CLIENT_HELLO_RESPONSE" | jq -r '.version')"
echo "Session ID: $SESSION_ID"

# Step 2: Save Server Certificate to file
echo "$SERVER_CERT" > $CERT_FILE  # No base64 decoding required

# Download CA certificate (Amazon Web Services in this case)
echo "Downloading CA certificate..."
wget -q https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/networking_project/cert-ca-aws.pem -O $CA_CERT_FILE

# Step 3: Verify Server Certificate
echo "Verifying server certificate..."
openssl verify -CAfile $CA_CERT_FILE $CERT_FILE
if [ $? -ne 0 ]; then
    echo "Server Certificate is invalid."
    exit 3
else
    echo "Server Certificate is valid."
fi

# Step 4: Generate Master Key and Encrypt it
echo "Generating master key..."
openssl rand -base64 32 > $MASTER_KEY_FILE
MASTER_KEY=$(cat $MASTER_KEY_FILE)

echo "Encrypting master key with server's public key..."
openssl smime -encrypt -aes-256-cbc -in $MASTER_KEY_FILE -outform DER $CERT_FILE | base64 -w 0 > $ENCRYPTED_KEY_FILE
ENCRYPTED_MASTER_KEY=$(cat $ENCRYPTED_KEY_FILE)

# Step 5: Send Encrypted Master Key to Server
echo "Sending encrypted master key to server..."

KEY_EXCHANGE_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "{
    \"sessionID\": \"$SESSION_ID\",
    \"masterKey\": \"$ENCRYPTED_MASTER_KEY\",
    \"sampleMessage\": \"Hi server, please encrypt me and send to client!\"
}" http://$SERVER_IP:8080/keyexchange)

# Debug - Show server response
echo "Server Key Exchange Response: $KEY_EXCHANGE_RESPONSE"

# Step 6: Parse and Decrypt the Encrypted Sample Message
ENC_SAMPLE_MESSAGE=$(echo "$KEY_EXCHANGE_RESPONSE" | jq -r '.encryptedSampleMessage')
if [ -z "$ENC_SAMPLE_MESSAGE" ]; then
    echo "Error: Failed to get encrypted sample message from server."
    exit 4
fi

echo "Decrypting the encrypted sample message..."
DECRYPTED_SAMPLE=$(echo "$ENC_SAMPLE_MESSAGE" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$MASTER_KEY")

# Step 7: Validate Decryption
if [ "$DECRYPTED_SAMPLE" != "Hi server, please encrypt me and send to client!" ]; then
    echo "Server Certificate is invalid."
    exit 5
else
    echo "Client-Server TLS handshake has been completed successfully."
fi


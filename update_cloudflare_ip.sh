#!/bin/bash

# Fetch the required variables from the environment
CF_API_TOKEN=${CF_API_TOKEN}
CF_ZONE_ID=${CF_ZONE_ID}
CF_RECORD_ID=${CF_RECORD_ID}
DOMAIN=${DOMAIN}

# Check if any of the required variables are missing
if [ -z "$CF_API_TOKEN" ] || [ -z "$CF_ZONE_ID" ] || [ -z "$CF_RECORD_ID" ] || [ -z "$DOMAIN" ]; then
  echo "Error: Missing required environment variables."
  echo "Please set CF_API_TOKEN, CF_ZONE_ID, CF_RECORD_ID, and DOMAIN."
  exit 1
fi

# File to store the old IP address
IP_FILE="/tmp/current_ip.txt"

# Get the current public IP address
CURRENT_IP=$(curl -s http://checkip.amazonaws.com)

# Get the old IP address
if [ -f $IP_FILE ]; then
  OLD_IP=$(cat $IP_FILE)
else
  OLD_IP=""
fi

# Compare the current IP with the old IP
if [ "$CURRENT_IP" != "$OLD_IP" ]; then
  echo "IP has changed to $CURRENT_IP"

  # Update the DNS record on Cloudflare
  RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$CURRENT_IP\",\"ttl\":1,\"proxied\":false}")

  # Check if the update was successful
  if echo "$RESPONSE" | jq -e '.success' > /dev/null; then
    echo "DNS record updated successfully."
    # Save the current IP address
    echo $CURRENT_IP > $IP_FILE
  else
    echo "Failed to update DNS record."
    echo "Response: $RESPONSE"
  fi
else
  echo "IP address has not changed."
fi
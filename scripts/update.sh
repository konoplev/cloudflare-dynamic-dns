#!/bin/bash

# Cloudflare Dynamic DNS Update Script
# This script updates an A record in Cloudflare DNS using the Cloudflare API

# Cloudflare API Token
#CLOUDFLARE_API_TOKEN="CLOUDFLARE_API_TOKEN"

# Cloudflare Zone ID
#ZONE_ID="ZONE_ID"

# The A record you want to update e.g. hello.example.com
#RECORDSET="RECORDSET"

# More advanced options below
# The Time-To-Live of this recordset (1 = Auto, 120 = 2 minutes, 300 = 5 minutes, etc.)
TTL=300
# Change this if you want
COMMENT="Auto updating @ `date`"
# Change to AAAA if using an IPv6 address
TYPE="A"

# Get the external IP address from OpenDNS (more reliable than other providers)
IP=`dig +short myip.opendns.com @resolver1.opendns.com`

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Get current dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="$DIR/update-cloudflare.log"
IPFILE="$DIR/update-cloudflare.ip"

if ! valid_ip $IP; then
    echo "Invalid IP address: $IP" >> "$LOGFILE"
    exit 1
fi

# Check if the IP has changed
if [ ! -f "$IPFILE" ]
    then
    touch "$IPFILE"
fi

if grep -Fxq "$IP" "$IPFILE"; then
    # code if found
    echo "IP is still $IP. Exiting" >> "$LOGFILE"
    exit 0
else
    echo "IP has changed to $IP" >> "$LOGFILE"
    
    # First, try to get the existing record
    EXISTING_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORDSET&type=$TYPE" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json")
    
    # Check if record exists
    RECORD_EXISTS=$(echo "$EXISTING_RECORD" | jq -r '.result | length')
    
    if [ "$RECORD_EXISTS" -gt 0 ]; then
        # Record exists, update it
        RECORD_ID=$(echo "$EXISTING_RECORD" | jq -r '.result[0].id')
        echo "Updating existing record $RECORD_ID" >> "$LOGFILE"
        
        UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{
                \"type\": \"$TYPE\",
                \"name\": \"$RECORDSET\",
                \"content\": \"$IP\",
                \"ttl\": $TTL,
                \"comment\": \"$COMMENT\"
            }")
        
        SUCCESS=$(echo "$UPDATE_RESPONSE" | jq -r '.success')
        if [ "$SUCCESS" = "true" ]; then
            echo "Successfully updated DNS record" >> "$LOGFILE"
        else
            echo "Failed to update DNS record: $(echo "$UPDATE_RESPONSE" | jq -r '.errors[0].message')" >> "$LOGFILE"
            exit 1
        fi
    else
        # Record doesn't exist, create it
        echo "Creating new DNS record" >> "$LOGFILE"
        
        CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{
                \"type\": \"$TYPE\",
                \"name\": \"$RECORDSET\",
                \"content\": \"$IP\",
                \"ttl\": $TTL,
                \"comment\": \"$COMMENT\"
            }")
        
        SUCCESS=$(echo "$CREATE_RESPONSE" | jq -r '.success')
        if [ "$SUCCESS" = "true" ]; then
            echo "Successfully created DNS record" >> "$LOGFILE"
        else
            echo "Failed to create DNS record: $(echo "$CREATE_RESPONSE" | jq -r '.errors[0].message')" >> "$LOGFILE"
            exit 1
        fi
    fi
    
    echo "IP Changed in Cloudflare DNS" >> "$LOGFILE"
fi

# All Done - cache the IP address for next time
echo "$IP" > "$IPFILE"

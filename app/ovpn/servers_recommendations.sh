#!/bin/bash

#Env
JSON_FILE=/tmp/servers_recommendations.json

#Get server recommendations
#https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations
curl -s $SERVER_RECOMMENDATIONS_URL -o $JSON_FILE

#Set vars
export SERVER="$(jq -r '.[0].hostname' $JSON_FILE)"
export SERVERNAME="$(jq -r '.[0].name' $JSON_FILE)"
export LOAD="$(jq -r '.[0].load' $JSON_FILE)"
export UPDATED_AT="$(jq -r '.[0].updated_at' $JSON_FILE)"
export IP="$(jq -r '.[0].station' $JSON_FILE)"
echo "$(jq -r '.[0].hostname' $JSON_FILE)" > /tmp/nordvpn_hostname
#!/bin/bash

. /app/date.sh --source-only

nordvpn_hostname=$(cat /tmp/nordvpn_hostname)
server_load=$(curl -s $SERVER_STATS_URL$nordvpn_hostname | jq -r '.[]')

#Check serverload value is not empty
if [ -z "$server_load" ];then
    echo "$(adddate) ERROR: No response from NordVPN API to get server load. This check to restart OpenVPN will be ignored."
    exit 1
fi

#Check serverload with expected load
if [ $server_load -gt $LOAD ]; then
    echo "$(adddate) WARNING: Load on $nordvpn_hostname is to high! Current load is $server_load and expected is $LOAD"
    echo "$(adddate) WARNING: OpenVPN will be restarted!"
    pgrep openvpn | xargs kill -15
else
    echo "$(adddate) INFO: The current load of $server_load on $nordvpn_hostname is okay"
fi
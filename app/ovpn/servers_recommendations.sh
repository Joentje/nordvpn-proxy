#!/bin/bash

. /app/date.sh --source-only

#Env
JSON_FILE=/tmp/servers_recommendations.json
JSON_FILE_SERVER_COUNTRIES=/tmp/servers_countries

# If no server was set, choose the best
if [[ ! -v SERVER ]]; then
    echo "$(adddate) INFO: SERVER has not been set, choosing best for you."
    QUERY_PARAM='?'
    if [ -z "$RANDOM_TOP" ]
        then
            QUERY_PARAM=$QUERY_PARAM'limit=1'
        else
            QUERY_PARAM=$QUERY_PARAM'limit='$RANDOM_TOP
    fi
    if [ -z "$COUNTRY" ]
        then 
            echo "$(adddate) INFO: No country has been set. The default will be picked by NordVPN API. If you want to use a country, please use e.g. COUNTRY=it"
            #GET fastest server based on NordVPN API
            #https://api.nordvpn.com/v1/servers/recommendations
        else
            echo "$(adddate) INFO: Your country setting will be used. This is set to: ${COUNTRY^^}"

            #Country codes will only be fetched once. You can force to get a new list to start a new container
            #This will speed up the process
            if [ -f "$JSON_FILE_SERVER_COUNTRIES" ]
                then
                    echo "$(adddate) INFO: The country codes are known, skipping"
                    export COUNTRY_CODE=$(cat $JSON_FILE_SERVER_COUNTRIES | jq '.[]  | select(.code == "'${COUNTRY^^}'") | .id')
                else 
                    echo "$(adddate) INFO: The country codes are unknown, getting country codes from API"
                    curl -s https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_countries -o /tmp/servers_countries
                    export COUNTRY_CODE=$(cat $JSON_FILE_SERVER_COUNTRIES | jq '.[]  | select(.code == "'${COUNTRY^^}'") | .id')
            fi

            QUERY_PARAM=$QUERY_PARAM'&filters%5Bcountry_id%5D='$COUNTRY_CODE
    fi
    
    #Set filter based on OpenVPN with the correct protocol
    QUERY_PARAM=$QUERY_PARAM'&filters%5Bservers_technologies%5D%5Bidentifier%5D=openvpn_'$PROTOCOL

    #GET fastest server based on COUNTRY
    #https://api.nordvpn.com/v1/servers/recommendations?limit=10&filters=[country_id]=106
    curl -s $SERVER_RECOMMENDATIONS_URL$QUERY_PARAM -o $JSON_FILE

    NUMBER_OF_SERVERS="$(jq length $JSON_FILE)"
    DESIRED_SERVER_NUMBER="$(shuf -i 0-$(($NUMBER_OF_SERVERS - 1)) -n 1)"

    #Set vars
    export SERVER="$(jq -r '.['$DESIRED_SERVER_NUMBER'].hostname' $JSON_FILE)"
    export SERVERNAME="$(jq -r '.['$DESIRED_SERVER_NUMBER'].name' $JSON_FILE)"
    export LOAD="$(jq -r '.['$DESIRED_SERVER_NUMBER'].load' $JSON_FILE)"
    export UPDATED_AT="$(jq -r '.['$DESIRED_SERVER_NUMBER'].updated_at' $JSON_FILE)"
    export IP="$(jq -r '.['$DESIRED_SERVER_NUMBER'].station' $JSON_FILE)"
    echo "$(jq -r '.['$DESIRED_SERVER_NUMBER'].hostname' $JSON_FILE)"
    echo "$(jq -r '.['$DESIRED_SERVER_NUMBER'].hostname' $JSON_FILE)" > /tmp/nordvpn_hostname

# Otherwise, use the server that was specified
else
    echo "$(adddate) INFO: SERVER has been set to ${SERVER^^}"
    curl --silent https://api.nordvpn.com/server | jq '.[] | select(.domain == '\"$SERVER\"')' > $JSON_FILE

    #Set vars
    export SERVERNAME="$(jq -r '.name' $JSON_FILE)"
    export LOAD=$(curl -s $SERVER_STATS_URL$SERVER | jq -r '.[]')
    export UPDATED_AT=""
    export IP="$(jq -r '.ip_address' $JSON_FILE)"
    echo "$SERVER" > /tmp/nordvpn_hostname
fi
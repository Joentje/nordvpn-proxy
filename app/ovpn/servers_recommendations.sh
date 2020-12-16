#!/bin/bash

. /app/date.sh --source-only

#Env
JSON_FILE=/tmp/servers_recommendations.json
JSON_FILE_SERVER_COUNTRIES=/tmp/servers_countries
JSON_FILE_SERVER_TYPES=/tmp/servers_types
COUNTRY_CODE=''
SERVER_TYPE_CODE=''

function get_country {
    if [ -z "$COUNTRY" ]
        then
            echo "$(adddate) INFO: No country has been set. The default will be picked by NordVPN API. If you want to use a country, please use e.g. COUNTRY=it"
        else
            echo "$(adddate) INFO: Your country setting will be used. This is set to: ${COUNTRY^^}"

            #Country codes will only be fetched once. You can force to get a new list to start a new container
            #This will speed up the process
            if [ -f "$JSON_FILE_SERVER_COUNTRIES" ]
                then
                    echo "$(adddate) INFO: The country codes are known, skipping"
                else
                    echo "$(adddate) INFO: The country codes are unknown, getting country codes from API"
                    curl -s https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_countries -o /tmp/servers_countries
            fi

            COUNTRY_CODE=$(cat $JSON_FILE_SERVER_COUNTRIES | jq '.[]  | select(.code | ascii_upcase == "'${COUNTRY^^}'") | .id')
            #GET fastest server based on COUNTRY
            #https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations&filters={%22country_id%22:106}
    fi
}

function get_server_types {
    if [ -z "$SERVER_TYPE" ]; then
        echo "$(adddate) INFO: No server_type has been set.  The default will be pickd by NordVPN API.  If you want to specify a server_type, please use ee.g. SERVER_TYPE=p2p"
    else
        export SERVER_TYPE="${SERVER_TYPE^^}"
        echo "$(adddate) INFO: Your server_type setting will be used. This is set to: $SERVER_TYPE"

        #Country codes will only be fetched once. You can force to get a new list to start a new container
        #This will speed up the process
        if [ -f "$JSON_FILE_SERVER_TYPES" ]
            then
                echo "$(adddate) INFO: The server_type codes are known, skipping"
            else
                echo "$(adddate) INFO: The server_type codes are unknown, getting server_type codes from API"
                curl -s https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_groups -o $JSON_FILE_SERVER_TYPES
        fi
        SERVER_TYPE_CODE=$(cat $JSON_FILE_SERVER_TYPES | jq --arg server_type "$SERVER_TYPE" '.[] | select(.name | ascii_upcase == $server_type) | .id')
        #GET fastest server based on SERVER_TYPE
        #https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations&filters={%22group_id%22:106}
    fi
}


# If no server was set, choose the best
if [[ ! -v SERVER ]]; then
    echo "$(adddate) INFO: SERVER has not been set, choosing best for you."

    get_country
    get_server_types

    FILTERS="&filters=%7B%22country_id%22:${COUNTRY_CODE},%22server_groups%22:%5B${SERVER_TYPE_CODE}%5D%7D"
    curl -s -o $JSON_FILE "$SERVER_RECOMMENDATIONS_URL$FILTERS"

    #Set vars
    export SERVER="$(jq -r '.[0].hostname' $JSON_FILE)"
    export SERVERNAME="$(jq -r '.[0].name' $JSON_FILE)"
    export LOAD="$(jq -r '.[0].load' $JSON_FILE)"
    export UPDATED_AT="$(jq -r '.[0].updated_at' $JSON_FILE)"
    export IP="$(jq -r '.[0].station' $JSON_FILE)"
    echo "$(jq -r '.[0].hostname' $JSON_FILE)" > /tmp/nordvpn_hostname
    echo "Connecting to $(jq -c -r '.[0].name' $JSON_FILE)  with technologies $(jq -c -r '.[0].groups | map(.title)' $JSON_FILE)"
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

#!/bin/bash

. /app/date.sh --source-only

#Env
JSON_FILE=/tmp/servers_recommendations.json
JSON_FILE_SERVER_COUNTRIES=/tmp/servers_countries


if [ -z "$COUNTRY" ]
    then 
        echo "$(adddate) INFO: No country has been set. The default will be picked by NordVPN API. If you want to use a country, please use e.g. COUNTRY=it"
        #GET fastest server based on NordVPN API
        #https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations
        curl -s $SERVER_RECOMMENDATIONS_URL -o $JSON_FILE
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
        
        #GET fastest server based on COUNTRY
        #https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations&filters={%22country_id%22:106}
        wget --quiet --header 'cache-control: no-cache' --output-document=$JSON_FILE ''$SERVER_RECOMMENDATIONS_URL'&filters={%22country_id%22:'$COUNTRY_CODE'}'
fi

#Set vars
export SERVER="$(jq -r '.[0].hostname' $JSON_FILE)"
export SERVERNAME="$(jq -r '.[0].name' $JSON_FILE)"
export LOAD="$(jq -r '.[0].load' $JSON_FILE)"
export UPDATED_AT="$(jq -r '.[0].updated_at' $JSON_FILE)"
export IP="$(jq -r '.[0].station' $JSON_FILE)"
echo "$(jq -r '.[0].hostname' $JSON_FILE)" > /tmp/nordvpn_hostname
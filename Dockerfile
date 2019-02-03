FROM alpine:3.8
LABEL MAINTAINER "Jeroen Slot"

ENV OVPN_FILES="https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip" \
    OVPN_CONFIG_DIR="/app/ovpn/config" \
    SERVER_RECOMMENDATIONS_URL="https://nordvpn.com/wp-admin/admin-ajax.php?action=servers_recommendations" \
    SERVER_STATS_URL="https://nordvpn.com/api/server/stats/" \
    CRON="*/15 * * * *" \
    USERNAME="" \
    PASSWORD="" \
    LOAD=75 \
    LOCAL_NETWORK=192.168.1.0/24

COPY app /app
EXPOSE 8118

RUN \
    echo "####### Installing packages #######" && \
    apk --update --no-cache add \
    privoxy openvpn runit bash jq ncurses curl unzip && \
    \
    echo "####### Changing permissions #######" && \
    find /app -name run | xargs chmod u+x && \
    find /app -name *.sh | xargs chmod u+x && \
    \
    echo "####### Download en extract ovpn files #######" && \
    mkdir -p ${OVPN_CONFIG_DIR} && \
    curl -o  ${OVPN_CONFIG_DIR}/ovpn.zip ${OVPN_FILES} && \
    unzip ${OVPN_CONFIG_DIR}/ovpn.zip -d ${OVPN_CONFIG_DIR} && \
    rm -rf ${OVPN_CONFIG_DIR}/ovpn.zip && \
    \
    echo "####### Removing packages #######" && \
    apk del unzip && \
    rm -rf /var/cache/apk/*

CMD ["runsvdir", "/app"]

HEALTHCHECK --interval=1m --timeout=10s \
  CMD if [[ $( curl -s https://api.nordvpn.com/vpn/check/full | jq -r '.["status"]' ) = "Protected" ]] ; then exit 0; else exit 1; fi
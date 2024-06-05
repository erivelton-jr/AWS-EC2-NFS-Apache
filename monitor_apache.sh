#!/bin/bash

STATUS=$(systemctl is-active httpd)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
DIRECTORY="/mnt/nfs_server/erivelton"

if [ "$STATUS" == "active" ]; then
    echo "$TIMESTAMP - httpd - ONLINE - Apache está funcionando" >> "$DIRECTORY/apache_status_online.log"
else
    echo "$TIMESTAMP - httpd - OFFLINE - Apache não está funcionando" >> "$DIRECTORY/apache_status_offline.log"
fi
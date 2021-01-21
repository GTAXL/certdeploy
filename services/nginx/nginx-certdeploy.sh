#!/bin/bash
# Certificate Watcher for nginx and other httpds
# Note, this script has to run as root in order to restart the nginx service!
# For certdeploy. When a www cert is renewed, reload the httpd
# nginx-certdeploy.sh
# Version 2.5
# JAN/21/2021
# Victor Coss gtaxl@gtaxl.net
# Credit: https://superuser.com/users/247052/vdr
# Example cronjob:
# @reboot /root/certdeploy/nginx-certdeploy.sh &

LTIME=`stat -c %Z /certdeploy/wwwcert`
systemctl reload nginx

while true    
do
   ATIME=`stat -c %Z /certdeploy/wwwcert`

   if [[ "$ATIME" != "$LTIME" ]]
   then    
       systemctl reload nginx
       LTIME=$ATIME
   fi
   sleep 1800
done
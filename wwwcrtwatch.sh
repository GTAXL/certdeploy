#!/bin/bash
# Certificate Watcher for nginx and other httpds
# For certdeploy. When a www cert is renewed, reload the httpd
# wwwcrtwatch.sh
# Version 1.0
# AUG/07/2020
# Victor Coss gtaxl@gtaxl.net
# Credit: https://superuser.com/users/247052/vdr

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
   sleep 15
done
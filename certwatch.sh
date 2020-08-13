#!/bin/bash
# Certificate Watcher, if a cert is renewed, execute a command
# certwatch.sh
# Version 1.1
# AUG/06/2020
# Victor Coss gtaxl@gtaxl.net
# Credit: https://superuser.com/users/247052/vdr
# Replace EXECUTE COMMAND HERE with what is needed for your intended application

server=example.com

LTIME=`stat -c %Z /certdeploy/$server/fullchain.pem`

EXECUTE COMMAND HERE

while true    
do
   ATIME=`stat -c %Z /certdeploy/$server/fullchain.pem`

   if [[ "$ATIME" != "$LTIME" ]]
   then    
       EXECUTE COMMAND HERE
	   LTIME=$ATIME
   fi
   sleep 15
done
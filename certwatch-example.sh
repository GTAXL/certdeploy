#!/bin/bash
# Certificate Watcher, if a cert is renewed, execute a command
# certwatch.sh
# Version 1.1
# AUG/06/2020
# Victor Coss gtaxl@gtaxl.net
# Credit: https://superuser.com/users/247052/vdr
# This is an example of certwatch.sh setup for UnrealIRCd 3.x

server=excession.gtaxl.net

LTIME=`stat -c %Z /certdeploy/$server/fullchain.pem`
cp /certdeploy/$server/fullchain.pem /home/gtaxl/GTAXLnetIRCd-3.0b/server.cert.pem
cp /certdeploy/$server/privkey.pem /home/gtaxl/GTAXLnetIRCd-3.0b/server.key.pem
chmod 600 /home/gtaxl/GTAXLnetIRCd-3.0b/*.pem
/home/gtaxl/rehashbot.sh > /dev/null 2>&1 &

while true    
do
   ATIME=`stat -c %Z /certdeploy/$server/fullchain.pem`

   if [[ "$ATIME" != "$LTIME" ]]
   then    
       cp /certdeploy/$server/fullchain.pem /home/gtaxl/GTAXLnetIRCd-3.0b/server.cert.pem
	   cp /certdeploy/$server/privkey.pem /home/gtaxl/GTAXLnetIRCd-3.0b/server.key.pem
	   chmod 600 /home/gtaxl/GTAXLnetIRCd-3.0b/*.pem
	   /home/gtaxl/rehashbot.sh > /dev/null 2>&1 &
       LTIME=$ATIME
   fi
   sleep 15
done
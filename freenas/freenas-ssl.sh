#!/bin/sh
# freenas-ssl.sh
# FreeNAS WebGUI nginx SSL certificate updater for certdeploy (Let's Encrypt)
# Version 1.00 AUG/27/2020
# Victor Coss gtaxl@gtaxl.net

domain=freenas.nas.lan.gtaxl.net

LTIME=`stat -f %m /certdeploy/$domain/fullchain.pem`

while true    
do
   ATIME=`stat -f %m /certdeploy/$domain/fullchain.pem`

   if [ "$ATIME" != "$LTIME" ]
   then
	   cd /certdeploy/
       /certdeploy/deploy_freenas.py
       LTIME=$ATIME
   fi
   sleep 60
done

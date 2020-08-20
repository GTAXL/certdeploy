#!/bin/bash
# Certificate Watcher, if a cert is renewed, execute a command
# certwatch.sh
# Version 1.1
# AUG/06/2020
# Victor Coss gtaxl@gtaxl.net
# Credit: https://superuser.com/users/247052/vdr
# This is an example for ZNC (IRC Bouncer service) before version 1.7

server=bnc.golden.gtaxl.net

LTIME=`stat -c %Z /certdeploy/$server/fullchain.pem`
cat /certdeploy/$server/privkey.pem /certdeploy/$server/fullchain.pem /home/gtaxl/.znc/dhparam.pem > /home/gtaxl/.znc/znc.pem

while true    
do
   ATIME=`stat -c %Z /certdeploy/$server/fullchain.pem`

   if [[ "$ATIME" != "$LTIME" ]]
   then    
       cat /certdeploy/$server/privkey.pem /certdeploy/$server/fullchain.pem /home/gtaxl/.znc/dhparam.pem > /home/gtaxl/.znc/znc.pem
       LTIME=$ATIME
   fi
   sleep 15
done
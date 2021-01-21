#!/bin/bash
# certdeploy for ZNC (IRC bouncer)
# znc-certdeploy.sh
# Version 2.5
# JAN/21/2021
# Victor Coss gtaxl@gtaxl.net
# Credit: https://superuser.com/users/247052/vdr
# This is an example for ZNC (IRC Bouncer service) before version 1.7
# Example cronjob:
# @reboot /home/gtaxl/certdeploy/znc-certdeploy.sh &
####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
server=bnc.golden.gtaxl.net
zncdir=/home/gtaxl/.znc
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################
LTIME=`stat -c %Z /certdeploy/$server/fullchain.pem`
cat /certdeploy/$server/privkey.pem /certdeploy/$server/fullchain.pem $zncdir/dhparam.pem > $zncdir/znc.pem

while true    
do
   ATIME=`stat -c %Z /certdeploy/$server/fullchain.pem`

   if [[ "$ATIME" != "$LTIME" ]]
   then    
       cat /certdeploy/$server/privkey.pem /certdeploy/$server/fullchain.pem $zncdir/dhparam.pem > $zncdir/znc.pem
       LTIME=$ATIME
   fi
   sleep 3600
done
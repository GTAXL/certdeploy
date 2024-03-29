#!/bin/sh
# pfsense-certdeploy.sh
# pfSense WebGUI nginx SSL certificate updater for certdeploy
# Last tested on pfSense Plus version 22.05-RELEASE
# This is for the Netgate 6100 and has the amd64 GNU binaries included.
# This will update the config.xml file with the newly renewed SSL cert from certdeploy.
# NOTE: Your webgui cert needs to be named "certdeploy" in the config.xml and you need the certdeploy user and directories setup first.
# We are NOT responsible for any damage or monetary losses, please backup your pfSense config before using this script.
# Version 1.0 NOV/04/2022
# Victor Coss gtaxl@gtaxl.net
# Credit: bartgrefte https://forum.netgate.com/topic/132560/update-ssl-certificate-from-command-line/19
####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
domain=pfsense.router.lan.gtaxl.net
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################
LTIME=`stat -f %m /certdeploy/$domain/fullchain.pem`

while true    
do
   ATIME=`stat -f %m /certdeploy/$domain/fullchain.pem`

   if [ "$ATIME" != "$LTIME" ]
   then
	   cd /certdeploy/
	   newcrt=$(/certdeploy/base64_amd64 /certdeploy/$domain/fullchain.pem | tr -d '[:space:]')
       newkey=$(/certdeploy/base64_amd64 /certdeploy/$domain/privkey.pem | tr -d '[:space:]')
       cp /conf/config.xml config-sslupdate.xml
       oldcrt=$(/certdeploy/grep_amd64 -A4 -P 'certdeploy' config-sslupdate.xml | awk '/<crt>/ { print $1}' | sed "s|<crt>||g" | sed "s|</crt>||g" | tr -d '[:space:]')
       oldkey=$(/certdeploy/grep_amd64 -A4 -P 'certdeploy' config-sslupdate.xml | awk '/<prv>/ { print $1}' | sed "s|<prv>||g" | sed "s|</prv>||g" | tr -d '[:space:]')
       /certdeploy/gsed_amd64 -i -e "s|$oldcrt|$newcrt|g" config-sslupdate.xml
       /certdeploy/gsed_amd64 -i -e "s|$oldkey|$newkey|g" config-sslupdate.xml
       mv -f config-sslupdate.xml /conf/config.xml
       rm /tmp/config.cache
       /etc/rc.restart_webgui > /dev/null 2>&1
       LTIME=$ATIME
   fi
   sleep 3600
done

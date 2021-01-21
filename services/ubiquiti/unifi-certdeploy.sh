#!/bin/bash
# Ubiquiti UniFi Controller SSL updater for Debian controllers
# NOTE: This script must be executed by root to restart the unifi service!
# For use with certdeploy
# unifi-certdeploy.sh
# Victor Coss gtaxl@gtaxl.net
# Version 2.5 JAN/20/2021
# Credit: Steve Jenkins <http://www.stevejenkins.com/>
# Example cronjob via root user:
# 0 * * * * /root/certdeploy/unifi-certdeploy.sh
####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
domain=unifi.lan.gtaxl.net
scriptdir=/root/certdeploy
# Don't change these unless you know what you're doing. These are correct for Debian/Ubuntu.
contrdir=/var/lib/unifi
JAVA_DIR=/usr/lib/unifi
keystore=/var/lib/unifi/keystore
alias=unifi
password=aircontrolenterprise
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################

if [[ -f $scriptdir/unifi-certdeploy.txt ]]
then
	LTIME=$(cat $scriptdir/unifi-certdeploy.txt)
	ATIME=`stat -c %Z /certdeploy/$domain/fullchain.pem`
	if [[ "$ATIME" != "$LTIME" ]]
		then
			echo $ATIME > $scriptdir/unifi-certdeploy.txt
			cd $contrdir
			systemctl stop unifi
			cp $keystore $keystore.bak
			openssl pkcs12 -export -in "/certdeploy/$domain/fullchain.pem" -inkey "/certdeploy/$domain/privkey.pem" -out "${contrdir}/tmpssl" -passout pass:"${password}" -name "${alias}"
			keytool -delete -alias "${alias}" -keystore "${keystore}" -deststorepass "${password}"
			keytool -importkeystore -srckeystore "${contrdir}/tmpssl" -srcstoretype PKCS12 -srcstorepass "${password}" -destkeystore "${keystore}" -deststorepass "${password}" -destkeypass "${password}" -alias "${alias}" -trustcacerts
			rm -f $contrdir/tmpssl
			systemctl start unifi
		else
			exit
	fi
else
	stat -c %Z /certdeploy/$domain/fullchain.pem > $scriptdir/unifi-certdeploy.txt
	cd $contrdir
	systemctl stop unifi
	cp $keystore $keystore.bak
	openssl pkcs12 -export -in "/certdeploy/$domain/fullchain.pem" -inkey "/certdeploy/$domain/privkey.pem" -out "${contrdir}/tmpssl" -passout pass:"${password}" -name "${alias}"
	keytool -delete -alias "${alias}" -keystore "${keystore}" -deststorepass "${password}"
	keytool -importkeystore -srckeystore "${contrdir}/tmpssl" -srcstoretype PKCS12 -srcstorepass "${password}" -destkeystore "${keystore}" -deststorepass "${password}" -destkeypass "${password}" -alias "${alias}" -trustcacerts
	rm -f $contrdir/tmpssl
	systemctl start unifi
fi
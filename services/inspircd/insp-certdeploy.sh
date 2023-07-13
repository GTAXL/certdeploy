#!/bin/bash
# certdeploy for InspIRCd 3.x
# Updates the SSL certificate for InspIRCd when using certdeploy.
# Requires the sslrehashsignal module to be loaded. More info here: https://docs.inspircd.org/3/modules/sslrehashsignal/
# FYI, this is included in the Debian package; it just needs to be loaded in your Insp config by placing <module name="sslrehashsignal">
# It is recommended you run this under root's crontab so it can update file permissions!
# insp-certdeploy.sh
# Victor Coss gtaxl@gtaxl.net
# Version 1.0 JUL/13/2023
# Example cronjob:
# 0 * * * * /root/certdeploy/insp-certdeploy.sh
####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
server=radium.dev.server.openbackdoor.com # The domain on the ssl cert for the server.
cert=/etc/inspircd/cert.pem # Where your Insp certificate file is stored. Defaults to Debian package location.
key=/etc/inspircd/key.pem # Where your Insp private key is stored. Defaults to Debian package location.
pid="" # Location to the PID file. Leave this blank if using a packaged install (--nopid flag passed on binary). Defaults to Debian package.
user=irc # The user and group to set the cert files to when placed. Defaults to Debian package user.
scriptdir=/root/certdeploy # The directory that this script is stored in.
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################

if [ ! -f "/certdeploy/$server/fullchain.pem" ]; then
	echo "ERROR! The certificate couldn't be found. Check the /certdeploy/ directory and what you have configured for the server variable."
	exit 1
fi

confpath=$(dirname "$cert")

if [ ! -d "$confpath" ]; then
	echo "ERROR! Your InspIRCd configuration directory doesn't exist. Check the directory you set on cert and key."
	exit 1
fi

update() {
	install -o $user -g $user -m 600 /certdeploy/$server/fullchain.pem $cert
	install -o $user -g $user -m 600 /certdeploy/$server/privkey.pem $key
	if [ ! -z "$pid" ]
	then
		if [ -e ${pid} ]
		then
			kill -USR1 `cat ${pid}`
		else
			echo "ERROR! A pid file is defined but does not exist."
			exit 1
		fi
	else
		systemctl kill --signal=SIGUSR1 inspircd.service
	fi	
}

if [[ -f $scriptdir/insp-certdeploy.txt ]]
then
	LTIME=$(cat $scriptdir/insp-certdeploy.txt)
	ATIME=`stat -c %Z /certdeploy/$server/fullchain.pem`
	if [[ "$ATIME" != "$LTIME" ]]
		then
			echo $ATIME > $scriptdir/insp-certdeploy.txt
			update
		else
			exit
	fi
else
	stat -c %Z /certdeploy/$server/fullchain.pem > $scriptdir/insp-certdeploy.txt
	update
fi

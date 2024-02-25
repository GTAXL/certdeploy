#!/bin/bash
# certdeploy for ZNC (IRC bouncer)
# znc-certdeploy.sh
# It is recommended you run this under root's crontab so it can update file permissions!
# Version 3.0
# FEB/24/2024
# Victor Coss gtaxl@gtaxl.net
# Example cronjob:
# 0 * * * * /root/certdeploy/znc-certdeploy.sh
####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
server=bnc.arsenic.openbackdoor.com # The domain on the SSL cert for the server.
cert=/var/lib/znc/znc.pem # The location of the SSL certificate. Defaults to Debian package.
zncuser=_znc # The user ZNC runs as. Defaults to Debian package.
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################

scriptdir=$(realpath $(dirname $0))

if [ ! -f "/certdeploy/$server/fullchain.pem" ]; then
	echo "ERROR! The certificate couldn't be found. Check the /certdeploy/ directory and what you have configured for the server variable."
	exit 1
fi

confpath=$(dirname "$cert")

if [ ! -d "$confpath" ]; then
	echo "ERROR! Your ZNC configuration directory doesn't exist. Check the directory you set for your certificate."
	exit 1
fi

if [ ! -f "/certdeploy/$server/dhparam.pem" ]; then
	cd /certdeploy/$server/
	openssl dhparam -out dhparam.pem 2048
	chown certdeploy:$zncuser dhparam.pem
	chmod o-r dhparam.pem
fi

update() {
	cat /certdeploy/$server/privkey.pem /certdeploy/$server/fullchain.pem /certdeploy/$server/dhparam.pem > $cert
}

if [[ -f $scriptdir/znc-certdeploy.txt ]]
then
	LTIME=$(cat $scriptdir/znc-certdeploy.txt)
	ATIME=`stat -c %Z /certdeploy/$server/fullchain.pem`
	if [[ "$ATIME" != "$LTIME" ]]
		then
			echo $ATIME > $scriptdir/znc-certdeploy.txt
			update
		else
			exit
	fi
else
	stat -c %Z /certdeploy/$server/fullchain.pem > $scriptdir/znc-certdeploy.txt
	update
fi

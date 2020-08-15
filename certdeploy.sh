#!/bin/bash
# Deploy new SSL certificate to remote servers for Let's Encrypt
# certdeploy.sh
# Version 1.3
# AUG/15/2020
# Victor Coss gtaxl@gtaxl.net

IFS=';'
cat certdeploy.conf | grep $1 | while read cert ip port www; do
	if [ $ip = "null" ]; then
		chmod 640 /certdeploy/$1/*.pem
		if [ $www = "yes" ]; then
			touch /certdeploy/wwwcert
		else
			exit
		fi
	else
		chmod 640 /certdeploy/$1/*.pem
		scp -P $port -i sshkey.id -q /certdeploy/$1/cert.pem /certdeploy/$1/chain.pem /certdeploy/$1/fullchain.pem /certdeploy/$1/privkey.pem certdeploy@$ip:/certdeploy/$1/
		ssh -p $port -i sshkey.id -q certdeploy@$ip "chmod 640 /certdeploy/$1/*.pem && exit"
		if [ $www = "yes" ]; then
			ssh -p $port -i sshkey.id -q certdeploy@$ip "touch /certdeploy/wwwcert && exit"
		else
			exit
		fi
	fi
done
exit
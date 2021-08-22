#!/bin/bash
# certdeploy for TrueNAS CORE, formerly known as FreeNAS
# Last tested on TrueNAS CORE 12.0-U5.1
# Utilizes TrueNAS RESTful API v2.0 to update SSL certificate
# truenas-certdeploy.sh
# Victor Coss gtaxl@gtaxl.net
# Version 1.0 AUG/22/2021
# Example cronjob:
# 0 * * * * /home/certdeploy/watchers/truenas/truenas-certdeploy.sh
####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
api_key="changeme" #Change this to the API Key you obtained from your TrueNAS box.
domain="freenas.nas.lan.gtaxl.net" #This is the domain name of the certificate and dns address you will be using.
host="10.0.0.6" #This can be the domain name if you have dns setup, or the IP address of the TrueNAS server. This is useful if you have the truenas on LAN but don't have internal DNS records setup.
verify="false" #Set this to false if host is an IP address. This is also useful to set to false when first changing out an invalid/expired cert. If an existing legit cert exists, set this to true.
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################

cert=$(date +certdeploy-%Y-%m-%d)
fullchain=$(jq -sR . /certdeploy/$domain/fullchain.pem)
key=$(jq -sR . /certdeploy/$domain/privkey.pem)

error() {
	time=$(date --iso-8601=seconds)
	echo -e "[0;31m$time ERROR: ${@:1}[0m" 1>&2
	/home/certdeploy/smtp.sh remote_script $time ERROR: ${@:1}
}

#Credit @socram8888 https://github.com/socram8888
scriptexitval=1
trap "exit \$scriptexitval" SIGKILL
abort() {
	scriptexitval=$1
	kill 0
}

if [ $verify == "true" ]; then
	verifyparam=' '
else
	verifyparam='-k '
fi

delete_old_cert() {
	resp=$(curl $verifyparam-H "Authorization: Bearer $api_key" -H "Content-Type: application/json" --http1.1 -s -X DELETE -i "https://$host/api/v2.0/certificate/id/${old_cert_id}")
	success=$(echo $resp | grep "HTTP/1.1 200 OK")
	if [ -z "$success" ]; then
		error "Failed to remove old TrueNAS certificate with certid $old_cert_id"
		error $resp
	fi
}

reload_webgui() {
	resp=$(curl $verifyparam-H "Authorization: Bearer $api_key" -H "Content-Type: application/json" --http1.1 -s -i "https://$host/api/v2.0/system/general/ui_restart")
	success=$(echo $resp | grep "HTTP/1.1 200 OK")
	if [ -z "$success" ]; then
		error "Failed to reload TrueNAS webgui."
		error $resp
	else
		if [ -n "$old_cert_id" ]; then
			delete_old_cert
		fi
	fi
}

activate_cert() {
	resp=$(curl $verifyparam-H "Authorization: Bearer $api_key" -H "Content-Type: application/json" --http1.1 -s -X PUT -i "https://$host/api/v2.0/system/general/" -d "{\"ui_certificate\":\"${new_cert_id}\"}")
	success=$(echo $resp | grep "HTTP/1.1 200 OK")
	if [ -z "$success" ]; then
		error "Failed to activate new TrueNAS certificate."
		error $resp
		abort 1
	fi
	resp=$(curl $verifyparam-H "Authorization: Bearer $api_key" -H "Content-Type: application/json" --http1.1 -s -X PUT -i "https://$host/api/v2.0/ftp/" -d "{\"ssltls_certificate\":\"${new_cert_id}\"}")
	success=$(echo $resp | grep "HTTP/1.1 200 OK")
	if [ -z "$success" ]; then
		error "Failed to activate new TrueNAS FTP certificate."
		error $resp
	fi
	resp=$(curl $verifyparam-H "Authorization: Bearer $api_key" -H "Content-Type: application/json" --http1.1 -s -X PUT -i "https://$host/api/v2.0/webdav/" -d "{\"certssl\":\"${new_cert_id}\"}")
	success=$(echo $resp | grep "HTTP/1.1 200 OK")
	if [ -z "$success" ]; then
		error "Failed to activate new TrueNAS WebDAV certificate."
		error $resp
	fi	
	reload_webgui
}

fetch_cert_id() {
	new_cert_id=$(curl $verifyparam-H "Authorization: Bearer $api_key" -H "Content-Type: application/json" --http1.1 -s "https://$host/api/v2.0/certificate?limit=0" | jq --arg cert "$cert" '.[] | select(.name == $cert).id')
	if [ -f "/home/certdeploy/watchers/truenas/certid.txt" ]; then
		old_cert_id=$(cat /home/certdeploy/watchers/truenas/certid.txt)
	fi
	echo $new_cert_id > /home/certdeploy/watchers/truenas/certid.txt
	activate_cert
}

upload_cert() {
	resp=$(curl $verifyparam-H "Authorization: Bearer $api_key" -H "Content-Type: application/json" --http1.1 -s -i "https://$host/api/v2.0/certificate" -d "{\"name\":\"${cert}\",\"certificate\":${fullchain},\"privatekey\":${key},\"create_type\":\"CERTIFICATE_CREATE_IMPORTED\"}")
	success=$(echo $resp | grep "HTTP/1.1 200 OK")
	if [ -z "$success" ]; then
		error "Failed to upload new certificate to TrueNAS via API."
		error $resp
		abort 1
	else
		sleep 3
		fetch_cert_id
	fi
}

if [[ -f /home/certdeploy/watchers/truenas/truenas-certdeploy.txt ]]
then
	LTIME=$(cat /home/certdeploy/watchers/truenas/truenas-certdeploy.txt)
	ATIME=`stat -c %Z /certdeploy/$domain/fullchain.pem`
	if [[ "$ATIME" != "$LTIME" ]]
		then
			echo $ATIME > /home/certdeploy/watchers/truenas/truenas-certdeploy.txt
			upload_cert
		else
			exit
	fi
else
	stat -c %Z /certdeploy/$domain/fullchain.pem > /home/certdeploy/watchers/truenas/truenas-certdeploy.txt
	upload_cert
fi

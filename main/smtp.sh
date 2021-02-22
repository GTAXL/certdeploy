#!/bin/bash
#SMTP Mailer for certdeploy
#/home/certdeploy/smtp.sh
#Sends e-mail notifications from certdeploy for any errors or concerns
#Uses an external SMTP server such as GTAXLnet Mail, G-Mail, etc.
#Victor Coss gtaxl@gtaxl.net
#Version 1.0 FEB/21/2021

####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
enabled='no' #Change this to yes if you have setup this script, it will notify other scripts you wish to send emails.
debug='no' #If set to yes, will log entire server communication to smtp.log. Useful when debugging configuration issues or bugs. WARNING! In this mode the username and password base64 will be in the smtp.log!
username='notify@gtaxl.net' #The username or e-mail address you will be sending e-mails from, authenticating to.
password='changeme' #The password to login to the e-mail account.
server='mail.gtaxl.net:587' #The SMTP server and port, commonly port 587, 465 or 25.
ehlo='jetstream.server.gtaxl.net' #The FQDN hostname of the main certdeploy server
starttls='no' #Whether to issue starttls, if set to no a direct tls connection will be used.
dstemail='gtaxl@gtaxl.net' #The E-Mail address to send the notification e-mails to.
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################

date=$(date +'%a, %-d %b %Y %H:%M:%S %z')

if [ $enabled != "yes" ]; then
	if [ "$1" == "remote_script" ]; then
		exit 0
	else
		time=$(date --iso-8601=seconds)
		echo -e "[0;31m$time ERROR: E-Mail notifications are not enabled or configured.[0m" 1>&2
		exit 1
	fi
fi

if [ "$1" == "remote_script" ]; then
	payload=${@:2}
else
	payload=${@:1}
fi

if [ $debug == "yes" ]; then
	curlparam='-v '
	touch /home/certdeploy/smtp.log
	chmod 600 /home/certdeploy/smtp.log
else
	curlparam=' '
fi

if [ $starttls == "yes" ]; then
	curl -s $curlparam--ssl-reqd --url "smtp://$server/$ehlo" --mail-from "$username" --mail-rcpt "$dstemail" --user "$username:$password" \
	-T <(echo -e "From: certdeploy <$username>\nTo: <$dstemail>\nSubject: certdeploy alert\nDate: $date\n\n$payload") &> /home/certdeploy/smtp.log
else
	curl -s $curlparam--url "smtps://$server/$ehlo" --ssl-reqd --mail-from "$username" --mail-rcpt "$dstemail" --user "$username:$password" \
	-T <(echo -e "From: certdeploy <$username>\nTo: <$dstemail>\nSubject: certdeploy alert\nDate: $date\n\n$payload") &> /home/certdeploy/smtp.log
fi

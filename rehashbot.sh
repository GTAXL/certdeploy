#!/bin/bash
# Connects to IRC, opers up and rehashes the SSL config for UnrealIRCd 3.2x
# which doesn't support commandline ssl reload
# Make sure to change the nick for each server to prevent nick collisions
# rehashbot.sh
# Victor Coss gtaxl@gtaxl.net
# Version 2.0 AUG/13/2020
# Credit: https://github.com/Newbrict/bash-irc-bot

operpassword=reallysecurepassword
nickpassword=changemeplz
server=excession
nick=certdeploy01
logchan=#staff
input=".bot.cfg"

echo "NICK $nick" > $input
echo "USER ssl 8 * :Rehashes SSL certs." >> $input

timeout 5s tail -f $input | openssl s_client -quiet -connect 127.0.0.1:6697 | while read res; do
	case "$res" in
		PING*)
			token=`echo $res | cut -d " " -f2-`
			echo "PONG $token" >> $input 
		;;
	
		*"You are now connected to GTAXLnet"*)
			echo "PRIVMSG NickServ :IDENTIFY $nickpassword" >> $input
			echo "OPER certdeploy $operpassword" >> $input
			echo "REHASH -ssl" >> $input
		;;
	
		*"SSL rehash"*)
			sleep 2
			echo "PRIVMSG $logchan :SSL certificate has been renewed for $server." >> $input
			echo "QUIT My work is done here." >> $input
			rm .bot.cfg
		;;
		
		*)
			echo $res >> /dev/null
		;;
	esac
done
exit
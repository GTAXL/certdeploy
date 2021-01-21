#!/bin/bash
# certdeploy for UnrealIRCd 3.2.x
# unreal3-certdeploy.sh
# Victor Coss gtaxl@gtaxl.net
# Version 2.5 JAN/06/2021
# Example cronjob:
# 0 * * * * /home/gtaxl/certdeploy/unreal3-certdeploy.sh
####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
operpassword=securepassword
nickpassword=changeme
server=excession.gtaxl.net
nick=certdeploy01 # This must be unique for each server to prevent nick collisions
logchan=#staff
scriptdir=/home/gtaxl/certdeploy
unrealdir=/home/gtaxl/GTAXLnetIRCd-3.0b
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################
rehashbot() {
input=".bot.cfg"

echo "NICK $nick" > $input
echo "USER ssl 8 * :certdeploy v2.5" >> $input

timeout 5s tail -f $input | openssl s_client -quiet -connect 127.0.0.1:6697 | while read res; do
	case "$res" in
		PING*)
			token=`echo $res | cut -d " " -f2-`
			echo "PONG $token" >> $input 
		;;
	
		*"Welcome to the"*)
			echo "MODE $nick +B" >> $input
			echo "PRIVMSG NickServ :IDENTIFY $nickpassword" >> $input
			echo "OPER certdeploy $operpassword" >> $input
			echo "REHASH -ssl" >> $input
		;;
		
		*"VERSION"*)
			res=${res%%!*} res=${res#:}; declare -p res
			echo "NOTICE $res "$(echo -ne ":\001VERSION ") "certdeploy v2.5 https://github.com/GTAXL/certdeploy"$(echo -ne "\001") >> $input
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
}

if [[ -f $scriptdir/unreal3-certdeploy.txt ]]
then
	LTIME=$(cat $scriptdir/unreal3-certdeploy.txt)
	ATIME=`stat -c %Z /certdeploy/$server/fullchain.pem`
	if [[ "$ATIME" != "$LTIME" ]]
		then
			echo $ATIME > $scriptdir/unreal3-certdeploy.txt
			cp /certdeploy/$server/fullchain.pem $unrealdir/server.cert.pem
			cp /certdeploy/$server/privkey.pem $unrealdir/server.key.pem
			chmod 600 $unrealdir/*.pem
			rehashbot > /dev/null 2>&1 &
		else
			exit
	fi
else
	stat -c %Z /certdeploy/$server/fullchain.pem > $scriptdir/unreal3-certdeploy.txt
	cp /certdeploy/$server/fullchain.pem $unrealdir/server.cert.pem
    cp /certdeploy/$server/privkey.pem $unrealdir/server.key.pem
    chmod 600 $unrealdir/*.pem
	rehashbot > /dev/null 2>&1 &
fi
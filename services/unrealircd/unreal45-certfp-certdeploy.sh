#!/bin/bash
# certdeploy for UnrealIRCd 4.x and 5.x
# Utilizes certificate fingerprint for authentication, certfp
# unreal45-certfp-certdeploy.sh
# Victor Coss gtaxl@gtaxl.net
# Version 2.6 MAR/11/2021
# Example cronjob:
# 0 * * * * /home/gtaxl/certdeploy/unreal45-certfp-certdeploy.sh
####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
certfp=certdeploy.pem
server=excession.gtaxl.net
nick=certdeploy01 # This must be unique for each server to prevent nick collisions
logchan=#staff
scriptdir=/home/gtaxl/certdeploy
unrealdir=/home/gtaxl/unrealircd
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################
cd $scriptdir

rehashbot() {
input=".bot.cfg"

echo "NICK $nick" > $input
echo "USER ssl 8 * :certdeploy v2.5" >> $input

timeout 5s tail -f $input | openssl s_client -quiet -cert $certfp -key $certfp -connect 127.0.0.1:6697 | while read res; do
	case "$res" in
		PING*)
			token=`echo $res | cut -d " " -f2-`
			echo "PONG $token" >> $input 
		;;
	
		*"Welcome to the"*)
			sleep 1
			echo "MODE $nick +B" >> $input
			echo "OPER certdeploy" >> $input
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

if [[ -f $scriptdir/unreal45-certfp-certdeploy.txt ]]
then
	LTIME=$(cat $scriptdir/unreal45-certfp-certdeploy.txt)
	ATIME=`stat -c %Z /certdeploy/$server/fullchain.pem`
	if [[ "$ATIME" != "$LTIME" ]]
		then
			echo $ATIME > $scriptdir/unreal45-certfp-certdeploy.txt
			cp /certdeploy/$server/fullchain.pem $unrealdir/conf/ssl/server.cert.pem
			cp /certdeploy/$server/privkey.pem $unrealdir/conf/ssl/server.key.pem
			chmod 600 $unrealdir/conf/ssl/*.pem
			rehashbot > /dev/null 2>&1 &
		else
			exit
	fi
else
	stat -c %Z /certdeploy/$server/fullchain.pem > $scriptdir/unreal45-certfp-certdeploy.txt
	cp /certdeploy/$server/fullchain.pem $unrealdir/conf/ssl/server.cert.pem
    cp /certdeploy/$server/privkey.pem $unrealdir/conf/ssl/server.key.pem
    chmod 600 $unrealdir/conf/ssl/*.pem
	rehashbot > /dev/null 2>&1 &
fi
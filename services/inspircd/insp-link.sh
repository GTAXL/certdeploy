#!/bin/bash
# Generates SSL cert for server linking only and gives you the fingerprint.
# Run this in your InspIRCd configuration directory. Likely /etc/inspircd/
# Run this under the same user account that you are running InspIRCd on, or change ownership afterwards.
# Ex. chown irc:irc link-cert.pem link-key.pem
# Victor Coss gtaxl@gtaxl.net
# Version 1.0 JUL/13/2023
#
#Generate a new SSL certificate for server linking only and provide the certificate fingerprint afterwards.
# ./insp-link.sh server1.example.com
#
#Use this to just generate the fingerprint of an existing certificate for your convenience.
# ./insp-link.sh fp some.cert.pem

genfp() {
hash="`openssl x509 -in $1 -sha256 -noout -fingerprint | cut -d'=' -f2`"
echo "The certificate fingerprint for $1 is:"
echo "$hash"
echo ""
echo "You add this to the <link> block on the other side:"
echo "fingerprint=\"$hash"\"
echo ""
}

gencert() {
openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -keyout link-key.pem -out link-cert.pem -days 1825 -sha256 -subj /CN=$1
chmod 600 link-key.pem link-cert.pem
genfp link-cert.pem
}

if [ -n "$1" ]; then
	if [ "$1" == "fingerprint" ] || [ "$1" = "fp" ]; then
		if [ -n "$2" ] && [ -f "$2" ]; then
			genfp $2
		else
			echo "The certificate you provided doesn't exist or you left the filename empty."
		fi
	else
		gencert $1
	fi
else
	echo "Syntax"
	echo ""
	echo "./insp-link.sh server1.example.com"
	echo "Generate a new SSL certificate for server linking only and provide the certificate fingerprint afterwards."
	echo ""
	echo "./insp-link.sh fp some.cert.pem"
	echo "Use this to just generate the fingerprint of an existing certificate for your convenience."
	echo ""
	echo "Change ownership afterwards if you're not running this as the same user as InspIRCd."
	echo "Ex. chown irc:irc link-cert.pem link-key.pem"
fi

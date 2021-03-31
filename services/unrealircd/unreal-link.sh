#!/bin/bash
# Generates SSL cert for server linking only and gives you the fingerprint
# Run this in your unrealircd/conf/tls/ directory
# Run this under the same user account that you are running UnrealIRCd on
# Victor Coss gtaxl@gtaxl.net
# Version 1.0 MAR/30/2021
# ./unreal-link.sh server1.example.com #Generate a new SSL certificate for server linking only and provide the SPKI fingerprint afterwards.
# ./unreal-link.sh fingerprint some.cert.pem #Use this to just generate the SPKI fingerprint of an existing certificate for your convenience.

genfp() {
openssl x509 -noout -in $1 -pubkey | openssl asn1parse -noout -inform pem -out tmplink.key
HASH="`openssl dgst -sha256 -binary tmplink.key | openssl enc -base64`"
rm -f tmplink.key
echo "The SPKI fingerprint for the certificate $1 is:"
echo "$HASH"
echo ""
echo "You add this to the link block on the other side:"
echo "password \"$HASH\" { spkifp; };"
echo ""
}

gencert() {
openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -keyout link.key.pem -out link.cert.pem -days 1825 -sha256 -subj /CN=$1
chmod 600 link.key.pem link.cert.pem
genfp link.cert.pem
}

if [ -d ~/unrealircd/conf/ssl/ ]; then
	cd ~/unrealircd/conf/ssl/
fi

if [ -d ~/unrealircd/conf/tls/ ]; then
	cd ~/unrealircd/conf/tls/
fi

if [ -n "$1" ]; then
	if [ "$1" == "fingerprint" ]; then
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
	echo "./unreal-link.sh server1.example.com"
	echo "Generate a new SSL certificate for server linking only and provide the SPKI fingerprint afterwards."
	echo ""
	echo "./unreal-link.sh fingerprint some.cert.pem"
	echo "Use this to just generate the SPKI fingerprint of an existing certificate for your convenience."
fi

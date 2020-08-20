#!/bin/bash
# Ubiquiti UniFi Controller SSL updater for Debian controllers
# For use with GTAXLnet certdeploy
# unifi-ssl.sh
# Victor Coss gtaxl@gtaxl.net
# Version 1.00 AUG/20/2020
# Credit: Steve Jenkins <http://www.stevejenkins.com/>

domain=unifi.lan.gtaxl.net

# Don't change below this line unless you know what you're doing. These are correct for Debian/Ubuntu.
contrdir=/var/lib/unifi
JAVA_DIR=/usr/lib/unifi
keystore=/var/lib/unifi/keystore
alias=unifi
password=aircontrolenterprise

cd $contrdir
systemctl stop unifi
cp $keystore $keystore.bak
openssl pkcs12 -export -in "/certdeploy/$domain/fullchain.pem" -inkey "/certdeploy/$domain/privkey.pem" -out "${contrdir}/tmpssl" -passout pass:"${password}" -name "${alias}"
keytool -delete -alias "${alias}" -keystore "${keystore}" -deststorepass "${password}"
keytool -importkeystore -srckeystore "${contrdir}/tmpssl" -srcstoretype PKCS12 -srcstorepass "${password}" -destkeystore "${keystore}" -deststorepass "${password}" -destkeypass "${password}" -alias "${alias}" -trustcacerts
rm -f $contrdir/tmpssl
systemctl start unifi
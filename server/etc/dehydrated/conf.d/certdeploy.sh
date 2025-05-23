#!/usr/bin/env bash
# Main configuration file for dehydrated (ACME client).
# For use with certdeploy_server.
# /etc/dehydrated/conf.d/certdeploy.sh
# Victor Coss <victor@openbackdoor.com>
# Version: 2025.05.15

# Which user should dehydrated run as? This will be implicitly enforced when running as root
DEHYDRATED_USER=certdeploy

# Which group should dehydrated run as? This will be implicitly enforced when running as root
DEHYDRATED_GROUP=certdeploy

# Resolve names to addresses of IP version only. (curl)
# supported values: 4, 6
# default: <unset>
IP_VERSION=4

# URL to certificate authority or internal preset
# Presets: letsencrypt, letsencrypt-test, zerossl, buypass, buypass-test
# default: letsencrypt
#CA="letsencrypt"

# Path to old certificate authority
# Set this value to your old CA value when upgrading from ACMEv1 to ACMEv2 under a different endpoint.
# If dehydrated detects an account-key for the old CA it will automatically reuse that key
# instead of registering a new one.
# default: https://acme-v01.api.letsencrypt.org/directory
#OLDCA="https://acme-v01.api.letsencrypt.org/directory"

# Which challenge should be used? Currently http-01, dns-01 and tls-alpn-01 are supported
CHALLENGETYPE="dns-01"

# Path to a directory containing additional config files, allowing to override
# the defaults found in the main configuration file. Additional config files
# in this directory needs to be named with a '.sh' ending.
# default: <unset>
#CONFIG_D=

# Directory for per-domain configuration files.
# If not set, per-domain configurations are sourced from each certificates output directory.
# default: <unset>
#DOMAINS_D=

# Base directory for account key, generated certificates and list of domains (default: $SCRIPTDIR -- uses config directory if undefined)
#BASEDIR=$SCRIPTDIR

# File containing the list of domains to request certificates for (default: $BASEDIR/domains.txt)
#DOMAINS_TXT="${BASEDIR}/domains.txt"

# Output directory for generated certificates
CERTDIR="/certdeploy/"

# Output directory for alpn verification certificates
#ALPNCERTDIR="${BASEDIR}/alpn-certs"

# Directory for account keys and registration information
#ACCOUNTDIR="${BASEDIR}/accounts"

# Output directory for challenge-tokens to be served by webserver or deployed in HOOK (default: /var/www/dehydrated)
#WELLKNOWN="/var/www/dehydrated"

# Default keysize for private keys (default: 4096)
KEYSIZE="2048"

# Path to openssl config file (default: <unset> - tries to figure out system default)
#OPENSSL_CNF=

# Path to OpenSSL binary (default: "openssl")
#OPENSSL="openssl"

# Extra options passed to the curl binary (default: <unset>)
#CURL_OPTS=

# Program or function called in certain situations
#
# After generating the challenge-response, or after failed challenge (in this case altname is empty)
# Given arguments: clean_challenge|deploy_challenge altname token-filename token-content
#
# After successfully signing certificate
# Given arguments: deploy_cert domain path/to/privkey.pem path/to/cert.pem path/to/fullchain.pem
#
# BASEDIR and WELLKNOWN variables are exported and can be used in an external program
# default: <unset>
#HOOK=

# Chain clean_challenge|deploy_challenge arguments together into one hook call per certificate (default: no)
#HOOK_CHAIN="no"

# Minimum days before expiration to automatically renew certificate (default: 30)
RENEW_DAYS="32"

# Regenerate private keys instead of just signing new certificates on renewal (default: yes)
#PRIVATE_KEY_RENEW="yes"

# Create an extra private key for rollover (default: no)
#PRIVATE_KEY_ROLLOVER="no"

# Which public key algorithm should be used? Supported: rsa, prime256v1 and secp384r1
KEY_ALGO=rsa

# E-mail to use during the registration (default: <unset>)
#CONTACT_EMAIL=

# Lockfile location, to prevent concurrent access (default: $BASEDIR/lock)
#LOCKFILE="${BASEDIR}/lock"

# Option to add CSR-flag indicating OCSP stapling to be mandatory (default: no)
#OCSP_MUST_STAPLE="no"

# Fetch OCSP responses (default: no)
#OCSP_FETCH="no"

# OCSP refresh interval (default: 5 days)
#OCSP_DAYS=5

# Issuer chain cache directory (default: $BASEDIR/chains)
#CHAINCACHE="${BASEDIR}/chains"

# Automatic cleanup (default: no)
AUTO_CLEANUP="yes"

# ACME API version (default: auto)
#API=auto

# Preferred issuer chain (default: <unset> -> uses default chain)
#PREFERRED_CHAIN=

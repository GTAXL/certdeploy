#!/usr/bin/env bash
#Cloudflare DNS hook for certdeploy (dehydrated)
#/home/certdeploy/hooks/cloudflare/hook.sh
#Victor Coss gtaxl@gtaxl.net
#Version 1.1 NOV/12/2022

####################################################################################################
############################# CONFIGURABLE OPTIONS #################################################
####################################################################################################
#More info here https://support.cloudflare.com/hc/en-us/articles/200167836-Managing-API-Tokens-and-Keys
api_token="changeme"
####################################################################################################
############################# DON'T EDIT BELOW THIS LINE ###########################################
####################################################################################################

log() {
	time=$(date --iso-8601=seconds)
	echo "$time ${@:1}" 1>&2
}

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

#Rewrites subdomains and 2nd level TLDs such as co.uk etc to zone name
#Credit @socram8888 https://github.com/socram8888
rewrite_domain() {
	local fqdn="$1"

	awk -v fqdn="$fqdn" '
		BEGIN {
			best=""
		}

		{
			# Remove comments
			gsub(/\/\/.*/, "")

			# Remove spaces
			gsub(/[ \t]/, "")

			# If blank, skip
			if (length($0) == 0)
				next

			# Add leading dot
			tld="." $0

			# Check if this new TLD is longer and matches
			if (length(tld) > length(best) && substr(fqdn, length(fqdn) - length(tld) + 1) == tld) {
				best=tld
			}
		}

		END {
			# Remove TLD
			domain=substr(fqdn, 1, length(fqdn) - length(best))

			# Remove everything before the last dot - all subdomains, that is
			gsub(/^.*\./, "", domain)

			# Print appending TLD
			print domain best
		}
	' /home/certdeploy/hooks/cloudflare/effective_tld_names.dat
}

fetch_zone_id() {
	if [ -f "/home/certdeploy/hooks/cloudflare/zoneid_$1.txt" ]; then
		log "Zone ID exists on file."
		cat /home/certdeploy/hooks/cloudflare/zoneid_$1.txt
	else
		log "Zone ID is not on file, fetching from Cloudflare's API..."
		local resp=$(curl -s -H "Authorization: Bearer ${api_token}" -H "Content-Type: application/json" "https://api.cloudflare.com/client/v4/zones?name=${1}")
		local status=$(echo $resp | jq -r ".success")
		local zoneid=$(echo $resp | jq -r ".result[0].id")
		if [ $status == "true" ] && [ $zoneid != "null" ]; then
			echo $zoneid > /home/certdeploy/hooks/cloudflare/zoneid_$1.txt
			echo $zoneid
		else
			error "Fetching Zone ID failed! Check API Token or Domain. Zone: $1"
			error "$resp"
			abort 1
		fi
	fi
}

create_acme_txt() {
	local resp=$(curl -s -H "Authorization: Bearer ${api_token}" -H "Content-Type: application/json" -X POST "https://api.cloudflare.com/client/v4/zones/${1}/dns_records" --data "{\"type\":\"TXT\",\"name\":\"_acme-challenge.${2}\",\"content\":\"${3}\",\"ttl\":\"120\"}")
	local status=$(echo $resp | jq -r ".success")
	local recordid=$(echo $resp | jq -r ".result.id")
	if [ $status == "true" ] && [ $recordid != "null" ]; then
		log "Successfully added the ACME Challenge. Record ID $recordid for $2"
		echo $recordid > /home/certdeploy/hooks/cloudflare/recordid_$2.txt
		log "Waiting 30 seconds for DNS to propagate..."
		sleep 30;
	else
		error "Failed to create ACME Challenge TXT record for $2"
		error "$resp"
		abort 1
	fi
}

delete_acme_txt() {
	local resp=$(curl -s -H "Authorization: Bearer ${api_token}" -H "Content-Type: application/json" -X DELETE "https://api.cloudflare.com/client/v4/zones/${1}/dns_records/${2}")
	local status=$(echo $resp | jq -r ".success")
	if [ $status == "true" ]; then
		log "Successfully deleted ACME TXT record, Record ID $2 for $3"
		rm /home/certdeploy/hooks/cloudflare/recordid_$3.txt
	else
		error "Failed to delete ACME TXT record, Record ID $2 for $3"
		error "$resp"
		abort 1
	fi
}

deploy_challenge() {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
	log "Deploying challenge token in DNS..."
	local zone=$(rewrite_domain $DOMAIN)
	log "Fetching Zone ID..."
	local zoneid=$(fetch_zone_id $zone)
	log "Zone ID for $zone is $zoneid"
	log "Creating ACME Challenge TXT record..."
	create_acme_txt $zoneid $DOMAIN $TOKEN_VALUE
}

clean_challenge() {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
	log "Cleaning up challenge token..."
	local zone=$(rewrite_domain $DOMAIN)
	if [ -f "/home/certdeploy/hooks/cloudflare/recordid_$DOMAIN.txt" ]; then
		local recordid=$(cat /home/certdeploy/hooks/cloudflare/recordid_$DOMAIN.txt)
		log "Fetching Zone ID..."
		local zoneid=$(fetch_zone_id $zone)
		delete_acme_txt $zoneid $recordid $DOMAIN
	else
		error "Record ID doesn't exist on file for $DOMAIN"
		abort 1
	fi
}

deploy_cert() {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"
	log "Deploying certificate. Running certdeploy.sh"
	/home/certdeploy/certdeploy.sh $DOMAIN
}

invalid_challenge() {
    local DOMAIN="${1}" RESPONSE="${2}"
	error "Validation of ${DOMAIN} failed. Response: ${RESPONSE}"
}

request_failure() {
    local STATUSCODE="${1}" REASON="${2}" REQTYPE="${3}" HEADERS="${4}"
	error "HTTP request failed. Status Code: ${STATUSCODE} Reason: ${REASON} Request Type: ${REQTYPE} Headers: ${HEADERS}"
}

startup_hook() {
	log "Begin logging from Cloudflare hook."
}

exit_hook() {
	local ERROR="${1:-}"
	if [ -z "$ERROR" ]; then
		log "End logging from Cloudflare hook."
	else
		error "$ERROR"
	fi
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_challenge|clean_challenge|deploy_cert|invalid_challenge|request_failure|startup_hook|exit_hook)$ ]]; then
  "$HANDLER" "$@"
fi

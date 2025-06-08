#!/usr/bin/env bash
# Cloudflare DNS hook for certdeploy (dehydrated ACME client)
# /usr/lib/certdeploy/dns-hooks/cloudflare/hook.sh
# Requires an API Token to be set in the certdeploy.yml config file. dns > cloudflare > api_token
# More info here https://developers.cloudflare.com/fundamentals/api/get-started/create-token/
# Licensed under the ISC License.
# (C) 2021-2025 Victor Coss <victor@openbackdoor.com>
# (C) 2017 Marcos Del Sol Vives <marcos@orca.pet>
# Version: 2025.06.08

CONFIG_FILE="/etc/certdeploy.yml" # The certdeploy configuration file to use. Only change this if you use a custom config when using this DNS hook. Example: certdeploy -c custom_config.yml

# certdeploy logging system
LOG_LEVEL=$(yq -r '.certdeploy.log_level' "${CONFIG_FILE}")

if [[ "${LOG_LEVEL}" =~ ^(debug|DEBUG)$ ]]; then
    LOG_LEVEL="debug"
elif [[ "${LOG_LEVEL}" =~ ^(normal|NORMAL)$ ]]; then
    LOG_LEVEL="norm"
elif [[ "${LOG_LEVEL}" =~ ^(error|ERROR)$ ]]; then
    LOG_LEVEL="err"
else
    LOG_LEVEL="norm"
fi

_log_debug() {
	if [[ "${LOG_LEVEL}" == "debug" ]]; then
		TIME=$(date --iso-8601=seconds)
		echo "${TIME} ${*:1}" 1>&2
		echo "${TIME} ${*:1}" 1>&2 >> /var/log/certdeploy.log
	fi
}

_log() {
	if [[ "${LOG_LEVEL}" != "err" ]]; then
		TIME=$(date --iso-8601=seconds)
		echo "${TIME} ${*:1}" 1>&2
		echo "${TIME} ${*:1}" 1>&2 >> /var/log/certdeploy.log
	fi
}

_error() {
	TIME=$(date --iso-8601=seconds)
	echo -e "[0;31m${TIME} ERROR: ${*:1}[0m" 1>&2
	echo "${TIME} ${*:1}" 1>&2 >> /var/log/certdeploy.log
	#certdeploy_smtp "remote_script ${TIME} ERROR: ${*:1}"  TODO, implement smtp e-mail sending
}

API_TOKEN=$(yq -r '.certdeploy.dns.cloudflare.api_token' "${CONFIG_FILE}") # DO NOT TOUCH THIS! DO IT WHERE YOU ARE SUPPOSED TO, IN YOUR CERTDEPLOY.YML CONFIG FILE.

if [[ -z "${API_TOKEN}" || "${API_TOKEN}" == "null" || "${API_TOKEN}" == "changeme" ]]; then
    _error "Invalid Cloudflare API token. Please set a valid token in the certdeploy config under dns > cloudflare > api_token."
    exit 1
fi

# Rewrites subdomains and 2nd level TLDs such as co.uk etc to zone name
# Function by Marcos Del Sol Vives <marcos@orca.pet> (ISC License)
_rewrite_domain() {
	local fqdn="${1}"

	awk -v fqdn="${fqdn}" '
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
	' /usr/share/publicsuffix/effective_tld_names.dat
}

_fetch_zone_id() {
	local DOMAIN
	DOMAIN="${1}"

	if [ -f "/var/lib/certdeploy/dns-hooks/cloudflare/zoneid_${DOMAIN}.txt" ]; then
		_log_debug "Zone ID exists on file."
		cat /var/lib/certdeploy/dns-hooks/cloudflare/zoneid_"${DOMAIN}".txt
	else
		_log_debug "Zone ID is not on file, fetching from Cloudflare's API..."
		local ENDPOINT RESPONSE CHECK_STATUS ZONE_ID
		ENDPOINT="https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}"
		RESPONSE=$(curl -sS -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" "${ENDPOINT}" 2>&1)

		# Check if RESPONSE contains a valid JSON response, otherwise don't run it through jq and return curl error instead.
		if jq -e . >/dev/null 2>&1 <<<"${RESPONSE}"; then
			CHECK_STATUS=$(echo "${RESPONSE}" | jq -r ".success")
		else
			CHECK_STATUS=""
		fi

		if [[ "${CHECK_STATUS}" == "true" ]]; then
			local CHECK_COUNT
			CHECK_COUNT=$(echo "${RESPONSE}" | jq -r ".result_info.count")

			if [[ "${CHECK_COUNT}" -eq 1 ]]; then
				ZONE_ID=$(echo "${RESPONSE}" | jq -r ".result[0].id")

				if [[ -n "${ZONE_ID}" && "${ZONE_ID}" != "null" ]]; then
					echo "${ZONE_ID}" > /var/lib/certdeploy/dns-hooks/cloudflare/zoneid_"${DOMAIN}".txt
					echo "${ZONE_ID}"
				else
					_error "Fetching Zone ID from Cloudflare failed for domain ${DOMAIN}."
					_error "${RESPONSE}"
					exit 1
				fi
			else
				_error "Domain ${DOMAIN} doesn't exist on Cloudflare account."
				exit 1
			fi
		elif [[ "${CHECK_STATUS}" == "false" ]]; then
			local CF_ERROR
			CF_ERROR=$(echo "${RESPONSE}" | jq -r ".errors[0].message")
			
			if [[ "${CF_ERROR}" == "Invalid request headers" || "${CF_ERROR}" == "Invalid access token" ]]; then
				_error "Invalid Cloudflare API token."
				exit 1
			else
				local CF_ERR_CODE
				CF_ERR_CODE=$(echo "${RESPONSE}" | jq -r ".errors[0].code")
				_error "Fetching Zone ID from Cloudflare failed for domain ${DOMAIN}."
				_error "Cloudflare API Response, Code: ${CF_ERR_CODE} ${CF_ERROR}"
				exit 1
			fi
		else
			_error "Fetching Zone ID from Cloudflare failed for domain ${DOMAIN}."
			_error "${RESPONSE}"
			exit 1
		fi
	fi
}

_create_acme_txt() {
	local ZONE_ID DOMAIN TOKEN_VALUE ENDPOINT PAYLOAD RESPONSE CHECK_STATUS
	ZONE_ID="${1}" DOMAIN="${2}" TOKEN_VALUE="${3}"

	ENDPOINT="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records"
	PAYLOAD=$(cat <<EOF
	{
		"type": "TXT",
		"name": "_acme-challenge.${DOMAIN}",
		"content": "\"${TOKEN_VALUE}\"",
		"ttl": 120
	}
EOF
	)

	RESPONSE=$(curl -sS -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" "${ENDPOINT}" -d "${PAYLOAD}" 2>&1)

	if jq -e . >/dev/null 2>&1 <<<"${RESPONSE}"; then
		CHECK_STATUS=$(echo "${RESPONSE}" | jq -r ".success")
	else
		CHECK_STATUS=""
	fi

	if [[ "${CHECK_STATUS}" == "true" ]]; then
		local RECORD_ID
		RECORD_ID=$(echo "${RESPONSE}" | jq -r ".result.id")

		if [[ -n "${RECORD_ID}" && "${RECORD_ID}" != "null" ]]; then
			_log_debug "Successfully added the ACME challenge to DNS. Record ID ${RECORD_ID} for ${DOMAIN}."
			echo "${RECORD_ID}" > /var/lib/certdeploy/dns-hooks/cloudflare/recordid_"${DOMAIN}".txt
			_log "Waiting 45 seconds for DNS to propagate..."
			sleep 45;
		else
			local CF_ERROR CF_ERR_CODE
			CF_ERROR=$(echo "${RESPONSE}" | jq -r ".errors[0].message")
			CF_ERR_CODE=$(echo "${RESPONSE}" | jq -r ".errors[0].code")
			_error "Failed to create ACME challenge TXT record for ${DOMAIN}."
			_error "Cloudflare API Response, Code: ${CF_ERR_CODE} ${CF_ERROR}"
			exit 1
		fi
	elif [[ "${CHECK_STATUS}" == "false" ]]; then
		local CF_ERROR CF_ERR_CODE
		CF_ERROR=$(echo "${RESPONSE}" | jq -r ".errors[0].message")
		CF_ERR_CODE=$(echo "${RESPONSE}" | jq -r ".errors[0].code")
		_error "Failed to create ACME challenge TXT record for ${DOMAIN}."
		_error "Cloudflare API Response, Code: ${CF_ERR_CODE} ${CF_ERROR}"
		exit 1
	else
		_error "Failed to create ACME challenge TXT record for ${DOMAIN}."
		_error "${RESPONSE}"
		exit 1
	fi
}

_delete_acme_txt() {
	local ZONE_ID RECORD_ID DOMAIN ENDPOINT RESPONSE
	ZONE_ID="${1}" RECORD_ID="${2}" DOMAIN="${3}"

	ENDPOINT="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}"
	RESPONSE=$(curl -sS -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" -X DELETE "${ENDPOINT}" 2>&1)

	if jq -e . >/dev/null 2>&1 <<<"${RESPONSE}"; then
		CHECK_STATUS=$(echo "${RESPONSE}" | jq -r ".success")
	else
		CHECK_STATUS=""
	fi

	if [[ "${CHECK_STATUS}" == "true" ]]; then
		_log_debug "Successfully deleted ACME TXT record, Record ID ${RECORD_ID} for ${DOMAIN}."
		rm /var/lib/certdeploy/dns-hooks/cloudflare/recordid_"${DOMAIN}".txt
	elif [[ "${CHECK_STATUS}" == "false" ]]; then
		local CF_ERROR CF_ERR_CODE
		CF_ERROR=$(echo "${RESPONSE}" | jq -r ".errors[0].message")
		CF_ERR_CODE=$(echo "${RESPONSE}" | jq -r ".errors[0].code")
		_error "Failed to delete ACME TXT record, Record ID ${RECORD_ID} for ${DOMAIN}."
		_error "Cloudflare API Response, Code: ${CF_ERR_CODE} ${CF_ERROR}"
	else
		_error "Failed to delete ACME TXT record, Record ID ${RECORD_ID} for ${DOMAIN}."
		_error "${RESPONSE}"
		exit 1
	fi
}

_deploy_challenge() {
    local DOMAIN TOKEN_FILENAME TOKEN_VALUE ZONE ZONE_ID
	DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
	_log "Deploying challenge token in DNS for ${DOMAIN}..."
	_log_debug "Token Filename for ${DOMAIN} is ${TOKEN_FILENAME}"
	_log_debug "Token Value for ${DOMAIN} is ${TOKEN_VALUE}"
	ZONE=$(_rewrite_domain "${DOMAIN}")
	_log_debug "Fetching Zone ID..."
	ZONE_ID=$(_fetch_zone_id "${ZONE}")
	_log_debug "Zone ID for ${ZONE} is ${ZONE_ID}"
	_log_debug "Creating ACME challenge TXT record..."
	_create_acme_txt "${ZONE_ID}" "${DOMAIN}" "${TOKEN_VALUE}"
}

_clean_challenge() {
    local DOMAIN TOKEN_FILENAME TOKEN_VALUE ZONE
	DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
	_log "Cleaning up challenge token..."
	ZONE=$(_rewrite_domain "${DOMAIN}")
	if [ -f "/var/lib/certdeploy/dns-hooks/cloudflare/recordid_${DOMAIN}.txt" ]; then
		local RECORD_ID ZONE_ID
		RECORD_ID=$(cat /var/lib/certdeploy/dns-hooks/cloudflare/recordid_"${DOMAIN}".txt)
		_log_debug "Fetching Zone ID..."
		ZONE_ID=$(_fetch_zone_id "${ZONE}")
		_delete_acme_txt "${ZONE_ID}" "${RECORD_ID}" "${DOMAIN}"
	else
		_error "Record ID doesn't exist on file for ${DOMAIN}."
		exit 1
	fi
}

_verify_dns() {
	local DOMAIN ZONE ZONE_ID TOKEN_VALUE ENDPOINT PAYLOAD RESPONSE CHECK_STATUS
	DOMAIN="${1}"
	_log "Testing authorization to DNS provider Cloudflare..."
	ZONE=$(_rewrite_domain "${DOMAIN}")
	_log_debug "Fetching Zone ID..."
	ZONE_ID=$(_fetch_zone_id "${ZONE}")
	_log_debug "Zone ID for ${ZONE} is ${ZONE_ID}"
	TOKEN_VALUE=$(openssl rand -base64 48 | tr -d '/+=' | cut -c1-64)

	ENDPOINT="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records"
	PAYLOAD=$(cat <<EOF
	{
		"type": "TXT",
		"name": "_certdeploy-test.${DOMAIN}",
		"content": "\"${TOKEN_VALUE}\"",
		"ttl": 120
	}
EOF
	)

	RESPONSE=$(curl -sS -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" "${ENDPOINT}" -d "${PAYLOAD}" 2>&1)

	if jq -e . >/dev/null 2>&1 <<<"${RESPONSE}"; then
		CHECK_STATUS=$(echo "${RESPONSE}" | jq -r ".success")
	else
		CHECK_STATUS=""
	fi

	if [[ "${CHECK_STATUS}" == "true" ]]; then
		local RECORD_ID
		RECORD_ID=$(echo "${RESPONSE}" | jq -r ".result.id")

		if [[ -n "${RECORD_ID}" && "${RECORD_ID}" != "null" ]]; then
			local DATE
			_log_debug "Successfully added the test TXT record to DNS. Record ID ${RECORD_ID} for ${DOMAIN}."
			echo "SUCCESS"
			echo "${RECORD_ID}" > /var/lib/certdeploy/dns-hooks/cloudflare/recordid_"${DOMAIN}".txt
			DATE=$(date +%F)
			echo "${DATE}" > /var/lib/certdeploy/dns-hooks/cloudflare/verify.txt
			sleep 45;
			_delete_acme_txt "${ZONE_ID}" "${RECORD_ID}" "${DOMAIN}"
		else
			local CF_ERROR CF_ERR_CODE
			CF_ERROR=$(echo "${RESPONSE}" | jq -r ".errors[0].message")
			CF_ERR_CODE=$(echo "${RESPONSE}" | jq -r ".errors[0].code")
			_error "Failed to create test TXT record with Cloudflare for domain ${DOMAIN}."
			_error "Cloudflare API Response, Code: ${CF_ERR_CODE} ${CF_ERROR}"
			echo "FAILED"
			exit 1
		fi
	elif [[ "${CHECK_STATUS}" == "false" ]]; then
		local CF_ERROR CF_ERR_CODE
		CF_ERROR=$(echo "${RESPONSE}" | jq -r ".errors[0].message")
		CF_ERR_CODE=$(echo "${RESPONSE}" | jq -r ".errors[0].code")
		_error "Failed to create test TXT record with Cloudflare for domain ${DOMAIN}."
		_error "Cloudflare API Response, Code: ${CF_ERR_CODE} ${CF_ERROR}"
		echo "FAILED"
		exit 1
	else
		_error "Failed to create test TXT record with Cloudflare for domain ${DOMAIN}."
		_error "${RESPONSE}"
		echo "FAILED"
		exit 1
	fi
}

_check_dns_provider() {
	local DOMAIN DATE
	DOMAIN="${1}"
	DATE=$(date +%F)

	if [[ -f "/var/lib/certdeploy/dns-hooks/cloudflare/verify.txt" ]]; then
		local FILE_DATE
		FILE_DATE=$(cat "/var/lib/certdeploy/dns-hooks/cloudflare/verify.txt")
		if [[ "${FILE_DATE}" == "${DATE}" ]]; then
			echo "SUCCESS"
		else
			_verify_dns "${DOMAIN}"
		fi
	else
		_verify_dns "${DOMAIN}"
	fi
}

_deploy_cert() {
    local DOMAIN
	DOMAIN="${1}"
	_log "Certificate for ${DOMAIN} successfully generated. Handing off to certdeploy for final deployment."
	certdeploy deploy "${DOMAIN}"
}

_invalid_challenge() {
    local DOMAIN RESPONSE
	DOMAIN="${1}" RESPONSE="${2}"
	_error "Validation of domain ${DOMAIN} failed. Response: ${RESPONSE}"
}

_request_failure() {
    local STATUSCODE REASON REQTYPE HEADERS
	STATUSCODE="${1}" REASON="${2}" REQTYPE="${3}" HEADERS="${4}"
	_error "HTTP request failed. Status Code: ${STATUSCODE} Reason: ${REASON} Request Type: ${REQTYPE} Headers: ${HEADERS}"
}

_startup_hook() {
	_log_debug "Begin logging from Cloudflare DNS hook."
}

_exit_hook() {
	local ERROR
	ERROR="${1:-}"
	if [ -z "${ERROR}" ]; then
		_log_debug "End logging from Cloudflare DNS hook."
	else
		_error "${ERROR}"
	fi
}

HANDLER="${1}"; shift
if [[ "${HANDLER}" =~ ^(deploy_challenge|clean_challenge|deploy_cert|invalid_challenge|request_failure|startup_hook|exit_hook|check_dns_provider)$ ]]; then
  "_${HANDLER}" "${@}"
fi

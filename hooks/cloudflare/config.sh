global_api_key="replaceme"
email="example@gtaxl.net"

domainapi=${1#${1%.*.*}.} 

case "$domainapi" in
	example.com)
		zones="apikey01"
	;;

	anotherdomain.net)
		zones="apikey02"
	;;

	thisserver.com)
		zones="apikey03"
	;;

esac

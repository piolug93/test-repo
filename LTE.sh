#!/bin/bash
function token {
	DATA=`curl http://192.168.8.1/api/webserver/SesTokInfo`
	SID=`echo "$DATA" | grep "SessionID=" | cut -b 10-147`
	TOKEN=`echo "$DATA" | grep "TokInfo" | cut -b 10-41` 
}

function ChangeNetworkMode {
	tryb=""
	case $1 in
		LTE)
		tryb="03"
		echo "$tryb"
		;;
		LTE_UMTS)
		tryb="0302"
		;;
	esac
	token
	curl http://192.168.8.1/api/net/net-mode -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><NetworkMode>'$tryb'</NetworkMode><NetworkBand>3FFFFFFF</NetworkBand><LTEBand>7FFFFFFFFFFFFFFF</LTEBand></request>' 
}

function SwitchData {
	token
	curl http://192.168.8.1/api/dialup/mobile-dataswitch -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><dataswitch>'$1'</dataswitch></request>' 
}

function SendSMS {
	token
	curl http://192.168.8.1/api/sms/send-sms -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Index>-1</Index><Phones><Phone>'$1'</Phone></Phones><Sca></Sca><Content>'$2'</Content><Length>4</Length><Reserved>1</Reserved><Date>2017-12-22 17:01:49</Date></request>'
}
# dopisać zmianę na UMTS
function StateLTE {
	token
	curl http://192.168.8.1/api/ussd/send -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<request><content>*111*480*3#</content><codeType></codeType><timeout>5</timeout></request>'
	sleep 5
	token
	respond=`curl http://192.168.8.1/api/ussd/get -b "$SID" -H "__RequestVerificationToken: $TOKEN" | grep "content" | sed -e 's/<[^>]*>//g' | head -n1`
	if [ "$respond" == "Usluga wlaczona" ]
		then
		echo "Wlaczona OK"
	elif [ "$respond" == "Usluga wylaczona" ]
		then
		echo "Wylczona, zle"
		#SendSMS "nr_tel" "tresc"
	else
		echo 'Blad: ' $wynik
	fi
}

function SendUSSD {
	SwitchData "0"
	ChangeNetworkMode "LTE_UMTS"
	token
	curl http://192.168.8.1/api/ussd/send -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<request><content>'$1'</content><codeType></codeType><timeout>5</timeout></request>'
	sleep 5
	ChangeNetworkMode "LTE"
	SwitchData "1"
}

function ActivateFreeLTE {
	SendUSSD "*111*480*1"
}


ActivateFreeLTE
sleep 5
StateLTE
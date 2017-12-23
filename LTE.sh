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
		;;
		LTE_UMTS)
		tryb="0302"
		;;
	esac
	token
	T=`curl http://192.168.8.1/api/net/net-mode -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><NetworkMode>'$tryb'</NetworkMode><NetworkBand>3FFFFFFF</NetworkBand><LTEBand>7FFFFFFFFFFFFFFF</LTEBand></request>'`
}

function SwitchData {
	token
	T=`curl http://192.168.8.1/api/dialup/mobile-dataswitch -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><dataswitch>'$1'</dataswitch></request>'`
}

function SendSMS {
	token
	curl http://192.168.8.1/api/sms/send-sms -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Index>-1</Index><Phones><Phone>'$1'</Phone></Phones><Sca></Sca><Content>'$2'</Content><Length>4</Length><Reserved>1</Reserved><Date>2017-12-22 17:01:49</Date></request>'
}

function StateLTE {
	SendUSSD "*111*480*3#"
	sleep 5
	respond=`GetUSSD | grep "content" | sed -e 's/<[^>]*>//g' | head -n1 | cut -c 3-18` 
	echo "$respond"
	if [ "$respond" == 'Usluga wlaczona ' ]
		then
		echo "Wlaczona OK"
	elif [ "$respond" == "Usluga wylaczona" ]
		then
		echo "Wylaczona, zle"
		#SendSMS "nr_tel" "tresc"
	else
		echo 'Blad'
	fi
}

function GetUSSD {
	SwitchData "0"
	ChangeNetworkMode "LTE_UMTS"
	sleep 2
	token
	get=`curl http://192.168.8.1/api/ussd/get -b "$SID" -H "__RequestVerificationToken: $TOKEN"`
	ChangeNetworkMode "LTE"
	SwitchData "1"
	echo $get
}

function SendUSSD {
	SwitchData "0"
	ChangeNetworkMode "LTE_UMTS"
	token
	sleep 2
	T=`curl http://192.168.8.1/api/ussd/send -b "$SID" -H "__RequestVerificationToken: $TOKEN" --data-binary $'<request><content>'$1'</content><codeType></codeType><timeout>5</timeout></request>'`
	#ChangeNetworkMode "LTE"
	#SwitchData "1"
}

function ActivateFreeLTE {
	SendUSSD "*111*480*1"
}


#ActivateFreeLTE
StateLTE

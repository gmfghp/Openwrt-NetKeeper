#!/bin/sh

#start pppoe-server
if [ -n "$(ps | grep pppoe-server | grep -v grep)" ]
then
    killall pppoe-server
fi
pppoe-server -k -I br-lan

#clear logs
cat /dev/null > /tmp/pppoe.log

while :
do
    #read the last username in pppoe.log
    var=$(grep 'user=' /tmp/pppoe.log | grep 'rcvd' | tail -n 1)
    name=${var#*'"'}
    username=${name%'" password="'*}
    word=${var#*'" password="'}
    password=${word%'"'*}

    if [ "$username" != "$username_old" ]
    then
        ifdown netkeeper
        uci set network.netkeeper.username="$username"
        uci set network.netkeeper.password="$password"
        uci commit
        ifup netkeeper
        username_old="$username"
        logger -t nk4 "new username $username"
    fi
    sleep 10

    #close pppoe if log fail
    if [ -z "$(ifconfig | grep "netkeeper")" ]
    then
        ifdown netkeeper
    else
	sleep 50
    fi
    	
	#clear logs everyday
	if [ "$(date '+%T' | cut -b 1-4)" == "00:0" ]
	then
		cat /dev/null > /tmp/pppoe.log
		sleep 10
		echo "$var" >> /tmp/pppoe.log
		sleep 10
	fi

done

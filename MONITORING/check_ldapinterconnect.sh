#! /bin/bash
## PvSA 7.2.23, add parameter to manage count of check failures until error
## PvSA 9.8.23 adjust split namp scan to dns, ping und port check
#set -x

LDAPCONFS="$1"
ERRCOUNT=$2
BLOCKFILE="/tmp/check_ldapinterconnect.block"
WAIT=5


# abort if block file exists
if [ -e $BLOCKFILE ]; then
	exit 1
fi

if [ -e check_ldapinterconnect_vars ]; then
	source check_ldapinterconnect_vars
else
	echo "source file check_ldapinterconnect_vars not exists in $PWD"
	echo check_ldapinterconnect_vars > $BLOCKFILE
	exit 1
fi

if [ $ZBXSRVINTERN == "" ] && [ $ZBXSRVEXTERN == "" ]; then
        echo "at least one zbx host must be specified"
        echo zbxhost > $BLOCKFILE
        exit 1
fi

if [ $ZBXKEY == "" ] || [ ! $ZBXPORT ]; then
        echo "zbx key and port needed"
        echo zbxkeyport > $BLOCKFILE
        exit 1
fi

if [ $LDAPWHO == "" ] || [ $LDAPWHOPW == "" ]; then
        echo "ldap host and password must be specified"
        echo ldap > $BLOCKFILE
        exit 1
fi



# check if ldapwhoami exists
if [ ! $(which ldapwhoami) ]; then
	echo "programm ldapwhoami does not exist. Exiting and set block file $BLOCKFILE to avoid further execution"
	echo ldapwhoami > $BLOCKFILE
	exit 1
fi
# check if app host exists
if [ ! $(which host) ]; then
	echo "programm host does not exist. Exiting and set block file $BLOCKFILE to avoid further execution"
	echo host > $BLOCKFILE
	exit 1
fi
# check if app nc exists
if [ ! $(which nc) ]; then
	echo "programm nc (netcat) does not exist. Exiting and set block file $BLOCKFILE to avoid further execution"
	echo nc > $BLOCKFILE
	exit 1
fi




LDAPLIST=$(cat $LDAPCONFS| egrep '.*ldap[0-9]*\.p.*net' |egrep -v "^#.*" |egrep -v "^//" |sed "s/\ /\n/g" |egrep '.*ldap[0-9]*\.p.*net' | sed 's/;//g'| sed "s/'//g" |sort |uniq)

for LDAPURL in $LDAPLIST; do
        LDAPPROTO="$(echo "$LDAPURL" | awk '{split($0,url,":"); print url[1]}')"
        LDAPHOST="$(echo "$LDAPURL" | awk '{split($0,url,":"); print url[2]}'| sed "s/\///g" )"

        # run check with nmap
        if [ "$LDAPPROTO" == "ldaps" ]; then
                LDAPPORT=636
        else
                LDAPPORT=389
        fi


	if ldapwhoami -H "$LDAPURL" -x -D "$LDAPWHO" -w "$LDAPWHOPW" 1>/dev/null 2>&1 ; then
                CHECK=OK
        else
		if [ $ERRCOUNT ] && [ $ERRCOUNT -gt 1 ]; then
			x=1
			while [ $x -lt $ERRCOUNT ]; 
			do
				if ldapwhoami -H "$LDAPURL" -x -D "$LDAPWHO" -w "$LDAPWHOPW" 1>/dev/null 2>&1 ; then 
					CHECK=OK
					x=$ERRCOUNT
				else
					CHECK=ERROR
				fi
				x=$(( $x + 1 ))
			done
		else
	                CHECK=ERROR
			# Check details DNS
			if host $LDAPHOST  2>&1 > /dev/null ;then
				DNSINFO="DNS=OK"
			else
				DNSINFO="DNS=NOK"
			fi
			# check details Ping
			if ping -c 3 $LDAPHOST  2>&1 > /dev/null ;then
				IPINFO="PING=OK"
			else
				IPONFO="PING=NOK"
			fi
			# check details port scan
			if nc -z $LDAPHOST $LDAPPORT 2>&1 > /dev/null ;then
				PINFO="PORT=OK"
			else
				PINFO="PORT=NOK"
			fi
		fi
        fi

        RESULT+="$(echo $LDAPURL $CHECK $DNSINFO $IPINFO $PINFO); "
        sleep $WAIT
done

# remove blockfile when script works until here
rm -f $BLOCKFILE

# print result to stdout with debug flag
if [ "$3" == "-d" ]; then
        echo "$RESULT"
fi


if nc -z "$ZBXSRVEXTERN" $ZBXPORT ; then
        zabbix_sender -z $ZBXSRVEXTERN -p 10051 -s "$(hostname -s)" -k "$ZBXKEY" -o "$RESULT" >/dev/null
else
        zabbix_sender -z $ZBXSRVINTERN -p 10051 -s "$(hostname -s)" -k "$ZBXKEY" -o "$RESULT" >/dev/null

fi


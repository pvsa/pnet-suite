#! /bin/bash
## PvSA 7.2.23, add parameter to manage count of check failures until error

#set -x

LDAPCONFS="$1"
ERRCOUNT=$2
ZBXSRVINTERN=""
ZBXSRVEXTERN=""
ZBXKEY="LDAP-Interconnect"
ZBXPORT=10051
LDAPWHO=''
LDAPWHOPW=''
WAIT=5

## check for parameter set
if [ "$1" = "" ]; then
  echo "USAGE: check_ldapinterconnect.sh CONFIG-FILE-WITH-LDAPHOSTS [MAX-RETRY]"
  echo "e.g. check_ldapinterconnect.sh /etc/postfix/ldap-user.cf 2"
  exit 1
fi

if [ "$ZBXSRVINTERN" = ""] || [ "$ZBXSRVEXTERN" = "" ] || [ "$LDAPWHO" = "" ] || [ "$LDAPWHOPW" = "" ]; then
  echo "Not all needed variables set:"
  echo "ZBXSRVINTERN = $ZBXSRVINTERN"
  echo "ZBXSRVEXTERN = $ZBXSRVEXTERN"
  echo "LDAPWHO = $LDAPWHO"
  echo "LDAPWHOPW = $LDAPWHOPW"
  echo "please check script file head. Exiting"
  exit 1
fi

#get ldap-server configured in LDAPCONFS
#LDAPLIST=$(cat $LDAPCONFS| egrep '.*ldap[0-9]*\.p.*net' |egrep -v "^#.*" |egrep -v "^\/\/" |sed "s/\ /\n/g" |egrep '.*ldap[0-9]*\.p.*net' | sed 's/;//g'| sed "s/'//g" |sort |uniq)
LDAPLIST=$(cat $LDAPCONFS| egrep '.*ldap[0-9]*\.p.*net' |egrep -v "^#.*" |egrep -v "^//" |sed "s/\ /\n/g" |egrep '.*ldap[0-9]*\.p.*net' | sed 's/;//g'| sed "s/'//g" |sort |uniq)

for LDAPURL in $LDAPLIST; do
        #echo "ldapurl: $LDAPURL"
       LDAPPROTO="$(echo "$LDAPURL" | awk '{split($0,url,":"); print url[1]}')"
        LDAPHOST="$(echo "$LDAPURL" | awk '{split($0,url,":"); print url[2]}'| sed "s/\///g" )"

        # run check with nmap
        if [ "$LDAPPROTO" == "ldaps" ]; then
                LDAPPORT=636
        else
                LDAPPORT=389
        fi

        #LDAPCHECK=$(nmap -sV -p$LDAPPORT $LDAPHOST)
        #if echo "$LDAPCHECK" |grep "Anonymous bind OK" 1>/dev/null; then
        #LDAPCHECK=$(nc -z $LDAPHOST $LDAPPORT)
        #if nc -z $LDAPHOST $LDAPPORT ; then
        # if ERRCOUNT not applicated, just do one
	if ldapwhoami -H "$LDAPURL" -x -D "$LDAPWHO" -w "$LDAPWHOPW" 1>/dev/null; then
                CHECK=OK
        else
		if [ "$ERRCOUNT" != "" ] && [ $ERRCOUNT -gt 1 ]; then
			x=1
			while [ $x -lt $ERRCOUNT ];
			do
				if ldapwhoami -H "$LDAPURL" -x -D "$LDAPWHO" -w "$LDAPWHOPW" 1>/dev/null ; then
					CHECK=OK
					x=$ERRCOUNT
				else
					CHECK=ERROR
				fi
				x=$(( $x + 1 ))
			done
		else
	                CHECK=ERROR
        	        #echo "$LDAPCHECK"
                	echo "$LDAPURLNORM Check failed"
			nmap -p$LDAPPORT $LDAPHOST
		fi
        fi

        RESULT+="$(echo $LDAPURL $CHECK); "
        sleep $WAIT
done

#echo "$RESULT"

if nc -z "$ZBXSRVEXTERN" $ZBXPORT ; then
        zabbix_sender -z $ZBXSRVEXTERN -p 10051 -s "$(hostname -s)" -k "$ZBXKEY" -o "$RESULT" >/dev/null
else
        zabbix_sender -z $ZBXSRVINTERN -p 10051 -s "$(hostname -s)" -k "$ZBXKEY" -o "$RESULT" >/dev/null

fi

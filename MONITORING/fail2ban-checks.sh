#!/bin/bash

jailconf="/etc/fail2ban/jail.local"

# check for zabbix_sender
if ! $(which zabbix_sender >/dev/null); then
        echo "program zabbix_sender not available"
        exit 1
fi

# find zabbix-agent version
if $(pgrep -u zabbix -l |grep agent2 >/dev/null); then
        ZBXAGENT="zabbix_agent2"
else
        ZBXAGENT="zabbix_agentd"
fi




fail2banclient=$(command -v fail2ban-client)

# 1. Prüfung: ist fail2ban-client installiert
if [ -x "$fail2banclient" ]; then
    clientstatus="OK"
else
    clientstatus="ERROR"
fi

# 2. Ping-Test
if [ "$clientstatus" = "OK" ]; then
    serverstatus="$($fail2banclient ping 2>&1 | grep -q "pong" && echo "OK" || echo "ERROR")"
else
    serverstatus="ERROR"
fi



# 2. Jails auslesen, Sektion [DEFAULT] ausnehmen
jails=$(grep '^\[' "$jailconf" | sed 's/\[//;s/\]//' | grep -v '^DEFAULT$')
statusline=""

for jail in $jails; do
    # Prüfen, ob Jail aktiviert ist
    if grep -A5 "^\[$jail\]" "$jailconf" | grep -q "enabled *= *true"; then
        jailactive=$($fail2banclient status | grep "Jail list:" | grep -Eo "[^:]+$" | grep -o "\b$jail\b")
        if [ -n "$jailactive" ]; then
            status="OK"
        else
            status="ERROR"
        fi
        statusline="${statusline}${jail}: ${status}, "
    fi
done

failed_total=0
banned_total=0

for jail in $jails; do
    if grep -A5 "^\[$jail\]" "$jailconf" | grep -q "enabled *= *true"; then
        jailactive=$($fail2banclient status | grep "Jail list:" | grep -Eo "[^:]+$" | grep -o "\b$jail\b")
        if [ -n "$jailactive" ]; then
            # Holen der Statuswerte für die Jail
            jailstatus="$($fail2banclient status "$jail")"
            failed=$(echo "$jailstatus" | grep "Currently failed" | awk -F: '{print $2}' | tr -d ' ')
            banned=$(echo "$jailstatus" | grep "Currently banned" | awk -F: '{print $2}' | tr -d ' ')
            failed_total=$((failed_total + failed))
            banned_total=$((banned_total + banned))
        fi
    fi
done

#echo "System - Client: $clientstatus, Server: $serverstatus"
#echo "Jails - ${statusline%, }"
#echo "Currently failed: $failed_total"
#echo "Currently banned: $banned_total"

#f2bsys
# push f2b-client installed + ping/pong
zabbix_sender -c /etc/zabbix/$ZBXAGENT.conf -k "f2bsys" -o "System - Client: $clientstatus, Server: $serverstatus" >/dev/null

# push jails status 
zabbix_sender -c /etc/zabbix/$ZBXAGENT.conf -k "f2bjails" -o "Jails - ${statusline%, }" >/dev/null

# push failed & banne count 
zabbix_sender -c /etc/zabbix/$ZBXAGENT.conf -k "f2bcurfail" -o "$failed_total" >/dev/null
zabbix_sender -c /etc/zabbix/$ZBXAGENT.conf -k "f2bcurbann" -o "$banned_total" >/dev/null

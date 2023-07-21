#! /bin/bash
### BEGIN INIT INFO
# Provides:		iptables
# Required-Start:	networking
# Required-Stop:
# Default-Start:        2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:    PORG Server Firewall
### END INIT INFO

# nichts, help oder dpg
if [ "$1" = "-h" ]; then
        echo "/etc/init.d/firewall [-d] "
        echo "Loads /etc/firewall"
        echo "-h : This help"
        echo "-d : Debug (set -x)"
        exit 1
elif [ "$1" = "-d" ]; then
        OPT="dbg"
else
        OPT="none"
fi

/etc/firewall $OPT


if [ "$?" = "0" ]; then
        echo -e -n "\033[1;32m"
        echo ">>>>>>>>> IPTables SUCCESSFUL (Re-)LOADED <<<<<<<<<<"
else
        echo -e -n "\033[1;33m"
        echo ">>>>>>>>> IPTables (Re-)LOADED WITH ERRORS <<<<<<<<<<"
fi

# disable echo-farbe
echo -e -n "\033[0m"
echo -E -n


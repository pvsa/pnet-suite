#! /bin/bash
## PvSa, 13.11.09:
# variablen am anfang fuer spaetere anpassung
# pbackup 
# ntp, update-check, mail (postfix)
# postfix + paladin
# rh/deb kompatibel
##
# PvSA, 15.4.10: Umstellung zip -> tar.gz
# PvSA, 16.4.10: pnet-ssl ausgelagert
# PvSA, 4.10.2010: PNET und allg. getrennt
# PvSA, 11.10.10: Bugfixing, webmin rh, sh -> bash
# PvSA, 4.7.11: rh - securitylevel Befehl korrigieren
#	gen. Logs einbauen, traceroute anstattt tcptraceroute bei rh
###
# TODO:
# Updates pruefen -> install_start.sh --update ?
# 	oder als unterfunktion innerhlab der befehle
# Tools (netwatch,pbackup...)Ordner separat
# Tools unterschieden zwischen root/non-root (whoami) -> /usr/local/bin


### DEBUG
# set -x
###


#############
## VARS
# Server from Install-packages came from
ISRV="ftp.pilarkto.net"
PROTO="ftp"
IUSR="anonymous"
IPW=""
IURL="$PROTO://$IUSR:$IPW@$ISRV/pub/pnet-suite/"
# Server to install packages (where you execute the script)
HERES=`hostname`
HEREF=`hostname -f`
HOMEDOM="example.com"
RSCRIPT="/root/Scripts"

## OS select
# DEB/Ubuntu
test -e /etc/apt/sources.list
if [ $? = 0 ]; then
OS="deb"
PM="apt-get"
PM_OPT="-y -q install" 
#GWIP="route -n|sort|head -n 1|cut -c 17-30"
PINST="dpkg -i"
UPRC="update-rc.d"
SED="sed -i"
ECHO="echo -e"
WGET="wget -nv"
fi

# RH/Centos
test -e /etc/yum.conf
if [ $? = 0 ]; then
OS="rh"
PM="yum"
PM_OPT="-y install" 
#GWIP="route -n|sort|head -n 1|cut -c 17-30"
PINST="rpm -Uh"
UPRC="chkconfig"
SED="sed -i"
ECHO="echo -e"
WGET="wget -nv"
fi

## INFO
$ECHO "INSTALL START Skript v2 (PNET) [PvSA@PNET - 08.10.2011]"
$ECHO "------------------------------------------------------"
$ECHO "PNET Standard-Install-Routine (Debian/Ubuntu/CentOS/RedHat)"
$ECHO "install_start.sh admin@example.org"
$ECHO "------------------------------------------------------"
$ECHO "======================================================"
$ECHO "HOSTNAME (FQDN) SETIINGS MUST APLIED ! Hostname Test: `hostname -f` "
$ECHO "[Enter=OK, Strg+C=Cancel]"
read STOP
##

## Start
$ECHO "\033[1;33m  - $HOMEDOM !!
This script must be run with root privileges 

	Server from install: >> $ISRV << 
	Server to install: >> $HEREF <<

[Enter=OK/ Strg+C=Cancel] \033[0m"
read STOP

## Install-Server online ?
$ECHO -e "\033[1;40m Install-Server Check \033[0m"
ping -q -c 3 $ISRV
$ECHO ""

if [ $? != 0 ]; then
	$ECHO "Installation Server not responding. Is network working ?"
	exit 1
else    $ECHO "Server: $ISRV  is Online !"
fi

$ECHO ""
## Abfrage der Paramter ohne "-s"
if [ "$1" != "-s" ];then
	if [ "$1" = "" ];then
		$ECHO "Please specify the admin/paladin (email) for this 
server"
		read PAL
	else PAL="$1"
		$ECHO "PALADIN IS: >> $1 <<"
	fi
fi
## Parameter mit "-s"
if [ "$1" = "-s" ];then
	if [ "$2" = "" ];then
		$ECHO "Please specify the admin/paladin for this server"
		read PAL
	else PAL="$2"
		$ECHO "PALADIN IS: >> $2 <<"
	fi
fi

$ECHO ""

## apt update
$ECHO "\033[1;40m Update Instalation Repositories \033[0m"
$PM update


## ROOT DIR
cd /root/

## ssh
$ECHO "\033[1;40m SSH... \033[0m"
if [ "$OS" = "deb" ];then
	$PM $PM_OPT ssh
else
	$PM $PM_OPT openssh-server
fi

## screen & lynx & joe & less
$ECHO "\033[1;40m SCREEN LYNX JOE LESS \033[0m"
$PM $PM_OPT screen lynx joe less unzip gzip bzip2 mlocate nano

# traceroute & nmap & ntpdate
$ECHO "\033[1;40m TRACEROUTE NMAP \033[0m"
$PM $PM_OPT traceroute nmap
if [ "$OS" = "deb" ]; then
	$PM $PM_OPT tcptraceroute
fi
$PM $PM_OPT ntpdate

# Bootlog aktivieren
# kann man auch mit sed machen
$ECHO "\033[1;40m Bootlog Service \033[0m"

if [ "$OS" = "deb" ];then
	cp -f /etc/default/bootlogd /etc/default/bootlogd_OLD
	$ECHO >> /etc/default/bootlogd
	$ECHO "# Run bootlogd at startup ?" >> /etc/default/bootlogd
	$ECHO "BOOTLOGD_ENABLE=YES" >> /etc/default/bootlogd
	$UPRC bootlogd defaults
fi

if [ "$OS" = "rh" ];then
	cd /etc/init.d
	$ECHO "#! /bin/sh" >> bootmsg
	$ECHO "dmesg >> /var/log/boot.msg" >> bootmsg
	chmod u+x /etc/init.d/bootmsg
	$UPRC bootmsg
fi


## ROOT Scripts
# Also nur fuer User root
mkdir -p $RSCRIPT
mkdir -p /etc/cron.d/
cd $RSCRIPT

## log.*
$ECHO "\033[1;40m log.* Scripts... \033[0m"
#$WGET -O log.tar.gz "$IURL/LOG/log_$OS.tar.gz"
#tar -xf log.tar.gz
#rm log.tar.gz
wget "$IURL/LOG/log.*"
chmod 750 log.*
ln -sf $RSCRIPT/log.* /usr/local/sbin/



# PBackup
$ECHO "\033[1;40m PBackup \033[0m"
$WGET "$IURL/INSTALL_START/pbackup"
chmod 750 pbackup
ln -sf $RSCRIPT/pbackup /usr/local/sbin/

# NTP
$ECHO "\033[1;40m NTP \033[0m"
$WGET "$IURL/INSTALL_START/NTP"
chmod 750 NTP
ln -sf $RSCRIPT/NTP /etc/cron.hourly/
ln -sf $RSCRIPT/NTP /etc/cron.d/

# Netwatch
$ECHO "\033[1;40m NetWatch \033[0m"
$WGET "$IURL/INSTALL_START/netwatch"
chmod 750 netwatch
ln -sf $RSCRIPT/netwatch /usr/local/sbin/


# APT Check
if [ "$OS" = "deb" ];then
$ECHO "\033[1;40m APT Check \033[0m"
	$ECHO "apt-check for paladin"
	echo "#! /bin/sh" >>  update-check
	echo "SERVER=`hostname`" >>  update-check
	echo "$PM -qq update" >>  update-check
	echo "$PM -suV upgrade | mail -s \"\$SERVER: Ausstehende Updates\" paladin" >>  update-check
	chmod 700 update-check
	ln -sf $RSCRIPT/update-check /etc/cron.weekly/
	ln -sf $RSCRIPT/update-check /etc/cron.d/
fi

# POSTFIX
$ECHO "\033[1;40m Mail - Smarthost(?)(Postfix) \033[0m"
if [ "$OS" = "deb" ];then
	$ECHO "Postfix & mailutils & mutt"
	TST=`dpkg -l|grep -c "postfix "`
	if [ $TST = 0 ]; then
		$PM $PM_OPT postfix
	else
	$ECHO -e "\033[1;33m Postfix is allready installed. 
	Run \"dpkg-reconfigure postfix\" to reconfigure 
	with smarthost (smtp.$HOMEDOM). \033[0m"
	fi
	$ECHO "paladin: $PAL" >> /etc/aliases
	postalias /etc/aliases
	$PM $PM_OPT mailutils mutt
	
elif [ "$OS" = "rh" ];then 
	$ECHO "Postfix & mailx & mutt"
	rpm -q postfix > /dev/null 2>&1
	if [ $? != 0 ]; then
		$PM $PM_OPT postfix
	else
	$ECHO -e "\033[1;33m Postfix is allready installed. \033[0m"
	fi
	$ECHO "paladin: $PAL" >> /etc/aliases
	postalias /etc/aliases
	$PM $PM_OPT mailx mutt
fi
	date && $ECHO "
	Hi,

	$HEREF is online. 
	
	Some scripts are installed to /root/Scripts and linked to 
desired location:
	You can use log.all, log.mail, log.web to read log files live.
	A Admin-User \"paladin\" is installed for mail-warnings.
	Network-Time and apt-checks are activatet for cron-Daemon.

	Also pbackup for backing up specific folder [ pbackup /folder ].
	Webmin, ssh, Networking-Tools and some Editors (joe, less, lynx) 
	and some more useful tools are also installed.
	
	Messages at boot time are loged to /var/log/bootmsg.
	


	Your $HOMEDOM install_start-Script "| mail -s "$HEREF: Start-Skript installed " paladin
	log.mail

	
#BASH Shortcuts and color
sed -e "s/#alias ll='ls -l'/alias ll='ls -l'/" -i /root/.bashrc


## END
$ECHO "DONE. Enjoy !"


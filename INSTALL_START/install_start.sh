#! /bin/bash
# Warnung: Bezieht sich nur auf Debian/Ubuntu Systeme
## PvSa, 13.11.09:
# variablen am anfang fuer spaetere anpassung
# pbackup 
# ntp, update-check, mail
# postfix + paladin (untested)
# rh/deb kompatibel
# ssl-cert: ca-certificates install, privkey und csr erstellen -> cacert ...
# ssl_config 
# http://tutorials.ludwig.im/cacert-zertifikat-erstellen-oder-aktualisieren/
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
PM_OPT="-y install" 
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
PINST="rpm -Uvh"
UPRC="chkconfig"
SED="sed -i"
ECHO="echo -e"
WGET="wget -nv"
fi

## INFO
$ECHO "INSTALL START Skript v2 (PNET) [PvSA@PNET - 27.03.2010]"
$ECHO "------------------------------------------------------"
$ECHO "PNET Standard-Install-Routine (Debian/Ubuntu/CentOS/RedHat)"
$ECHO "install_start.sh admin@example.org"
$ECHO "install_start.sh -s admin@example.org => ... with SSL Cert"
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

## webmin
$ECHO "\033[1;40m  WEBMIN...(this may take some time) \033[0m"
if [ "$OS" = "deb" ];then
	mkdir -p Webmin
	cd Webmin
	$WGET http://www.webmin.com/download/deb/webmin-current.deb
	$PM $PM_OPT -f perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl libmd5-perl
	$PINST webmin*.deb
	#zur sicherheit (apt-get -f install)
	$PM -f $PM_OPT 
	/etc/init.d/webmin stop && sleep 5
	cp /etc/webmin/miniserv.conf /etc/webmin/miniserv.conf_OLD
	/etc/init.d/webmin start
	cd ~

elif [ "$OS" = "rh" ];then
    echo "[Webmin]" >> /etc/yum.repos.d/webmin.repo
    echo "name=Webmin Distribution Neutral" >> /etc/yum.repos.d/webmin.repo
    echo "baseurl=http://download.webmin.com/download/yum" >> /etc/yum.repos.d/webmin.repo
    echo "enabled=1" >> /etc/yum.repos.d/webmin.repo
	wget http://www.webmin.com/jcameron-key.asc -O /tmp/webmin-key.asc
	rpm /tmp/jcameron-key.asc
    $PM $PM_OPT webmin
    /etc/init.d/webmin stop && sleep 5
    cp /etc/webmin/miniserv.conf /etc/webmin/miniserv.conf_OLD
    $SED '/port=/s/10000/9779/g' /etc/webmin/miniserv.conf >> /etc/webmin/miniserv.conf
    $SED '/listen=/s/10000/9779/g' /etc/webmin/miniserv.conf >> /etc/webmin/miniserv.conf
    /etc/init.d/webmin start

else
        $ECHO "\033[1;41m NO Webmin installed - Only Debian- and Redhat-Distros supported \033[0m"
fi

	




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

# Firewall INIT
$ECHO "\033[1;40m Firewall \033[0m"
if [ "$OS" = "deb" ];then
	$WGET $IURL/INSTALL_START/firewall-init.d
	mv firewall-init.d /etc/init.d/firewall
	chmod 750 /etc/init.d/firewall
	$WGET $IURL/INSTALL_START/firewall
	chmod 700 firewall
	update-rc.d firewall defaults
	$ECHO "\033[1;31m ACHTUNG: Firewall ist AKTIV (nur ssh, webmin(10000) und http werden durchgelassen) \033[0m"

elif [ "$OS" = "rh" ];then
	system-config-securitylevel-tui
	
fi

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
	$ECHO "#! /bin/sh" >>  update-check
	$ECHO "SERVER=`hostname`" >>  update-check
	$ECHO "$PM -qq update" >>  update-check
	$ECHO "$PM -suV upgrade | mail -s \"\$SERVER: Ausstehende Updates\" paladin" >>  update-check
	chmod 700 update-check
	ln -sf $RSCRIPT/update-check /etc/cron.weekly/
	ln -sf $RSCRIPT/update-check /etc/cron.d/
fi

# POSTFIX
$ECHO "\033[1;40m Mail (Postfix) \033[0m"
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
	
	Some scripts are installed to /root/Scripts and linked to desired location:
	You can use log.all, log.mail, log.web to read log files live.
	A Admin-User \"paladin\" is installed for mail-warnings.
	Network-Time and apt-checks are activatet for cron-Daemon.

	Also pbackup for backing up specific folder [ pbackup /folder ].
	Webmin, ssh, Networking-Tools and some Editors (joe, less, lynx) 
	and some more useful tools are also installed.
	
	Messages at boot time are loged to /var/log/bootmsg.
	


	Your $HOMEDOM install_start-Script "| mail -s "$HEREF: Start-Skript installed " paladin
	log.mail


## WITH SSL
# store ssl-script every time
cd ~/Scripts

if [ "$1" = "-s" ];then

$WGET ftp://$IUSER:$IPW@$ISRV/INSTALL_START/cacert-ssl-cert.sh
$ECHO "\033[1;40m OpenSSL Cert for $HEREF \033[0m"
$ECHO "--------------------------------"

sh ./cacert-ssl-cert.sh -c $OS $HEREF

fi

## END
$ECHO "DONE. Enjoy !"




## Farbe in der Bash
# --> da sollte eigentlich sed hin !
#
#echo "BASH-FARBE..."
#echo "#Achtung! das ist dann eventuell zweimal in bashrc drin !" >> /root/.bashrc
#echo "#install_start_PORG-Script" >> /root/.bashrc
#echo "#--------------------------" >> /root/.bashrc
#echo "export LS_OPTIONS='--color=auto'" >> /root/.bashrc
#echo 'eval "`dircolors`"' >> /root/.bashrc
#echo "alias ls='ls \$LS_OPTIONS' " >> /root/.bashrc
#echo "alias ll='ls $LS_OPTIONS -l' " >> /root/.bashrc
#echo "alias l='ls $LS_OPTIONS -lA' " >> /root/.bashrc

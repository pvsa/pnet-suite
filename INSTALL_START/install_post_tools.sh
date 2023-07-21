echo "Installing Tools..........."
echo "1. Screen"
emerge app-misc/screen
echo "2. git & eix"
emerge -D app-portage/eix dev-vcs/git
eix-update
echo "3. nullmailer, gentoolkit, cron, mailx"
emerge -D app-portage/gentoolkit mail-mta/nullmailer virtual/cron mail-client/mailx
emerge --config nullmailer
rc-update add nullmailer
CRONNAME="${ls /etc/init.d/ |grep cron}"
rc-update add $CRONNAME
echo "4. getting pnet-suite"
cd /usr/share
git clone https://github.com/pvsa/pnet-suite.git
echo "5. iptables und firewall"
emerge -D iptables
cp /usr/share/pnet-suite/INSTALL_START/firewall-init.d /etc/local.d/firewall.start
chmod 755 /etc/local.d/firewall.start
cp /usr/share/pnet-suite/INSTALL_START/firewall /etc/firewall
chmod 755 /etc/firewall
echo "6. localtime to Berlin"
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
echo "Finish"
echo "following atoms are in world:"
cat /var/lib/portage/world




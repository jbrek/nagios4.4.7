#!/bin/bash
#ubuntu 22 fix for apt restart service  screen https://askubuntu.com/questions/1367139/apt-get-upgrade-auto-restart-services
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
sudo apt-get update
sudo apt-get install -y software-properties-common ca-certificates lsb-release apt-transport-https autoconf gcc libc6 make wget unzip apache2 php7.4 libapache2-mod-php7.4 libgd-dev openssl libssl-dev autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext
echo "Bulding Nagios"
cd /tmp
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.7/nagios-4.4.7.tar.gz
tar xzf nagioscore.tar.gz
cd /tmp/nagios-4.4.7
sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled
sudo make all
sudo make install-groups-users
sudo usermod -a -G nagios www-data
sudo make install
sudo make install-daemoninit
sudo make install-commandmode
sudo make install-config
sudo make install-webconf
sudo a2enmod rewrite
sudo a2enmod cgi
sudo htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

#rem bug in 4.4.7 fix is to disable update check
sudo sh -c "sed -i 's/check_for_updates=1/check_for_updates=0/g' /usr/local/nagios/etc/nagios.cfg"

#instaling plugins
echo "Bulding Plugins"
cd /tmp
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.4.0/nagios-plugins-2.4.0.tar.gz
tar zxf nagios-plugins.tar.gz
cd /tmp/nagios-plugins-2.4.0
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install
echo " ########################"
echo " ## Starting Services  ##"
echo " ########################"
sudo systemctl start apache2
sudo systemctl start nagios.service

echo " ########################"
echo " ## FINISHED           ##"
echo " ########################"

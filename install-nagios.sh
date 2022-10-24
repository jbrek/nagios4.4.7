#!/bin/bash
#ubuntu 22 fix for apt res/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg tart service  screen https://askubuntu.com/questions/1367139/apt-get-upgrade-auto-restart-services
SECONDS=0

echo "install apt-get" | tee -a ~/log.txt
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
#adding php7.4 repo
sudo yes | LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get update
sudo apt-get install -y software-properties-common ca-certificates lsb-release apt-transport-https autoconf gcc libc6 make wget unzip apache2 php7.4 libapache2-mod-php7.4 libgd-dev openssl libssl-dev autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext
echo "apt install finished. Elapsed Time (using \$SECONDS): $SECONDS seconds" | tee -a ~/log.txt
echo "downloading nagioscore.tar.gz" | tee -a ~/log.txt
cd /tmp
i=1
while [ $i -ge 1 ]
do
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.7/nagios-4.4.7.tar.gz
#need a check to see if unable to extract
if [ $? = 0 ]; then
echo "succesfully download nagioscore.tar.gz. Elapsed Time (using \$SECONDS): $SECONDS seconds" | tee -a ~/log.txt
i=0
else
    echo "ERROR Download failed nagioscore.tar.gz" | tee -a ~/log.txt
    sleep 5
    echo "Trying download again $i" | tee -a ~/log.txt
    rm nagioscore.tar.gz
     ((i++))
fi
done
echo "extracting nagioscore.tar.gz /tmp/nagios-4.4.7" | tee -a ~/log.txt
tar xzf nagioscore.tar.gz
cd /tmp/nagios-4.4.7
sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled
echo "bulding nagioscore make all" | tee -a ~/log.txt
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
echo "creating account nagiosadmin/nagiosadmin account" | tee -a ~/log.txt
sudo htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

#rem bug in 4.4.7 fix is to disable update check https://community.spiceworks.com/topic/2455449-nagios-core-4-4-6-works-correct-nagios-core-4-4-7-give-segmentation-fault
echo "Disable update check - bug" | tee -a ~/log.txt
sudo sh -c "sed -i 's/check_for_updates=1/check_for_updates=0/g' /usr/local/nagios/etc/nagios.cfg"

#instaling plugins
echo "downloading nagios plugins" | tee -a ~/log.txt
cd /tmp
i=1
while [ $i -ge 1 ]
do
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.4.0/nagios-plugins-2.4.0.tar.gz
#need a check to see if unable to extract
if [ $? = 0 ]; then
echo "succesfully download nagios-plugins.tar.gz"  | tee -a ~/log.txt
i=0
else
    echo "ERROR download failed nagios-plugins.tar.gz"  | tee -a ~/log.txt
    sleep 5
    echo "Trying download again nagios-plugins.tar.gz"  | tee -a ~/log.txt
    rm nagios-plugins.tar.gz
    ((i++))    
fi
done

tar zxf nagios-plugins.tar.gz
cd /tmp/nagios-plugins-2.4.0
sudo ./tools/setup
sudo ./configure
echo "Bulding nagios-plugins make install" | tee -a ~/log.txt
sudo make
sudo make install

echo " ########################"
echo "Starting Services"    | tee -a ~/log.txt
echo " ########################"
sudo systemctl restart apache2.service
sudo systemctl restart nagios.service

echo " ########################"
echo "FINISHED           " | tee -a ~/log.txt
echo " ########################"
echo 
echo "Elapsed Time (using \$SECONDS): $SECONDS seconds" | tee -a ~/log.txt
ip=$(hostname  -I)
#removing trailing space
ip="$(echo -e "${ip}" | tr -d '[:space:]')"
echo "access nagios @ http://"$ip"/nagios" | tee -a ~/log.txt
echo "username/password nagiosadmin" | tee -a ~/log.txt
echo "log file at /tmp/install-nagios.log " | tee -a ~/log.txt
cp ~/log.txt /tmp/install-nagios.log
cat ~/log.txt
rm ~/log.txt

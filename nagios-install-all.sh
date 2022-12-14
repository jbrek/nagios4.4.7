#!/bin/bash
#ubuntu 22 fix for apt restart service  screen https://askubuntu.com/questions/1367139/apt-get-upgrade-auto-restart-services
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
#
sudo apt-get update
echo "More stuff to make work on ub22"
sudo apt-get install -y software-properties-common ca-certificates lsb-release apt-transport-https
#add new repositry to isntall php7
sudo yes | LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
sudo apt-get update
echo "INSTALL NAGIOS APT"
sudo apt-get install -y autoconf gcc libc6 make wget unzip apache2 php7.4 libapache2-mod-php7.4 libgd-dev
echo "INSTALL SSL required 4.4.7"
sudo apt-get install -y openssl libssl-dev
echo "INSTALL NAGIOS PLUGINS APT"
sudo apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext
echo "INSTALL PNP4NAGIOS"
sudo apt-get install -y rrdtool librrds-perl php7.4-gd php7.4-xml rdtool                     
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
#sudo apt install php libapache2-mod-php
#service --status-all
#rem bug in 4.4.7 fix is to disable update check
sudo sh -c "sed -i 's/check_for_updates=1/check_for_updates=0/g' /usr/local/nagios/etc/nagios.cfg"
echo " ########################"
echo " ## Starting Services  ##"
echo " ########################"
sudo systemctl start apache2
sudo systemctl start nagios.service

echo " ########################"
echo " ## FINISHED           ##"
echo " ########################"

#instaling plugins
cd /tmp
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.4.0/nagios-plugins-2.4.0.tar.gz
tar zxf nagios-plugins.tar.gz
cd /tmp/nagios-plugins-2.4.0
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install
echo " ##############################"
echo " ##  nagios Services restart ##"
echo " ##############################"
sudo systemctl restart nagios.service
#sudo systemctl status nagios.service

#installing PNP4Nagios Graphing
cd /tmp
wget -O pnp4nagios.tar.gz https://github.com/lingej/pnp4nagios/archive/0.6.26.tar.gz
tar xzf pnp4nagios.tar.gz
cd /tmp/pnp4nagios-0.6.26
sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled
sudo make all
sudo make install
sudo make install-webconf
sudo make install-config
sudo make install-init
sudo systemctl daemon-reload
sudo systemctl enable npcd.service
echo " ##############################"
echo " ##  npcd started            ##"
echo " ##############################"
sudo systemctl start npcd.service
sudo systemctl restart apache2.service

#settting up nagios for pnp
sudo sh -c "sed -i 's/process_performance_data=0/process_performance_data=1/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/#host_perfdata_file=/host_perfdata_file=/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/^host_perfdata_file=.*/host_perfdata_file=\/usr\/local\/pnp4nagios\/var\/service-perfdata/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/^#host_perfdata_file_template=.*/host_perfdata_file_template=DATATYPE::HOSTPERFDATA\\\\tTIMET::\$TIMET\$\\\\tHOSTNAME::\$HOSTNAME\$\\\\tHOSTPERFDATA::\$HOSTPERFDATA\$\\\\tHOSTCHECKCOMMAND::\$HOSTCHECKCOMMAND\$\\\\tHOSTSTATE::\$HOSTSTATE\$\\\\tHOSTSTATETYPE::\$HOSTSTATETYPE\$/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/#host_perfdata_file_mode=/host_perfdata_file_mode=/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/^#host_perfdata_file_processing_interval=.*/host_perfdata_file_processing_interval=15/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/^#host_perfdata_file_processing_command=.*/host_perfdata_file_processing_command=process-host-perfdata-file-bulk-npcd/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/#service_perfdata_file=/service_perfdata_file=/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/^service_perfdata_file=.*/service_perfdata_file=\/usr\/local\/pnp4nagios\/var\/service-perfdata/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/^#service_perfdata_file_template=.*/service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\\\\tTIMET::\$TIMET\$\\\\tHOSTNAME::\$HOSTNAME\$\\\\tSERVICEDESC::\$SERVICEDESC\$\\\\tSERVICEPERFDATA::\$SERVICEPERFDATA\$\\\\tSERVICECHECKCOMMAND::\$SERVICECHECKCOMMAND\$\\\\tHOSTSTATE::\$HOSTSTATE\$\\\\tHOSTSTATETYPE::\$HOSTSTATETYPE\$\\\\tSERVICESTATE::\$SERVICESTATE\$\\\\tSERVICESTATETYPE::\$SERVICESTATETYPE\$/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/#service_perfdata_file_mode=/service_perfdata_file_mode=/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/^#service_perfdata_file_processing_interval=.*/service_perfdata_file_processing_interval=15/g' /usr/local/nagios/etc/nagios.cfg"
sudo sh -c "sed -i 's/^#service_perfdata_file_processing_command=.*/service_perfdata_file_processing_command=process-service-perfdata-file-bulk-npcd/g' /usr/local/nagios/etc/nagios.cfg"

sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo 'define command {' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '    command_name    process-host-perfdata-file-bulk-npcd' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '    command_line    /bin/mv /usr/local/pnp4nagios/var/host-perfdata /usr/local/pnp4nagios/var/spool/host-perfdata.\$TIMET\$' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '    }' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo 'define command {' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '    command_name    process-service-perfdata-file-bulk-npcd' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '    command_line    /bin/mv /usr/local/pnp4nagios/var/service-perfdata /usr/local/pnp4nagios/var/spool/service-perfdata.\$TIMET\$' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '    }' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/commands.cfg"


sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo 'define host {' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   name       host-pnp' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   action_url /pnp4nagios/index.php/graph?host=\$HOSTNAME\$&srv=_HOST_' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   register   0' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '}' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo 'define service {' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   name       service-pnp' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   action_url /pnp4nagios/index.php/graph?host=\$HOSTNAME\$&srv=\$SERVICEDESC\$' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   register   0' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '}' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/templates.cfg"


sudo sh -c "sed -i '/name.*generic-host/a\        use                             host-pnp' /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "sed -i '/name.*generic-service/a\        use                             service-pnp' /usr/local/nagios/etc/objects/templates.cfg"

sudo rm -f /usr/local/pnp4nagios/share/install.php
echo "Fixing PNP4 code"
sudo wget -O /usr/local/pnp4nagios/lib/kohana/system/libraries/Input.php https://raw.githubusercontent.com/jbrek/nagios4.4.7/main/Input.php
sudo wget -O /usr/local/pnp4nagios/share/application/models/data.php https://raw.githubusercontent.com/jbrek/nagios4.4.7/main/data.php



#Installing NRPE
sudo apt-get update
sudo apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget openssl

cd /tmp
wget --no-check-certificate -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-4.1.0.tar.gz
tar xzf nrpe.tar.gz

cd /tmp/nrpe-nrpe-4.1.0/
sudo ./configure --enable-command-args --with-ssl-lib=/usr/lib/x86_64-linux-gnu/
sudo make all

#sudo make install-groups-users
#sudo make install
#sudo make install-config
sudo sh -c "echo >> /etc/services"
sudo sh -c "sudo echo '# Nagios services' >> /etc/services"
sudo sh -c "sudo echo 'nrpe    5666/tcp' >> /etc/services"

sudo make install-init
sudo sh -c "sed -i 's/^dont_blame_nrpe=.*/dont_blame_nrpe=1/g' /usr/local/nagios/etc/nrpe.cfg"
sudo systemctl enable nrpe.service
sudo systemctl start nrpe.service
/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1


echo "Starting Nagios"
sudo systemctl restart nagios.service
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

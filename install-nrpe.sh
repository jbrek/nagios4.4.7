#!/bin/bash
sudo apt-get update
sudo apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget openssl

cd /tmp
wget --no-check-certificate -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-4.1.0.tar.gz
tar xzf nrpe.tar.gz

cd /tmp/nrpe-nrpe-4.1.0/
sudo ./configure --enable-command-args --with-ssl-lib=/usr/lib/x86_64-linux-gnu/
sudo make all

#sudo make install-groups-users
sudo make install
sudo make install-config
sudo sh -c "echo >> /etc/services"
sudo sh -c "sudo echo '# Nagios services' >> /etc/services"
sudo sh -c "sudo echo 'nrpe    5666/tcp' >> /etc/services"

sudo make install-init
sudo sh -c "sed -i 's/^dont_blame_nrpe=.*/dont_blame_nrpe=1/g' /usr/local/nagios/etc/nrpe.cfg"

sudo sh -c "echo ''  >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo 'define command {' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '   command_name       check_nrpe' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '   command_line       \$USER1\$/check_nrpe -2 -P 8192 -H \$HOSTADDRESS\$ -c \$ARG1\$' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '}' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo ''  >> /usr/local/nagios/etc/objects/commands.cfg"

echo "Resarting services"
sudo systemctl enable nrpe.service
sudo systemctl start nrpe.service
sudo systemctl restart nagios.service
echo "running /usr/local/nagios/libexec/check_nrpe should output version"
/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1


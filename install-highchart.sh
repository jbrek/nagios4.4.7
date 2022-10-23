#!/bin/bash
#10-23-2022 version 1
echo "Installing Highchart"
sudo apt update
sudo apt install unrar
mkdir /tmp/highcharts4nagios.1.3.1
cd /tmp/highcharts4nagios.1.3.1/
wget "https://exchange.nagios.org/components/com_mtree/attachment.php?link_id=4011&cf_id=24" -O highcharts4nagios.1.3.1.rar
unrar x highcharts4nagios.1.3.1.rar

echo "Inserting IP address into highcharts.html"
ip=$(hostname  -I)
#removing trailing space
ip="$(echo -e "${ip}" | tr -d '[:space:]')"
sed -i "s/88.8.108.207/$ip/g" highcharts.html 
sed -i "s/88.8.138.138/$ip/g" highcharts.html 

echo "Applying dark theme & bigger chart"
sed -i "s/<body>/\<style\> body \\{background-color\\: \\#2b2b2b\\;\\} p \\{ color\\:\\#e3e3e3\\;\\} \\<\\/style\\> \\<body\\> /g" highcharts.html 
sed -i "s/800px/1200px/g" highcharts.html
sed -i "s/400px/600px/g" highcharts.html

cd /tmp
sudo mv /tmp/highcharts4nagios.1.3.1/ /usr/local/highcharts
##############
#apache2 conf 
##############
echo "Creating /etc/apache2/sites-enabled/highcharts.conf"
sudo sh -c "echo Alias /highcharts \\\"/usr/local/highcharts\\\" > /etc/apache2/sites-enabled/highcharts.conf"
sudo sh -c "echo \<Directory \\\"/usr/local/highcharts\>\\\" >> /etc/apache2/sites-enabled/highcharts.conf"
sudo sh -c "echo '    Options None' >> /etc/apache2/sites-enabled/highcharts.conf"
sudo sh -c "echo '    AllowOverride None' >> /etc/apache2/sites-enabled/highcharts.conf"
sudo sh -c "echo '    Order allow,deny' >> /etc/apache2/sites-enabled/highcharts.conf"
sudo sh -c "echo '    Allow from all' >> /etc/apache2/sites-enabled/highcharts.conf"
sudo sh -c "echo '    Require all granted' >> /etc/apache2/sites-enabled/highcharts.conf"
sudo sh -c "echo \</Directory\> >> /etc/apache2/sites-enabled/highcharts.conf"

#Nagios Config
echo "updating genric-service in /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "sed -i 's/use                             service-pnp/use                             service-pnp,service-highchart/g' /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo 'define service {' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   name       service-highchart' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   action_url /pnp4nagios/index.php/graph?host=\$HOSTNAME\$&srv=\$SERVICEDESC\$ class=tips rel=/pnp4nagios/popup?host=\$HOSTNAME$&srv=\$SERVICEDESC$' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   notes_url /highcharts/highcharts.html?host=\$HOSTNAME\$&srv=\$SERVICEDESC\$' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '   register   0' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '}' >> /usr/local/nagios/etc/objects/templates.cfg"
sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/templates.cfg"

echo "restarting services"
sudo systemctl restart nagios.service
sudo systemctl restart apache2.service
echo "Finished"

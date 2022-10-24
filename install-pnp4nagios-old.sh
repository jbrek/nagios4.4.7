#!/bin/bash
#installing PNP4Nagios Graphing
SECONDS=0
echo "$SECONDS seconds: adding ppa:ondrej/php repository to install php7.4" | tee -a ~/log.txt
sudo yes | LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get install -y rrdtool librrds-perl php7.4-gd php7.4-xml rdtool    
echo "$SECONDS seconds: apt install completed" | tee -a ~/log.txt
echo "$SECONDS seconds: Downloading pnp4nagios.tar.gz" | tee -a ~/log.txt
cd /tmp

i=1
while [ $i -ge 1 ]
do
wget -O pnp4nagios.tar.gz https://github.com/lingej/pnp4nagios/archive/0.6.26.tar.gz
#need a check to see if unable to extract
if [ $? = 0 ]; then
echo "$SECONDS seconds: succesfully download pnp4nagios.tar.gz"  | tee -a ~/log.txt
i=0
else
    echo "ERROR download failed pnp4nagios.tar.gz"  | tee -a ~/log.txt
    sleep 5
    echo "Trying download again pnp4nagios.tar.gz"  | tee -a ~/log.txt
    rm pnp4nagios.tar.gz
    ((i++))    
fi
done



tar xzf pnp4nagios.tar.gz
cd /tmp/pnp4nagios-0.6.26
sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled
echo "$SECONDS seconds: making pnp4nagios"  | tee -a ~/log.txt
sudo make all
sudo make install
sudo make install-webconf
sudo make install-config
sudo make install-init

echo "$SECONDS seconds: starting npcd.service pnp4nagios"  | tee -a ~/log.txt
sudo systemctl daemon-reload
sudo systemctl enable npcd.service
sudo systemctl start npcd.service

#settting up nagios for pnp
echo "$SECONDS seconds: editing nagios.cfg"  | tee -a ~/log.txt
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

echo "$SECONDS seconds: editing command.cfg"  | tee -a ~/log.txt
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

echo "$SECONDS seconds: editing templates.cfg"  | tee -a ~/log.txt
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

echo "Fixing PNP4 code  should use sed" | tee -a ~/log.txt
sudo wget -O /usr/local/pnp4nagios/lib/kohana/system/libraries/Input.php https://raw.githubusercontent.com/jbrek/nagios4.4.7/main/Input.php
sudo wget -O /usr/local/pnp4nagios/share/application/models/data.php https://raw.githubusercontent.com/jbrek/nagios4.4.7/main/data.php

echo "Restarting services " | tee -a ~/log.txt
sudo systemctl start npcd.service
sudo systemctl restart apache2.service
sudo systemctl restart nagios.service
echo "log file at /tmp/install-pnp4nagios.log"
echo "Elapsed Time (using \$SECONDS): $SECONDS seconds" | tee -a ~/log.txt
cat ~/log.txt
cp ~/log.txt /tmp/install-pnp4nagios.log
rm ~/log.txt
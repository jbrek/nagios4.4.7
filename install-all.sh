#!/bin/bash
bash ./install-nagios.sh
bash ./install-pnp4nagios.sh
bash ./install-nrpe.sh
bash ./install-highchart.sh


sudo systemctl restart apache2.service
sudo systemctl restart nagios.service
sudo systemctl restart nrpe.service
sudo systemctl restart npcd.service


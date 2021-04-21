#!/bin/bash
sudo apt update && sudo apt upgrade
sudo apt -y install squid
sudo systemctl start squid
sudo sed -i -r 's/^http_access deny all/http_access allow all/' /etc/squid/squid.conf
sudo systemctl reload squid

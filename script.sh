#!/bin/bash

# Ajuste dos privilégios
sudo chown -R hduser:hadoop /home/hduser/jdk
sudo chown -R hduser:hadoop /home/hduser/hbase
sudo chown -R hduser:hadoop /home/hduser/phoenix

# Restart do serviço ssh
#sudo service ssh restart
#sudo systemctl restart sshd

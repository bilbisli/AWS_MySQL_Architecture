#!/bin/bash
#update yum
sudo yum -y update
sudo yum -y upgrade
#install mysql community server
sudo amazon-linux-extras install epel -y
sudo yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-10.noarch.rpm
sudo yum install -y mysql-community-server
#start the service
sudo systemctl start mysqld
sudo systemctl enable mysqld
mysql_root_pass=`sudo cat /var/log/mysqld.log | grep "temporary" | grep -oP '.*:\s+\K.*'`
new_password=Aa123456!


mysql -u root -p$mysql_root_pass
ALTER USER 'root'@'localhost' IDENTIFIED BY $new_password;



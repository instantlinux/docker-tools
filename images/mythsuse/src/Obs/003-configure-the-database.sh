#!/bin/bash

  mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION"
  mysql -uroot -e "CREATE DATABASE IF NOT EXISTS myth28"
  mysql -uroot -e "CREATE USER 'mythtv' IDENTIFIED BY 'mythtv'"
  mysql -uroot -e "GRANT ALL ON myth28.* TO 'mythtv' IDENTIFIED BY 'mythtv'"
  mysql -uroot -e "GRANT CREATE TEMPORARY TABLES ON myth28.* TO 'mythtv' IDENTIFIED BY 'mythtv'"
  mysql -uroot -e "ALTER DATABASE myth28 DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci"

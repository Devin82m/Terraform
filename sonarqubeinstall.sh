#!/bin/bash

# Updates
yum update -y
sleep 2m

# Install SonarQube
wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo
yum install sonar
service start sonar
chkconfig sonar
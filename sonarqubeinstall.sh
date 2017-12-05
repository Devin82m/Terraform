#!/bin/bash

# Updates
yum update -y

# Wait for all updates to install
sleep 2m

# Install the correct JDK
yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel -y

# Install SonarQube
wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo
yum install sonar
service start sonar
chkconfig sonar

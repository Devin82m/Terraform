#!/bin/bash

# Updates
sudo yum update -y

# Wait for all updates to install
sleep 2m

# Install the correct JDK
sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel -y

# Install SonarQube
sudo wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo
sudo yum install sonar
sudo service start sonar
sudo chkconfig sonar


jdk1.8.0_73/bin/java
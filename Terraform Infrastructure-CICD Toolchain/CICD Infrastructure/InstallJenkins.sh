#! /bin/bash

# Install Java
sudo amazon-linux-extras install java-openjdk11 -y

# Download and Install Jenkins
sudo yum update -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
sudo yum upgrade
sudo yum install jenkins -y

# Start Jenkins
sudo systemctl start jenkins

# Enable Jenkins with systemctl
sudo systemctl enable jenkins

# Install Git SCM
sudo yum install git -y

# Make sure Jenkins comes up/on when reboot
sudo chkconfig jenkins on


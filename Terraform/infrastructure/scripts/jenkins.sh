#!/bin/bash
# Ubuntu 22.04 / 24.04

# Install Java
sudo apt update -y
sudo apt install -y fontconfig openjdk-21-jre openjdk-21-jdk
java --version

# Clean up any old/broken Jenkins repo config (avoids "Conflicting Signed-By" errors)
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc

# Install Jenkins (LTS) with the 2026 signing key
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  -o /usr/share/keyrings/jenkins-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

sudo systemctl enable --now jenkins
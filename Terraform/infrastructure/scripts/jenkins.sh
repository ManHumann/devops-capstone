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

#For running node APP
sudo apt-get install -y nodejs

sudo apt-get install -y npm

#Installing Docker
sudo apt update
sudo apt install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Running post install steps..."
sudo usermod -aG docker ubuntu
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

#Installing Promtal
curl -O -L "https://github.com/grafana/loki/releases/download/v2.4.1/promtail-linux-amd64.zip"

sudo apt install -y unzip

unzip "promtail-linux-amd64.zip"
chmod a+x "promtail-linux-amd64"

sudo cp promtail-linux-amd64 /usr/local/bin/promtail

#prepare /etc/promptail/config.yml file here
sudo usermod -aG jenkins promtail

sudo mkdir -p /etc/promtail /etc/promtail/logs

cat > /etc/promtail/promtail-config.yaml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/positions.yaml

clients:
  - url: http://${monitoring_ip}:3100/loki/api/v1/push

scrape_configs:
  - job_name: jenkins
    static_configs:
      - targets:
          - localhost
        labels:
          job: jenkins
          host: jenkins-ec2
          env: production
          __path__: /var/log/jenkins/jenkins.log
EOF


sudo cat > /etc/systemd/system/promtail.service << 'EOF'
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail/promtail-config.yaml
Restart=on-failure
RestartSec=20
StandardOutput=append:/etc/promtail/logs/promtail.log
StandardError=append:/etc/promtail/logs/promtail.log

[Install]
WantedBy=multi-user.target
EOF
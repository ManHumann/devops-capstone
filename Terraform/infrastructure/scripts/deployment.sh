#!/bin/bash
# Add Docker's official GPG key:
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

## $${} is used to denote it as a bash variable using terraform template
sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Running post install steps..."
sudo usermod -aG docker ubuntu
sudo systemctl enable docker.service
sudo systemctl enable containerd.service


###################################################

# Install Nginx
sudo apt update
sudo apt-get install -y nginx

# Enable Nginx at boot and start it
sudo systemctl enable nginx
sudo systemctl start nginx

########################################################################
#Setting Up public key from jenkins sercver
mkdir -p /home/ubuntu/.ssh

echo "${jenkins_public_key}" >> /home/ubuntu/.ssh/authorized_keys

chowm -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

######################################################
#Create Deployment Environment
mkdir -p /opt/nodejs-postgres-app

cat > /opt/nodejs-postgres-app/docker-compose.yml <<'EOF'
${compose_file}
EOF

cat > /opt/nodejs-postgres-app/.env <<'EOF'
${env_file}
EOF

chown -R ubuntu:ubuntu /opt/nodejs-postgres-app

mkdir -p /opt/nodejs-postgres-app/db

#Loading the database initialization file required in docker compose
cat > /opt/nodejs-postgres-app/db/init.sql <<'EOF'
${init_sql_file}
EOF

#Loading nginx congiguration
cat > /etc/nginx/sites-available/node-app <<'EOF'
${nginx_conf}
EOF

sudo ln -s /etc/nginx/sites-available/node-app /etc/nginx/sites-enabled/node-app
sudo rm /etc/nginx/sites-enabled/default

sudo systemctl reload nginx
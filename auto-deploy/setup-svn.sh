#!/bin/bash
set -e

echo "===================================================="
echo " 🚀 AUTOMATED SVN + DOCKER + DOCKER COMPOSE SETUP"
echo "===================================================="


\###############################################
# STEP 0 — FIX DOCKER PERMISSIONS PROACTIVELY
###############################################

echo "🔧 Checking Docker group permissions..."

# Create docker group if missing
if ! getent group docker >/dev/null; then
    echo "🛠️  Creating docker group..."
    sudo groupadd docker
fi

# Add user to docker group
if ! groups $USER | grep -q docker; then
    echo "🛠️  Adding user '$USER' to docker group..."
    sudo usermod -aG docker $USER
    FIXED_PERMISSION=1
else
    FIXED_PERMISSION=0
    echo "✔ User already in docker group"
fi

###############################################
# STEP 1 — INSTALL DOCKER & DOCKER COMPOSE
###############################################
echo "🔧 Installing Docker..."

sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

echo "🐳 Docker installed:"
docker --version || true

echo "📦 Installing Docker Compose..."
sudo apt install -y docker-compose

echo "===================================================="
echo " 🛠️  Fixing Docker Socket Permissions (if needed)"
echo "===================================================="

# Fix permission denied on /var/run/docker.sock
if [ ! -w /var/run/docker.sock ]; then
    echo "🛠️  Fixing /var/run/docker.sock permissions..."
    sudo chmod 666 /var/run/docker.sock || true
fi

###########################################################
# If user was added to docker group, notify about relogin
###########################################################
if [ "$FIXED_PERMISSION" -eq 1 ]; then
    echo ""
    echo "===================================================="
    echo " ⚠️  IMPORTANT: YOU MUST LOG OUT AND LOG IN AGAIN"
    echo "===================================================="
    echo "Because the script added your user to the docker group."
    echo "Please log out of SSH and log in again, then re-run:"
    echo ""
    echo "   ./setup-svn.sh"
    echo ""
    exit 0
fi

echo "===================================================="
echo " 🏗️  Creating SVN project structure"
echo "===================================================="

###############################################
# STEP 2 — PROJECT DIRECTORY
###############################################
mkdir -p svn-docker
cd svn-docker

###############################################
# STEP 3 — DIRECTORY STRUCTURE
###############################################
mkdir -p server client

###############################################
# STEP 4 — CREATE SVN SERVER DOCKERFILE
###############################################
cat << 'EOF' > server/Dockerfile
FROM ubuntu:22.04

RUN apt update && apt install -y subversion apache2 libapache2-mod-svn && \
    a2enmod dav && a2enmod dav_svn

# Create repository
RUN mkdir -p /var/svn/repos && \
    svnadmin create /var/svn/repos/myrepo && \
    chown -R www-data:www-data /var/svn/repos

# Apache config
RUN echo '<Location /svn>' >> /etc/apache2/mods-enabled/dav_svn.conf && \
    echo '   DAV svn' >> /etc/apache2/mods-enabled/dav_svn.conf && \
    echo '   SVNParentPath /var/svn/repos' >> /etc/apache2/mods-enabled/dav_svn.conf && \
    echo '   AuthType Basic' >> /etc/apache2/mods-enabled/dav_svn.conf && \
    echo '   AuthName "SVN Repo"' >> /etc/apache2/mods-enabled/dav_svn.conf && \
    echo '   AuthUserFile /etc/svn-auth-users' >> /etc/apache2/mods-enabled/dav_svn.conf && \
    echo '   Require valid-user' >> /etc/apache2/mods-enabled/dav_svn.conf && \
    echo '</Location>' >> /etc/apache2/mods-enabled/dav_svn.conf

# Create login user
RUN htpasswd -bc /etc/svn-auth-users user1 pass123

EXPOSE 80
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
EOF

###############################################
# STEP 5 — CREATE SVN CLIENT DOCKERFILE
###############################################
cat << 'EOF' > client/Dockerfile
FROM ubuntu:22.04

RUN apt update && apt install -y subversion

WORKDIR /workspace
CMD ["bash"]
EOF

###############################################
# STEP 6 — CREATE docker-compose.yml
###############################################
cat << 'EOF' > docker-compose.yml
version: "3.8"

services:
  svn-server:
    build: ./server
    container_name: svn-server
    ports:
      - "8080:80"
    networks:
      - svn-net

  svn-client:
    build: ./client
    container_name: svn-client
    networks:
      - svn-net
    tty: true
    stdin_open: true

networks:
  svn-net:
EOF

echo "===================================================="
echo " 🚀 Building & Starting SVN Containers"
echo "===================================================="

###############################################
# STEP 7 — BUILD AND RUN CONTAINERS
###############################################
docker-compose up --build -d

echo "===================================================="
echo " 🎉 SETUP COMPLETE"
echo "===================================================="
echo "➡ SVN Server running on:  http://<YOUR_VM_IP>:8080/svn/myrepo"
echo "➡ Username: user1"
echo "➡ Password: pass123"
echo ""
echo "➡ To enter SVN client: docker exec -it svn-client bash"
echo ""
echo "Everything is ready! 🚀"

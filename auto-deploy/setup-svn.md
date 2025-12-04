Here is the **complete one-click automation shell script** (`setup-svn.sh`) that performs **ALL** steps you listed:

✅ Installs Docker
✅ Installs Docker Compose
✅ Creates project directory
✅ Creates folders + Dockerfiles
✅ Generates docker-compose.yml
✅ Builds & runs the SVN server + client
✅ Fully automatic — one command, everything ready

---

# ✅ **FULL AUTOMATION SCRIPT — `setup-svn.sh`**

> **Just copy → paste → save → run.**
> Works on **Ubuntu 20.04 / 22.04 / 24.04**.

```bash
#!/bin/bash
set -e

echo "===================================================="
echo " 🚀 AUTOMATED SVN + DOCKER + DOCKER COMPOSE SETUP"
echo "===================================================="

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
docker --version

echo "📦 Installing Docker Compose..."
sudo apt install -y docker-compose

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
```

---

# 📌 **HOW TO USE THIS SCRIPT**

1️⃣ Create the file

```bash
nano setup-svn.sh
```

2️⃣ Paste the entire script
3️⃣ Save and exit
4️⃣ Make executable

```bash
chmod +x setup-svn.sh
```

5️⃣ Run

```bash
./setup-svn.sh
```

---

# 🎉 Result: EVERYTHING is done with **1 click**

✔ Docker installed
✔ Docker Compose installed
✔ Project folders created
✔ Dockerfiles created
✔ docker-compose.yml created
✔ SVN server + client built
✔ Containers started
✔ Ready to use in seconds

---

If you want, I can also create:

🔥 A one-click installer for **multiple users**
🔥 Automatic SVN backups
🔥 Auto GitHub push
🔥 Auto volume creation
🔥 Auto migration of old repos

Just tell me **“create multi-user script”** or **“add backup automation”**.

#!/bin/bash
set -e

echo "======================================================"
echo "   FULL SVN LAB SETUP (Day 2 + Day 3) - AUTOMATION"
echo "   Runs Entirely From HOST Machine (Ubuntu)"
echo "======================================================"

################################################################################
# STEP 1: INSTALL DOCKER + DOCKER COMPOSE (IF NOT INSTALLED)
################################################################################

if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker not found. Installing Docker..."

  apt update
  apt install -y ca-certificates curl gnupg lsb-release

  mkdir -m 0755 -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | tee /etc/apt/keyrings/docker.asc > /dev/null
  chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose docker-compose-plugin

  systemctl enable docker
  systemctl start docker

  echo "[SUCCESS] Docker Installed"
else
  echo "[INFO] Docker already installed."
fi

################################################################################
# STEP 2: REMOVE OLD LAB ENVIRONMENT (SO SCRIPT IS ALWAYS REUSABLE)
################################################################################

echo "[INFO] Removing previous svn-docker environment (if any)..."
rm -rf ~/svn-docker

################################################################################
# STEP 3: RECREATE DIRECTORY STRUCTURE FOR DAY 2 + DAY 3
################################################################################

mkdir -p ~/svn-docker/server ~/svn-docker/client
cd ~/svn-docker

################################################################################
# STEP 4: WRITE SERVER DOCKERFILE
################################################################################

cat > server/Dockerfile << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y subversion apache2 libapache2-mod-svn apache2-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/svn/repos && svnadmin create /var/svn/repos/myrepo && \
    chown -R www-data:www-data /var/svn/repos

RUN mv /etc/apache2/mods-enabled/dav_svn.conf /etc/apache2/mods-enabled/dav_svn.conf.orig 2>/dev/null || true
RUN printf '<Location /svn>\n   DAV svn\n   SVNParentPath /var/svn/repos\n   AuthType Basic\n   AuthName "SVN Repo"\n   AuthUserFile /etc/svn-auth-users\n   Require valid-user\n</Location>\n' > /etc/apache2/mods-enabled/dav_svn.conf

RUN htpasswd -bc /etc/svn-auth-users user1 pass123

EXPOSE 80

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
EOF

################################################################################
# STEP 5: WRITE CLIENT DOCKERFILE
################################################################################

cat > client/Dockerfile << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y subversion curl nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash"]
EOF

################################################################################
# STEP 6: WRITE DOCKER COMPOSE FILE
################################################################################

cat > docker-compose.yml << 'EOF'
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

################################################################################
# STEP 7: START DOCKER ENVIRONMENT
################################################################################

docker compose up -d --build
sleep 5

echo "[SUCCESS] SVN Docker environment is running."
docker ps --filter "name=svn-server" --filter "name=svn-client"

################################################################################
# STEP 8: DAY 2 – CHECKOUT REPO & INITIAL COMMIT
################################################################################

docker exec -i svn-client bash << 'EOF'
cd /workspace
svn checkout http://svn-server/svn/myrepo --username user1 --password pass123
cd myrepo

echo "Welcome to SVN Docker Lab" > readme.txt
svn add readme.txt
svn commit -m "Initial commit: added readme.txt" --username user1 --password pass123

# Standard SVN layout
mkdir trunk branches tags
mv readme.txt trunk/

svn add trunk branches tags
svn commit -m "Added standard trunk/branches/tags structure" --username user1 --password pass123
EOF

echo "[SUCCESS] DAY 2 setup completed."

################################################################################
# STEP 9: DAY 3 – INSTALL HOOKS INSIDE SERVER
################################################################################

# PRE-COMMIT
docker exec -i svn-server bash << 'EOF'
cd /var/svn/repos/myrepo/hooks

cat > pre-commit << 'HOOK'
#!/bin/bash
REPOS="$1"
TXN="$2"

/usr/bin/svnlook log -t "$TXN" "$REPOS" | grep -q '[A-Za-z0-9]' || {
  echo "Commit rejected: commit message cannot be empty." 1>&2
  exit 1
}

exit 0
HOOK

chmod +x pre-commit
EOF

# POST-COMMIT
docker exec -i svn-server bash << 'EOF'
cd /var/svn/repos/myrepo/hooks

cat > post-commit << 'HOOK'
#!/bin/bash
REPOS="$1"
REV="$2"

/usr/bin/svnlook author $REPOS -r $REV >> /var/log/svn-commit.log
/usr/bin/svnlook changed $REPOS -r $REV >> /var/log/svn-commit.log
echo "------" >> /var/log/svn-commit.log
HOOK

chmod +x post-commit
EOF

echo "[SUCCESS] Hooks installed."

################################################################################
# STEP 10: TEST HOOKS + CREATE BACKUP
################################################################################

docker exec -i svn-client bash << 'EOF'
cd /workspace/myrepo

echo "Hook test content" > hooktest.txt
svn add hooktest.txt
svn commit -m "Valid commit for hook test" --username user1 --password pass123
EOF

# BACKUP
docker exec -i svn-server bash << 'EOF'
svnadmin dump /var/svn/repos/myrepo > /var/svn/repos/myrepo_backup.dump
EOF

docker cp svn-server:/var/svn/repos/myrepo_backup.dump ~/myrepo_backup.dump

echo "[SUCCESS] Day 3 Backup created at ~/myrepo_backup.dump"

################################################################################
echo "======================================================"
echo "   FULL SVN LAB READY (DAY 2 + DAY 3 AUTOMATED)"
echo "======================================================"

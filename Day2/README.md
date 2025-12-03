# 🚀 **FULL STEP-BY-STEP GUIDE (Ubuntu VM)**

---

# **STEP 1 — Install Docker & Docker Compose**

```bash
sudo apt update
sudo apt install -y docker.io docker-compose
```

Verify:

```bash
docker --version
docker info
```

---

# **STEP 2 — Create Project Directory**

```bash
mkdir yourName
cd yourName
```

---

# **STEP 3 — Create Directory Structure**

```bash
mkdir server client
touch docker-compose.yml server/Dockerfile client/Dockerfile
```

---

# **STEP 4 — Create SVN Server Dockerfile**

`server/Dockerfile`:

```dockerfile
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
```

---

# **STEP 5 — Create SVN Client Dockerfile**

`client/Dockerfile`:

```dockerfile
FROM ubuntu:22.04

RUN apt update && apt install -y subversion

WORKDIR /workspace
CMD ["bash"]
```

---

# **STEP 6 — Create docker-compose.yml**

`docker-compose.yml`:

```yaml
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
```

---

# **STEP 7 — Build & Start Containers**

Run:

```bash
docker-compose up --build -d
```

Check containers:

```bash
docker ps
```

You should see:

* `svn-server` (running)
* `svn-client` (running)

---

# **STEP 8 — Verify SVN Server in Browser**

Open this URL in your browser:

```
http://<YOUR_VM_IP>:8080/svn/myrepo
```

Login:

* **user1**
* **pass123**

---

# **STEP 9 — Use SVN Client Container**

Enter the client container:

```bash
docker exec -it svn-client bash
```

---

# **STEP 10 — Checkout Repository**

Inside client:

```bash
svn checkout http://svn-server/svn/myrepo --username user1 --password pass123
```

You will see:

```
Checked out revision 0.
```

---

# **STEP 11 — Add a File and Commit**

Inside client:

```bash
cd myrepo
echo "Hello SVN from Docker" > readme.txt
svn add readme.txt
svn commit -m "Initial commit" --username user1 --password pass123
```

You should now see:

```
Committed revision 1.
```

---

# 🎉 **SETUP COMPLETE**

You now have:

✔ SVN Server running in Docker
✔ SVN Client container
✔ Working repository
✔ Successful commit

---

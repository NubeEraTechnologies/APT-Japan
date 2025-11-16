# Day 1 — Environment setup & prerequisites (installation steps you’ll keep using later)

## Goal (one line)

Prepare a baseline VM / Docker environment with Java, DB (Postgres & MySQL), Git, Docker, and basic tools. Create trainee users and a saved snapshot / image so we can reuse it in later labs.

---

## Quick checklist (tick as you finish)

* [ ] Update system
* [ ] Create a trainee user
* [ ] Install OpenJDK 11 (or 17)
* [ ] Install Git
* [ ] Install Docker & docker-compose
* [ ] Install PostgreSQL and MySQL (server + client)
* [ ] Install curl, wget, unzip, vim
* [ ] Create DB admin users & sample DBs
* [ ] Save VM snapshot or export Docker images

---

## Preparation — connect to your VM

If using a cloud VM or VirtualBox/VMware, SSH into it (example):

```
ssh your_user@your_vm_ip
```

If you're on the host machine (not a VM), run commands in an elevated terminal (use `sudo`).

---

## 1) Update OS packages

Run:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common apt-transport-https ca-certificates gnupg lsb-release
```

---

## 2) Create a trainee admin user (so you don’t run as root)

Replace `trainee` with a name you prefer:

```bash
sudo adduser trainee
sudo usermod -aG sudo trainee
```

Test by switching users:

```bash
su - trainee
# if you need to run sudo you can: sudo whoami
```

---

## 3) Install Java (OpenJDK 11 and optionally 17)

Atlassian apps need Java 11 or 17 depending on version. Install both so you can choose:

```bash
# OpenJDK 11
sudo apt install -y openjdk-11-jdk

# Optional: OpenJDK 17
sudo apt install -y openjdk-17-jdk

# Check versions
java -version
```

If you need to switch the default Java later:

```bash
sudo update-alternatives --config java
```

---

## 4) Install Git

```bash
sudo apt install -y git
git --version
```

Tip: configure your global name/email:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

---

## 5) Install Docker & docker-compose (recommended for repeatable labs)

Add Docker repo and install:

```bash
# install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# add Docker GPG key and repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# add trainee user to docker group so you can run docker without sudo
sudo usermod -aG docker trainee
# you must log out/in for the group change to take effect
```

Install docker-compose plugin:

```bash
sudo apt install -y docker-compose-plugin
docker compose version
```

Verify Docker:

```bash
docker run --rm hello-world
```

**Windows note:** install Docker Desktop for Windows and enable WSL2 backend.

---

## 6) Install PostgreSQL and create admin DB user + sample DB

Install Postgres:

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
sudo -u postgres psql -c "SELECT version();"
```

Create a DB user and database for Atlassian (example names):

```bash
sudo -u postgres createuser --pwprompt jira_user
# when prompted, set a password (e.g., jira_pass)

sudo -u postgres createdb -O jira_user jira_db
# test connection
PGPASSWORD=jira_pass psql -h localhost -U jira_user -d jira_db -c "\dt"
```

Keep these credentials in a secure file (we'll reuse them):

```
/home/trainee/lab_creds.txt
# add: postgres_user=jira_user
#      postgres_db=jira_db
#      postgres_password=<the password you set>
```

---

## 7) Install MySQL (or MariaDB) — create user + sample DB

Install MariaDB (recommended) or MySQL. Example with MariaDB:

```bash
sudo apt install -y mariadb-server mariadb-client
sudo systemctl enable --now mariadb

# secure installation (follow prompts)
sudo mysql_secure_installation

# login and create user + DB (replace password)
sudo mysql -e "CREATE DATABASE jira_mysql_db CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -e "CREATE USER 'jira_mysql'@'localhost' IDENTIFIED BY 'jira_mysql_pass';"
sudo mysql -e "GRANT ALL PRIVILEGES ON jira_mysql_db.* TO 'jira_mysql'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

Test:

```bash
mysql -u jira_mysql -p jira_mysql_db -e "SHOW TABLES;"
```

---

## 8) Install common CLI tools

```bash
sudo apt install -y curl wget unzip vim net-tools htop
```

---

## 9) (Optional) Install Nginx or Apache (for reverse proxy / SSO later)

Install Nginx:

```bash
sudo apt install -y nginx
sudo systemctl enable --now nginx
```

Nginx will be useful later for reverse proxy / SSL termination.

---

## 10) Create an artifacts & sample code repo

Create a simple sample project that we will import to SVN/Git later:

```bash
mkdir -p ~/labs/sample-project
cat > ~/labs/sample-project/README.md <<'EOF'
Sample Project for Atlassian Labs
EOF
git init ~/labs/sample-project
cd ~/labs/sample-project
git add .
git commit -m "Initial commit - sample project"
```

---

## 11) Create a directory to store installers and credentials

Useful for offline/repeatable labs:

```bash
mkdir -p ~/labs/installers
mkdir -p ~/labs/backups
chmod 700 ~/labs
```

Move any downloaded installers here for later use.

---

## 12) Save credentials and notes (important)

Store DB creds and service notes in a file for later:

```bash
cat > ~/labs/lab_credentials.txt <<'EOF'
Postgres:
  user: jira_user
  db: jira_db
  password: <your postgres password>

MariaDB:
  user: jira_mysql
  db: jira_mysql_db
  password: jira_mysql_pass

VM snapshot note: create snapshot now (see next step)
EOF
chmod 600 ~/labs/lab_credentials.txt
```


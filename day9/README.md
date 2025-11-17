---

# 📘 **README.md – APT Admin Training (SVN + Fisheye + JIRA + License Generation)**

## **Day 1–9 Summary (From Scratch Installations)**

This README covers all steps performed so far across multiple days, starting from an empty Ubuntu server and progressing through SVN setup, Fisheye installation, JIRA installation, and JIRA license generation.

---

# ------------------------------------------------------------

# 🧩 **1. System Preparation (Ubuntu)**

Run all commands as a sudo user.

```bash
sudo apt update && sudo apt upgrade -y
```

Install essential tools:

```bash
sudo apt install -y unzip wget curl vim net-tools htop
```

---

# ------------------------------------------------------------

# 🧩 **2. Install Java 11 (Required for JIRA & Fisheye)**

```bash
sudo apt install -y openjdk-11-jdk
java -version
```

Expected:

```
openjdk version "11.x"
```

---

# ------------------------------------------------------------

# 🧩 **3. Install SVN (Subversion) From Scratch**

### Create repository root:

```bash
sudo mkdir -p /svn/repos
sudo chmod -R 777 /svn/repos
```

### Create repository:

```bash
sudo svnadmin create /svn/repos/projectA
```

### Start SVN Server:

```bash
sudo svnserve -d -r /svn/repos
```

### Create SVN Users:

Edit passwd file:

```bash
sudo nano /svn/repos/projectA/conf/passwd
```

Add:

```
[users]
admin = admin123
developer = dev123
tester = test123
```

### Configure Access Control:

```bash
sudo nano /svn/repos/projectA/conf/authz
```

Add:

```
[groups]
team = admin, developer, tester

[/]
admin = rw
developer = rw
tester = r
```

### Create standard structure:

```bash
mkdir ~/svn_temp
cd ~/svn_temp
mkdir trunk branches tags
svn import . svn://localhost/projectA -m "Initial structure"
```

### Checkout working copy:

```bash
svn checkout svn://localhost/projectA/trunk ~/projectA_wc --username admin
```

---

# ------------------------------------------------------------

# 🧩 **4. Branching, Switching, Merging in SVN**

### Create branch:

```bash
svn copy svn://localhost/projectA/trunk \
         svn://localhost/projectA/branches/feature-login \
         -m "Created feature-login branch"
```

### Switch to branch:

```bash
cd ~/projectA_wc
svn switch svn://localhost/projectA/branches/feature-login
```

### Add changes + commit:

```bash
echo "Login work" >> feature.txt
svn add feature.txt
svn commit -m "Added login feature"
```

### Merge back to trunk:

```bash
svn switch svn://localhost/projectA/trunk
svn merge svn://localhost/projectA/branches/feature-login
svn commit -m "Merged feature-login into trunk"
```

### Create tag:

```bash
svn copy svn://localhost/projectA/trunk \
         svn://localhost/projectA/tags/v1.0 \
         -m "Release 1.0"
```

---

# ------------------------------------------------------------

# 🧩 **5. Install PostgreSQL (For JIRA)**

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
```

### Create DB and user:

```bash
sudo -u postgres createuser --pwprompt jira_user
sudo -u postgres createdb -O jira_user jiradb
```

---

# ------------------------------------------------------------

# 🧩 **6. Install JIRA Software (Data Center)**

### Create installation folder:

```bash
sudo mkdir /opt/jira
sudo chmod 777 /opt/jira
cd /opt/jira
```

### Upload installer

Download from:
[https://www.atlassian.com/software/jira/update](https://www.atlassian.com/software/jira/update)

Then upload:

```bash
scp atlassian-jira-software-9.4.0-x64.bin azureuser@yourserver:/opt/jira/
```

Make executable:

```bash
chmod +x atlassian-jira-software-9.4.0-x64.bin
```

### Run Installer:

```bash
sudo ./atlassian-jira-software-9.4.0-x64.bin
```

Choose defaults:

* Install JIRA? → **Yes**
* Install as service? → **Yes**
* HTTP Port → **8080**
* JIRA Home → **/var/atlassian/application-data/jira**

---

# ------------------------------------------------------------

# 🧩 **7. Access JIRA for First Time**

Open browser:

```
http://<server-ip>:8080
```

You will see:

* Setup wizard
* License page
* DB configuration

---

# ------------------------------------------------------------

# 🧩 **8. Generate JIRA License Key (FREE Evaluation License)**

### Step 1 — Open Atlassian Licensing Portal

Go to:

🔗 [https://my.atlassian.com/products/index](https://my.atlassian.com/products/index)

Login with your Atlassian Account.

---

### Step 2 — Create New Evaluation License

Click:

**"New Evaluation License"**

Choose:

* Product: **Jira Software (Data Center)**
* Type: **Evaluation**
* Enter your **Server ID** (shown on JIRA’s license screen)

Click **Generate License**.

---

### Step 3 — Copy License

You will see a long block of text:

```
AAABrQ0ODAoPeJw9...
```

Copy it →
Paste it into the JIRA setup screen:

```
Please enter your license key
```

Click **Next**.

License is now active.

---

# ------------------------------------------------------------

# 🧩 **9. Connect JIRA to PostgreSQL**

Select:

```
I’ll set up my own database
```

Enter:

| Field    | Value       |
| -------- | ----------- |
| Host     | localhost   |
| Port     | 5432        |
| DB       | jiradb      |
| User     | jira_user   |
| Password | (your pass) |

Click **Test Connection → Next**

---

# ------------------------------------------------------------

# 🧩 **10. Create Admin Account**

Enter:

* Full Name: Admin User
* Username: admin
* Password: admin123
* Email: your email

Continue.

---

# ------------------------------------------------------------

# 🧩 **11. Create First JIRA Project**

Go to:

```
Projects → Create Project
```

Choose:

* **Scrum Software Project**
* Name: **DevTeam Project**
* Key: **DEV**

---

# ------------------------------------------------------------

# 🧩 **12. Add Users and Permissions**

Go to:

```
Administration → User Management → Create User
```

Create:

* dev1
* tester1
* lead1

Assign roles:

```
Project Settings → People
```

---

# ------------------------------------------------------------

# 🧩 **13. Workflow Customization**

Go to:

```
Project Settings → Workflows → Edit
```

Add status:

* Ready for QA

Add transitions:

```
In Progress → Ready for QA
Ready for QA → Done
```

Publish workflow.

---

# ------------------------------------------------------------

# 🧩 **14. Verification Checklist**

✔ SVN installed and working
✔ Branching + tags done
✔ PostgreSQL configured
✔ JIRA installed and running
✔ License key generated
✔ DB connected successfully
✔ Project created
✔ Users added
✔ Workflow customized

---

# 🎉 **End of README.md**

# Day 9 - Jira Installation & Setup (Complete README)

This guide documents all steps performed during **Day 9**, including installation of Jira, database setup, initial configuration, project creation, user/role management, workflow customization, and **license key generation**.

---

## 📌 Overview

Day 9 focuses on installing Jira Software (Data Center), connecting it to PostgreSQL, setting up an admin account, generating an evaluation license key, and creating a project inside Jira.

---

# 🟦 1. Requirements

* Ubuntu 20.04/22.04 VM
* Minimum 4GB RAM (8GB recommended)
* Java 11
* PostgreSQL database
* Internet access for license generation

---

# 🟦 2. Install Java 11

```bash
sudo apt update
sudo apt install -y openjdk-11-jdk
java -version
```

Expected:

```
openjdk version "11.x"
```

---

# 🟦 3. Install PostgreSQL

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
```

## Create Jira DB User + Database

```bash
sudo -u postgres createuser --pwprompt jira_user
sudo -u postgres createdb -O jira_user jiradb
```

## Increase max connections

```bash
sudo nano /etc/postgresql/*/main/postgresql.conf
```

Change:

```
max_connections = 300
```

Restart:

```bash
sudo systemctl restart postgresql
```

---

# 🟦 4. Download Jira Software

Create directory:

```bash
cd /opt
sudo mkdir jira
sudo chmod 777 jira
cd jira
```

Upload installer (example):

```
atlassian-jira-software-9.4.0-x64.bin
```

Make executable:

```bash
chmod +x atlassian-jira-software-9.4.0-x64.bin
```

---

# 🟦 5. Install Jira

Run installer:

```bash
sudo ./atlassian-jira-software-9.4.0-x64.bin
```

Choose default settings:

* Installation directory: `/opt/atlassian/jira`
* Home directory: `/var/atlassian/application-data/jira`
* HTTP Port: **8080**
* Install as service: **Yes**

---

# 🟦 6. Access Jira

Open browser:

```
http://<server-ip>:8080
```

You will reach the Jira setup wizard.

---

# 🟦 7. Connect Jira to PostgreSQL

Choose:

```
Set up my own database
```

Fill values:

* **Host:** localhost
* **Port:** 5432
* **DB Name:** jiradb
* **Username:** jira_user
* **Password:** (your password)
* **Schema:** public

Click **Test Connection** → **Next**

---

# 🟦 8. Generate Jira License Key (Important)

Jira requires a license key to complete setup.

### Steps to generate free evaluation license:

1. Go to:
   **[https://my.atlassian.com/products/index](https://my.atlassian.com/products/index)**

2. Login with your Atlassian account.

3. Click **New Evaluation License**.

4. Select:
   **Jira Software (Data Center)**

5. Enter your **Server ID** (shown on Jira setup page).

6. Click **Generate License**.

7. Copy the generated license key.

8. Paste it into Jira's license key field:

```
Please enter your license key
```

Click **Next**.

---

# 🟦 9. Create Jira Admin Account

Enter:

* Name: Admin User
* Username: admin
* Password: admin123
* Email: your_email

Click **Next**.

---

# 🟦 10. Create First Project

Go to:

```
Projects → Create Project
```

Choose template:

* **Scrum Software Project**

Project Name:
`DevTeam Project`

Project Key:
`DEV`

Click **Create**.

---

# 🟦 11. Create Users & Assign Roles

Go to:

```
Administration → User Management
```

Create:

* dev1
* tester1
* lead1

Assign roles in DEV project:

```
Project Settings → People → Add People
```

* dev1 → Developer
* tester1 → Tester
* lead1 → Project Administrator

---

# 🟦 12. Modify Workflow

Go to:

```
Project Settings → Workflows → Edit
```

Add status:

```
Ready for QA
```

Add transitions:

* In Progress → Ready for QA
* Ready for QA → Done

Publish workflow.

---

# 🟦 13. Verification Checklist

✓ Jira running on port 8080
✓ PostgreSQL connected
✓ Admin account working
✓ DEV project created
✓ Users added and roles assigned
✓ Custom workflow applied

---

# ✅ End of Day 9

Jira is now fully installed, licensed, users configured, and a working Scrum project created.

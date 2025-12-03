
# **Day 4 – SVN Installation, Hooks, Backup & Restore (Ubuntu)**

This document contains all practical work completed on **Day 4 of APT Training**.

---

# ## **1. Install SVN on Ubuntu**

```bash
sudo apt update
sudo apt install subversion -y
```

---

# ## **2. Create SVN User & Repository Structure**

```bash
sudo adduser svn
sudo mkdir -p /svn/repos
sudo chown -R svn:svn /svn
```

---

# ## **3. Create the Repository (projectA)**

```bash
sudo -u svn svnadmin create /svn/repos/projectA
```

Verify:

```bash
ls /svn/repos/projectA
```

---

# ## **4. Configure svnserve Access**

Edit configuration:

```bash
nano /svn/repos/projectA/conf/svnserve.conf
```

Enable:

```
anon-access = none
auth-access = write
password-db = passwd
```

Edit password file:

```bash
nano /svn/repos/projectA/conf/passwd
```

Add:

```
user1 = password123
```

---

# ## **5. Start svnserve (Manual Start)**

```bash
svnserve -d -r /svn/repos
```

---

# ## **6. Checkout Repository**

```bash
svn checkout svn://localhost/projectA ~/projectA_wc
```

---

# # **SVN Hooks**

# ## **7. Pre-Commit Hook**

Prevents commits without a commit message.

```bash
cd /svn/repos/projectA/hooks
nano pre-commit
```

Add:

```bash
#!/bin/bash
REPOS="$1"
TXN="$2"

/usr/bin/svnlook log -t "$TXN" "$REPOS" | grep "[A-Za-z0-9]" > /dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: Commit message cannot be empty." 1>&2
    exit 1
fi
exit 0
```

Make executable:

```bash
chmod +x pre-commit
```

Test:

```bash
svn commit -m "" .
```

---

# ## **8. Post-Commit Hook**

Logs commit author + changed files to `/var/log/svn-commits.log`.

```bash
nano post-commit
```

Add:

```bash
#!/bin/bash
REPOS="$1"
REV="$2"

/usr/bin/svnlook author "$REPOS" -r "$REV" >> /var/log/svn-commits.log
/usr/bin/svnlook changed "$REPOS" -r "$REV" >> /var/log/svn-commits.log
echo "-----" >> /var/log/svn-commits.log
exit 0
```

Make executable:

```bash
chmod +x post-commit
```

Test:

```bash
echo "Hello" > test.txt
svn add test.txt
svn commit -m "Testing post-commit"
cat /var/log/svn-commits.log
```

---

# # **Convert svnserve to systemd Service**

# ## **9. Stop Manual svnserve**

```bash
pkill svnserve
```

Create service:

```bash
nano /etc/systemd/system/svnserve.service
```

Add:

```
[Unit]
Description=Subversion Server
After=network.target

[Service]
Type=forking
User=svn
Group=svn
ExecStart=/usr/bin/svnserve -d -r /svn/repos
ExecStop=/bin/kill -15 $MAINPID
PIDFile=/var/run/svnserve.pid

[Install]
WantedBy=multi-user.target
```

Enable & start service:

```bash
systemctl daemon-reload
systemctl enable --now svnserve
systemctl status svnserve
```

---

# # **Backup & Restore**

# ## **10. Hotcopy Backup**

```bash
svnadmin hotcopy /svn/repos/projectA /svn_backups/projectA_backup
ls /svn_backups/projectA_backup
```

---

# ## **11. Daily Automated Backup (cron job)**

Create backup script:

```bash
nano /usr/local/bin/svn_backup.sh
```

Add:

```bash
#!/bin/bash
BACKUP_ROOT="/svn_backups"
REPO_PATH="/svn/repos/projectA"
DATE=$(date +%F_%H%M)
DEST="$BACKUP_ROOT/projectA_$DATE"

mkdir -p "$BACKUP_ROOT"
svnadmin hotcopy "$REPO_PATH" "$DEST"
tar -czf "$DEST.tar.gz" -C "$BACKUP_ROOT" "$(basename $DEST)"
rm -rf "$DEST"
```

Make script executable:

```bash
chmod +x /usr/local/bin/svn_backup.sh
```

Add to cron:

```bash
crontab -e
```

Add:

```
0 2 * * * /usr/local/bin/svn_backup.sh >/dev/null 2>&1
```

---

# ## **12. Restore from Backup**

```bash
tar -xzf /svn_backups/projectA_<date>.tar.gz -C /tmp
svnadmin hotcopy /tmp/projectA_<date> /svn/repos/projectA_restored
```

Verify restore:

```bash
svnlook uuid /svn/repos/projectA_restored
```

---

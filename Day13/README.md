# Day 13 - Crowd SSO & Application Permissions (Ubuntu, Crowd 7.0.1)

---

## 🎯 Objectives

* Connect **JIRA** (and optionally **Nexus/Confluence**) to Crowd
* Configure **Crowd SSO**
* Map **Groups → Application Roles**
* Test **SSO** functionality across tools
* Validate **permissions and access controls**

---

## 📌 Prerequisites

* Ubuntu VM running Crowd 7.0.1
* Admin access to Crowd
* JIRA installed (Day 12)
* Optional: Nexus 3.x installed
* Browser access to:

  * Crowd → `http://<vm-ip>:8095/crowd`
  * JIRA → `http://<vm-ip>:8080`

---

## 1. Verify Crowd Installation

```bash
sudo systemctl status crowd
```

Open Crowd in browser:

```
http://<crowd-ip>:8095/crowd
```

---

## 2. Verify/Configure Internal Directory

Navigate:
**Crowd → Directories → Internal Directory**

Create Groups:

* `jira-admin`
* `jira-user`
* `nexus-admin` (optional)
* `nexus-user` (optional)
* `sso-users`

Create sample users and assign them to appropriate groups.

---

## 3. Add JIRA as an Application in Crowd

Navigate:
**Crowd → Applications → Add Application → JIRA**

Fill in the fields:

* **Name:** `jira`
* **Password:** e.g. `JiraApp123@`
* **URL:** `http://<jira-ip>:8080`
* **IP:** `<vm-ip>` or subnet (`192.168.0.0/24`)
* **Directory:** Internal Directory

Save and note the **application password**.

---

## 4. Connect JIRA to Crowd (User Directory Setup)

In JIRA:
**Administration → User Management → User Directories → Add Directory → Atlassian Crowd**

Enter:

* **Crowd URL:** `http://<crowd-ip>:8095/crowd/`
* **App Name:** `jira`
* **App Password:** stored earlier
* **Sync:** 5 minutes

Click **Test Connection** → Save.

Restart JIRA if needed:

```bash
sudo systemctl restart jira
```

---

## 5. Enable SSO in Crowd

Navigate:
**Crowd → SSO → SSO Domain**

If using domain:
`.yourdomain.com`
If using IP-based labs: leave default.

Enable SSO for JIRA:
**Applications → jira → SSO**

* ✔ Allow SSO
* ✔ Allow cookie-based tokens
* ✔ Enable Single Sign-On mode

Save.

---

## 6. (Optional) Add Nexus as a Crowd Application

Navigate:
**Applications → Add Application → Remote (Generic)**

Use:

* **Name:** `nexus`
* **Password:** `NexusApp123@`
* **URL:** `http://<nexus-ip>:8081`

Assign directories.

Inside Nexus:

* Settings → Security → Realms
* Activate: **Crowd Realm**, **User Token Realm**

---

## 7. Assign Groups → Application Permissions

### In Crowd

**Applications → jira → Directories & Groups**
Move groups to allowed:

* `jira-admin`
* `jira-user`
* `sso-users`

### In JIRA

**User Management → Groups → Permissions**
Map:

* `jira-admin` → Admin role
* `jira-user` → User role

---

## 8. Test SSO (Important)

### Test steps:

1. Login to JIRA → Should use Crowd credentials
2. Open Crowd UI → Already logged in (SSO)
3. Open Nexus (optional) → SSO login may pass
4. Logout from **Crowd** → All sessions terminate

If logout does not work → SSO cookie issue.

---

## 9. Permission Testing

Create two users:

### **Admin User**

Groups:

* jira-admin
* nexus-admin
* sso-users

**Should have:**
✔ JIRA admin
✔ Nexus admin

### **Normal User**

Groups:

* jira-user
* sso-users

**Should have:**
✔ JIRA access
❌ No JIRA admin
❌ No Nexus admin

---

## 10. Troubleshooting

### 1. JIRA user not allowed to authenticate

Fix in Crowd:
**Applications → jira → Directories**
Ensure Internal Directory is active.

### 2. SSO cookie missing

Check browser:
DevTools → Application → Cookies → `crowd.token_key`

### 3. JIRA not syncing

```bash
sudo systemctl restart jira
```

### 4. Time sync issue

```bash
sudo apt install -y ntp
```

---

## ✔ Day 13 Completed!

You have:

* Configured Crowd SSO
* Integrated JIRA with Crowd
* Mapped permissions using Crowd groups
* Tested SSO functionality
* Validated admin/user access levels

---


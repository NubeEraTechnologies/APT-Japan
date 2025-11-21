---

# **Day 16 – Nexus Access Control & Cleanup Policies**

**APT Admin Training – Term 2 • Day 16**
**Objective:**
On Day 16 you will:
✔ Configure role-based access control (RBAC)
✔ Create custom restricted roles
✔ Test access permissions using `devuser` (without switching Linux users)
✔ Create cleanup policies
✔ Apply cleanup policies to repositories
✔ Trigger cleanup and validate logs
✔ Prepare baseline for Day 17

---

# **1. Login to Nexus**

Open browser:

```
http://158.23.160.152:8081
```

Login:

```
Username: admin
Password: Admin@123
```

---

# **2. Create a Custom Role for Restricted Developers**

**Purpose:** Allow developers to READ from repositories but NOT WRITE.

### Steps:

1. Go to
   **Administration → Security → Roles → Create Role**

2. Fill in:

| Field       | Value                                    |
| ----------- | ---------------------------------------- |
| Role ID     | `dev-restricted-role`                    |
| Role Name   | Developer Restricted Role                |
| Description | Read-only access to group + hosted repos |

3. Under **Privileges**, add:

```
nx-repository-view-maven2-maven-hosted-read
nx-repository-view-maven2-maven-hosted-browse

nx-repository-view-maven2-maven-public-group-read
nx-repository-view-maven2-maven-public-group-browse
```

⚠️ Do NOT assign deploy/write privileges.

4. Click **Save**.

---

# **3. Assign Restricted Role to devuser**

1. Go to
   **Administration → Security → Users → devuser → Edit**

2. Add:

```
dev-restricted-role
```

3. Click **Save**.

✔ Now `devuser` has read/browse only.
✔ Upload should fail.

---

# **4. Test Access using devuser (NO need to switch Linux user)**

We temporarily modify Maven credentials.

---

## **4.1 Switch Maven credentials to devuser**

Edit Maven settings.xml:

```bash
nano ~/.m2/settings.xml
```

Overwrite with this valid working file:

```xml
<settings>

  <mirrors>
    <mirror>
        <id>central-group</id>
        <mirrorOf>*</mirrorOf>
        <url>http://158.23.160.152:8081/repository/maven-public-group/</url>
    </mirror>
  </mirrors>

  <servers>
    <server>
      <id>maven-hosted</id>
      <username>devuser</username>
      <password>Dev@123</password>
    </server>
  </servers>

</settings>
```

Save:

```
CTRL + O → ENTER → CTRL + X
```

---

## **4.2 Test READ permissions (Must PASS)**

```bash
cd ~/nexus-labs/nexus-sample
mvn dependency:tree
```

Expected:

✔ Succeeds
✔ Reads dependencies from group repository
✔ Confirms `devuser` has correct read access

---

## **4.3 Test WRITE permissions (Must FAIL)**

```bash
mvn clean deploy
```

Expected output:

```
403 Forbidden
User does not have permission
```

✔ This confirms your restricted role works correctly.

---

## **4.4 Restore admin credentials**

Edit:

```bash
nano ~/.m2/settings.xml
```

Replace credentials:

```xml
<username>admin</username>
<password>Admin@123</password>
```

Save file.

---

# **5. Create Cleanup Policy (Auto-delete Old Snapshots)**

Purpose: Keep repository clean by deleting old snapshot versions.

### Steps:

1. Go to
   **Administration → Repository → Cleanup Policies**

2. Click **Create Cleanup Policy**

3. Fill:

| Field                       | Value                  |
| --------------------------- | ---------------------- |
| Name                        | `delete-old-snapshots` |
| Format                      | `maven2`               |
| Last Blob Updated           | 30 days                |
| Number of Snapshots to Keep | 3                      |

Click **Create Policy**.

✔ This keeps latest 3 snapshot builds
✔ Deletes older ones automatically

---

# **6. Apply Cleanup Policy to Repositories**

Apply to:

* `maven-hosted`
* (Optional) `maven-central-proxy`
* (Optional) `maven-public-group`

### Steps:

1. Go to **Repositories**
2. Click repository → **Edit**
3. Scroll to **Cleanup Policy**
4. Select:

```
delete-old-snapshots
```

5. Save.

---

# **7. Trigger Cleanup Manually**

1. Go to
   **Administration → Tasks**

2. Find:

```
Cleanup service
```

3. Click:

```
Run Now
```

---

# **8. Verify Cleanup in Logs**

Run:

```bash
sudo tail -f /opt/sonatype-work/nexus3/log/nexus.log
```

Expected log messages:

```
Deleting component...
Deleting snapshot...
Cleanup completed...
```

Press **CTRL + C** to stop logs.

---

# **9. Demonstration: Create Multiple Snapshots and Watch Cleanup**

### Step 1 — Update version:

```bash
nano pom.xml
```

Set:

```xml
<version>1.2-SNAPSHOT</version>
```

### Step 2 — Deploy multiple times:

```bash
mvn clean deploy
mvn clean deploy
mvn clean deploy
mvn clean deploy
```

### Step 3 — Run Cleanup Task again

Go to:

**Administration → Tasks → Cleanup service → Run Now**

Expected:

✔ Nexus removes older snapshots
✔ Retains only **latest 3**
✔ Logs confirm deletion

---

# **10. Save Day 16 Notes**

Create or update:

```bash
nano ~/nexus-labs/day16_notes.txt
```

Include:

* Screenshot of roles
* devuser permission results
* Cleanup policy name
* Cleanup log outputs
* Snapshot retention count

Save & close.

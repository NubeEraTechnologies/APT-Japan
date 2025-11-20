
# **Day 15 – Nexus Proxy & Group Repositories + Maven Integration**

**APT Admin Training – Term 2 (Day 15)**
**Objective:**
On Day 15 you will:
✔ Create a **Proxy Repository** (mirror Maven Central)
✔ Create a **Group Repository** that combines hosted + proxy
✔ Configure Maven to use the group repository
✔ Test artifact downloads through Nexus
✔ Test access control using `devuser` (without switching OS user)
✔ Observe Nexus caching behavior

This is the standard enterprise-grade Nexus setup used in real DevOps pipelines.

---

# **1. Log In to Nexus**

Open browser:

```
http://<server-ip>:8081
```

Example:

```
http://4.206.201.229:8081
```

Login:

```
username: admin
password: Admin@123
```

---

# **2. Create Proxy Repository (Maven Central Mirror)**

1. In Nexus UI → Left panel → **Repositories**
2. Click **Create repository**
3. Select **maven2 (proxy)**

Fill the fields:

| Field          | Value                             |
| -------------- | --------------------------------- |
| Name           | `maven-central-proxy`             |
| Remote URL     | `https://repo1.maven.org/maven2/` |
| Version Policy | **Mixed**                         |
| Layout Policy  | Strict                            |
| Blob Store     | default                           |

Click **Create repository**.

✔ This repo will fetch dependencies on demand.

---

# **3. Create Group Repository (Unified Repository)**

1. Go to **Repositories**
2. Click **Create repository**
3. Choose **maven2 (group)**

Fill in:

| Field          | Value                |
| -------------- | -------------------- |
| Name           | `maven-public-group` |
| Version Policy | Mixed                |
| Members        | Add:                 |

* `maven-hosted`
* `maven-central-proxy` |

Order should be:

```
1. maven-hosted
2. maven-central-proxy
```

Click **Create repository**.

✔ This gives developers ONE URL for everything.
✔ Recommended by Sonatype as best practice.

---

# **4. Get the Group Repository URL**

Go to **maven-public-group** → Copy URL:

Example:

```
http://4.206.201.229:8081/repository/maven-public-group/
```

---

# **5. Update Maven Settings to Use the Group Repo**

Edit:

```bash
nano ~/.m2/settings.xml
```

Add or update:

```xml
<settings>

  <mirrors>
    <mirror>
      <id>central-group</id>
      <mirrorOf>*</mirrorOf>
      <url>http:/YOUR_VM_IP:8081/repository/maven-public-group/</url>
    </mirror>
  </mirrors>

  <servers>
    <server>
      <id>maven-hosted</id>
      <username>admin</username>
      <password>Admin@123</password>
    </server>
  </servers>

</settings>
```

Save file.

✔ This means Maven will ALWAYS use Nexus instead of the internet.

---

# **6. Test Maven Download Through Nexus Group**

Go to your project:

```bash
cd ~/nexus-labs/nexus-sample
```

Run:

```bash
mvn dependency:tree
```

Expected behavior:

✔ Maven contacts only the group repo
✔ Nexus retrieves dependencies from proxy repo
✔ Proxy repository cache starts populating

---

# **7. Verify Proxy Repo is Working**

In Nexus UI:

Go to:

```
Repositories → maven-central-proxy → Browse
```

You should now see directories:

```
junit/
org/
com/
```

✔ This confirms remote dependencies were fetched successfully.

---

# **8. Test Access Control Using devuser (Without Switching Linux User)**

Modify Maven to temporarily use devuser credentials.

### Edit Maven settings:

```bash
nano ~/.m2/settings.xml
```

Change:

```xml
<username>admin</username>
<password>Admin@123</password>
```

TO:

```xml
<username>devuser</username>
<password>Dev@123</password>
```

Save file.

---

## **8.1 Test READ permissions**

```bash
mvn dependency:tree
```

Expected:

✔ Should succeed
✔ devuser has READ + BROWSE privileges
✔ Proxy + group repo download still works

---

## **8.2 Test WRITE permissions (should fail)**

```bash
mvn clean deploy
```

Expected:

```
403 Forbidden
User does not have permission
```

✔ Confirms devuser CANNOT upload
✔ Confirms your Nexus role/permissions are correct

---

## **8.3 Restore admin credentials**

Revert settings:

```xml
<username>admin</username>
<password>Admin@123</password>
```

---

# **9. View Nexus Logs (Caching + Requests)**

Run:

```bash
sudo tail -f /opt/sonatype-work/nexus3/log/nexus.log
```

While Maven runs, you will see:

* Group repo requests
* Proxy MISS → remote fetch
* Cache store events
* Security permission logs

Press `CTRL + C` to exit.

---

# **10. Save Day 15 Notes**

```bash
nano ~/nexus-labs/day15_notes.txt
```

Include:

* Proxy repo URL
* Group repo URL
* Working behavior of mirrorOf
* devuser permission test results
* Screenshots or notes
* Log observations

---

# **11. Take VM Snapshot**

Name it:

```
day15_nexus_proxy_group_baseline
```

✔ Ensures a stable starting point for Day 16.

---

Just say: **Day 16**

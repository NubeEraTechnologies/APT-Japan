---

# **Day 14 – Nexus Repository Manager (Hosted Repository Setup)**

**APT Admin Training – Term 2**
**Objective:**
Install Nexus Repository Manager, configure it as a service, create a Hosted Maven repository, configure Maven, deploy an artifact, and verify the upload & download using correct authentication.

---

# **1. Prepare Directories**

```bash
sudo mkdir -p /opt/nexus
sudo mkdir -p /opt/sonatype-work
sudo chown -R $(whoami):$(whoami) /opt/nexus /opt/sonatype-work
```

---

# **2. Download Nexus Repository OSS**

```bash
cd /opt/nexus
wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
tar -xvf latest-unix.tar.gz
mv nexus-3* nexus
```

---

# **3. Create Dedicated Nexus User**

```bash
sudo useradd -r -m -U -d /opt/nexus -s /bin/bash nexus
sudo chown -R nexus:nexus /opt/nexus /opt/sonatype-work
```

---

# **4. Configure `run_as_user`**

```bash
sudo nano /opt/nexus/nexus/bin/nexus.rc
```

Add:

```
run_as_user="nexus"
```

Save file.

---

# **5. Create Systemd Service for Nexus**

```bash
sudo nano /etc/systemd/system/nexus.service
```

Paste:

```
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/nexus/bin/nexus start
ExecStop=/opt/nexus/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

Enable + start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus
sudo systemctl status nexus
```

---

# **6. Access Nexus UI**

Open a browser:

```
http://<server-ip>:8081
```

Example:

```
http://4.206.201.229:8081
```

---

# **7. Retrieve Initial Admin Password**

```bash
sudo cat /opt/sonatype-work/nexus3/admin.password
```

Use this to log in.
Set a new password (example for labs): **Admin@123**

---

# **8. Disable Anonymous Access**

(Recommended for secure, authenticated access)

Nexus UI →
**Administration → Security → Anonymous Access → Disable** → Save.

---

# **9. Create a Hosted Maven Repository**

Nexus UI →
**Repositories → Create repository → maven2 (hosted)**

Use:

| Setting        | Value                                        |
| -------------- | -------------------------------------------- |
| Name           | `maven-hosted`                               |
| Version Policy | **Mixed** (to allow both RELEASE & SNAPSHOT) |
| Write Policy   | `Allow redeploy`                             |
| Layout Policy  | `Strict`                                     |

✔ Save repository.

---

# **10. Configure Maven Credentials**

Edit Maven settings:

```bash
nano ~/.m2/settings.xml
```

Add:

```xml
<settings>
  <servers>
    <server>
      <id>maven-hosted</id>
      <username>admin</username>
      <password>Admin@123</password>
    </server>
  </servers>
</settings>
```

Save & exit.

---

# **11. Generate Sample Maven Project**

```bash
mkdir -p ~/nexus-labs
cd ~/nexus-labs

mvn archetype:generate \
  -DgroupId=com.demo \
  -DartifactId=nexus-sample \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false

cd nexus-sample
```

---

# **12. Update `pom.xml` (Java 11 + distribution repo)**

```bash
nano pom.xml
```

Replace entire file with:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>com.demo</groupId>
    <artifactId>nexus-sample</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>nexus-sample</name>
    <url>http://maven.apache.org</url>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <distributionManagement>
        <repository>
            <id>maven-hosted</id>
            <url>http://4.206.201.229:8081/repository/maven-hosted/</url>
        </repository>
    </distributionManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>11</source>
                    <target>11</target>
                </configuration>
            </plugin>
        </plugins>
    </build>

</project>
```

Save.

---

# **13. Deploy Artifact to Nexus**

```bash
mvn clean deploy
```

✔ This should succeed.
✔ Artifact appears in Nexus UI under:

```
com/demo/nexus-sample/1.0-SNAPSHOT/
```

---

# **14. Download the Artifact (Authenticated)**

```bash
wget --user=admin --password='Admin@123' \
http://4.206.201.229:8081/repository/maven-hosted/com/demo/nexus-sample/1.0-SNAPSHOT/nexus-sample-1.0-SNAPSHOT.jar
```

✔ Download succeeds
✔ Confirms permissions are correct

---

# **15. Create Developer Role & User (Prep for Day 15)**

Nexus UI →
**Administration → Security → Roles → Create Role**

```
Role ID: dev-role
Privileges:
  nx-repository-view-maven2-*-read
  nx-repository-view-maven2-*-browse
```

Create user:

```
username: devuser
password: Dev@123
roles: dev-role
```

---

# **16. Save Day 14 Notes**

```bash
nano ~/nexus-labs/day14_notes.txt
```

Write:

* Repository URL
* Admin credentials
* Maven settings
* Deployment success message
* User/role details

---

# **17. Snapshot the VM**

### VirtualBox

Machine → Take Snapshot → `day14_baseline`

### VMware

Snapshot → Take Snapshot

### Cloud

Create an image/AMI.

✔ This ensures Day 15 can continue cleanly.

If you want, I can now generate the **Day 15 README.md** or guide you step-by-step for the next lab.

# Oracle JD Edwards EnterpriseOne Toolkit on GCP | JD Edwards Demo 

This folder provides Terraform configurations and Makefile automation to deploy Oracle JD Edwards EnterpriseOne infrastructure on Google Cloud Platform.


## Architectural Diagram

### Oracle JD Edwards Demo on GCP
![Oracle JD Edwards Demo Technical Architecture Diagram](images/Oracle%20Vision%20on%20GCP_%20Technical%20Architecture%20diagram.png "Oracle JD Edwards Demo on GCP Technical Architecture Diagram")

## Prerequisites

Before starting, ensure the following requirements are met:

### Environment
- GCP Project: A Google Cloud project must already exist for this deployment. Note the `PROJECT_ID`.
- Make: Install the `make` tool (version >= 4.3 recommended).

### Quota Requirements
Before deploying Toolkit, verify that your GCP project has sufficient resource quotas in the target region.

Minimum recommended quotas:
- Persistent Disk SSD (GB): ~ 1T 

Check your current quotas with:

```
gcloud compute regions describe <REGION> --project=<PROJECT_ID> \
  --format="flattened(quotas[].metric,quotas[].limit,quotas[].usage)" | grep SSD
  ```

Action if insufficient:

 - Go to Google Cloud Console – Quotas: https://console.cloud.google.com/iam-admin/quotas

 - Filter for Persistent Disk SSD (GB) in your region.

 - Click EDIT QUOTAS and request the desired increase.

 - Once the quotas are approved, proceed with the next steps.

### IAM

Ensure your GCP account has the following IAM roles:

- `roles/iam.serviceAccountUser` – Use service accounts for VM access  
- `roles/iap.tunnelResourceAccessor` – Connect to VMs using IAP tunneling  
- `roles/compute.osAdminLogin` – SSH/RDP access to VMs via OS Login  
- `roles/compute.instanceAdmin.v1` – Start, stop, and manage VM instances  
- **Storage access (choose one):**  
  - `roles/storage.admin` – Full control of Cloud Storage (buckets and objects), **or**  
  - `roles/storage.objectAdmin` – Object-level control only (least privilege option) 

#### Alternatively, the GCP account can have broad roles like:
- `roles/owner`
- `roles/editor`

## Oracle JD Edwards EnterpriseOne Demo Deployment

All Makefile commands should be run from the project root for all the deployments.

### 1. Setup the environment

```bash
# Install required tools
make setup

# Verify GCP account and project
gcloud config list

# Verify GCP access and IAM roles
make verify-gcp-access
```

---

### 2. Authenticate with GCP and configure Application Default Credentials:

Terraform uses Application Default Credentials (ADC) to interact with GCP. Run the following command before initializing Terraform:

```bash
gcloud auth application-default login
```

---

### 3. Deploy Oracle JD Edwards EnterpriseOne Infrastructure

Run the commands below to deploy the Oracle JD Edwards EnterpriseOne environment that consists of 5 servers:

```bash
# Initialize Terraform backend and modules
make init

# IMPORTANT: Verify the disk type and disk sizes in the infra.auto.tfvars file

# Plan the changes
make jde_demo_plan

# Deploy the changes
make jde_demo_deploy
```

---

### 4. Stage Oracle JD Edwards EnterpriseOne required  Media files

To deploy Oracle JD Edwards EnterpriseOne using [One-Click deployment](https://docs.oracle.com/en/applications/jd-edwards/one-click-provisioning/9.2/eoiol/index.html) process 
you'll need to stage Oracle Software from EDelivery, My Oracle Support and Oracle downloads.


Software from edelivery.oracle.com 
  - JD Edwards One-Click Provisioning 3.15 for Apps 9.2 Tools 9.2.26.1

![Oracle JD Edwards Download](images/do_edel_jde.png "Oracle JD Edwards Download")

 - Oracle Weblogic 14c

![Oracle WLS 14c Download](images/do_edel_wls.png "Oracle Weblogic 14c Download")

Oracle.com downloads
 - Oracle Database 19c Enterprise Edition 19.3.0.0.0 https://www.oracle.com/database/technologies/oracle19c-linux-downloads.html file (LINUX.X64_193000_db_home.zip)
 - Oracle JDK 1.8 https://www.oracle.com/asean/java/technologies/javase/javase8-archive-downloads.html file (jdk-8u202-linux-x64.tar.gz)
 - Oracle JDBC driver: https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html file (ojdbc8-full.tar.gz)

Sofware from support.oracle.com:
  - Oracle OPatch for 19c Database https://updates.oracle.com/download/6880880.html (OPatch 12.2.0.1.52 for DB 19.0.0.0.0)
  - Oracle Database CPU Patch #39034528 https://updates.oracle.com/download/39034528.html
  - Oracle Weblogic CPU patch #39796866 https://updates.oracle.com/download/39796866.html
  - Oracle OPatch for 14c Weblogic #28186730 https://updates.oracle.com/download/28186730.html
  
Upload all the Oracle media to Bucket created by make jde_demo_deploy process 




```bash
# Example
gcloud storage cp * gs://oracle-jde-toolkit-storage-bucket-26dd45d7/

# Verify that all required files are present in the bucket - if not please review download criteria and stage properly
./scripts/check_oracle_media_on_bucket.sh gs://oracle-jde-toolkit-storage-bucket-26dd45d7
  OK      LINUX.X64_193000_db_home.zip
  OK      V1045131-01.zip
  OK      V1053599-01.zip
  OK      V1053600-01.zip
  OK      V1053602-01.zip
  OK      V1053603-01.zip
  OK      V1053604-01.zip
  OK      V1053605-01.zip
  OK      V1053607-01.zip
  OK      V1053608-01.zip
  OK      V1053609-01.zip
  OK      V1053610-01.zip
  OK      V1053619-01.zip
  OK      V1055306-01.zip
  OK      V994956-01.zip
  OK      jdk-8u202-linux-x64.tar.gz
  OK      ojdbc8-full.tar.gz
  OK      p28186730_1394224_Generic.zip
  OK      p39034528_190000_Linux-x86-64.zip
  OK      p39796866_141100_Generic.zip
  OK      p6880880_190000_Linux-x86-64.zip

  All required Oracle media files are present in gs://oracle-jde-toolkit-storage-bucket-26dd45d7.

# Note: all remaining steps expecte this specific media and version to be in place (as automated processes)
```

---

### 5. Prepare JD Edwards servers and setup

Through this required server setup and software will be installed to servers.



```bash
# Deploy changes
make jde_demo_deploy_soft
```


```bash
# Mac hosts file 
cat /etc/hosts
127.0.0.1 jde-demo-prov.c.oracle-ebs-toolkit-demo.internal jde-demo-prov
127.0.0.1 jde-demo-db.c.oracle-ebs-toolkit-demo.internal jde-demo-db
127.0.0.1 jde-demo-ent.c.oracle-ebs-toolkit-demo.internal jde-demo-ent
127.0.0.1 jde-demo-web.c.oracle-ebs-toolkit-demo.internal jde-demo-web
127.0.0.1 jde-demo-dep.c.oracle-ebs-toolkit-demo.internal jde-demo-dep

```

Open IAP tunnel

```bash
# open tunnel
gcloud compute ssh "oracle-vision" --tunnel-through-iap  \
 --project "oracle-ebs-toolkit" -- -L 8000:localhost:8000

```

Add http://apps.example.com:8000 to the Java Security Exception list.
Open a browser and login to http://apps.example.com:8000 using sysadmin/SYSADMIN12 (case sensitive)

---

### 6. Available additional commands

List of commands available

---

### 7. Destroy Oracle JD Edwards EnterpriseOne Demo environment

```bash
# Destroy JD infrastructure (including buckets, networks and VM)

make jde_demo_destroy

```
---

### Notes

- `PROJECT_ID` is auto-detected from `gcloud config` or can be passed explicitly

- Run `make verify-gcp-access` **once** to confirm IAM roles; it is not required for each Terraform command.

# Set Region and Zone
terraform_version    = "1.6.6"
region               = "us-central1"
zone                 = "us-central1-a"
force_destroy_bucket = true

# Adjust subnet region and IP CIDR range
subnets = [{
  subnet_name           = "oracle-jde-toolkit-subnet-01"
  subnet_region         = "us-central1"
  subnet_ip             = "10.115.0.0/20"
  subnet_private_access = true
  subnet_flow_logs      = true
}]

# EBS Apps VM Configuration
ebs_apps_server_internal_ip = "10.115.0.20"
apps_machine_type           = "e2-standard-4"
apps_boot_disk_type         = "pd-balanced"
apps_boot_disk_size         = 512
apps_boot_disk_auto_delete  = true

# EBS DB VM Configuration
ebs_db_server_internal_ip = "10.115.0.25"
dbs_machine_type          = "e2-standard-8"
dbs_boot_disk_type        = "pd-balanced"
dbs_boot_disk_size        = 1024
dbs_boot_disk_auto_delete = true

## JDE DEMO config

# JD Edwards EnterpriseOne DEMO Provisioning Server jde_demo_prov
jde_demo_prov_vm_name               = "jde-demo-prov"
jde_demo_prov_server_internal_ip    = "10.115.0.40"
jde_demo_prov_machine_type          = "e2-highmem-2"
jde_demo_prov_boot_disk_size        = 200
jde_demo_prov_boot_disk_type        = "pd-ssd"
jde_demo_prov_boot_disk_auto_delete = true

# JD Edwards EnterpriseOne DEMO Database Server Configuration jde_demo_db
jde_demo_db_vm_name               = "jde-demo-db"
jde_demo_db_server_internal_ip    = "10.115.0.41"
jde_demo_db_machine_type          = "e2-highmem-4"
jde_demo_db_boot_disk_size        = 200
jde_demo_db_boot_disk_type        = "pd-ssd"
jde_demo_db_boot_disk_auto_delete = true

# JD Edwards EnterpriseOne DEMO Enterprise Server Configuration jde_demo_ent
jde_demo_ent_vm_name               = "jde-demo-ent"
jde_demo_ent_server_internal_ip    = "10.115.0.42"
jde_demo_ent_machine_type          = "e2-highmem-2"
jde_demo_ent_boot_disk_size        = 200
jde_demo_ent_boot_disk_type        = "pd-ssd"
jde_demo_ent_boot_disk_auto_delete = true

# JD Edwards EnterpriseOne DEMO Web Server Configuration jde_demo_web
jde_demo_web_vm_name               = "jde-demo-web"
jde_demo_web_server_internal_ip    = "10.115.0.43"
jde_demo_web_machine_type          = "e2-highmem-2"
jde_demo_web_boot_disk_size        = 200
jde_demo_web_boot_disk_type        = "pd-ssd"
jde_demo_web_boot_disk_auto_delete = true

# JD Edwards EnterpriseOne DEMO Deployment Server Configuration jde_demo_dep
jde_demo_dep_vm_name               = "jde-demo-dep"
jde_demo_dep_server_internal_ip    = "10.115.0.44"
jde_demo_dep_machine_type          = "e2-highmem-2"
jde_demo_dep_boot_disk_size        = 300
jde_demo_dep_boot_disk_type        = "pd-ssd"
jde_demo_dep_boot_disk_auto_delete = true

# Trusted IP Ranges for External access
trusted_ip_ranges = [] # Please provide your own trusted IP ranges. Example -   trusted_ip_ranges = ["203.0.113.0/24", "198.51.100.0/24"]

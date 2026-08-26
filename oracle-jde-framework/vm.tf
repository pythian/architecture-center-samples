data "google_compute_image" "apps_image" {
  family  = var.apps_image_family
  project = var.apps_image_project
}

data "google_compute_image" "dbs_image" {
  family  = var.dbs_image_family
  project = var.dbs_image_project
}

data "google_compute_image" "jde_demo_prov_image" {
  family  = var.jde_demo_prov_family
  project = var.jde_demo_prov_project
}

data "google_compute_image" "jde_demo_prov_image_win" {
  family  = var.jde_demo_prov_family_win
  project = var.jde_demo_prov_project_win
}

resource "google_compute_instance" "apps" {
  count        = var.oracle_jde_vision ? 0 : 1
  name         = "oracle-ebs-apps"
  machine_type = var.apps_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.apps_image.self_link
      size  = var.apps_boot_disk_size
      type  = var.apps_boot_disk_type
    }
    auto_delete = var.apps_boot_disk_auto_delete
  }

  network_interface {
    subnetwork = values(module.network.subnets)[0].self_link
    network_ip = google_compute_address.ebs_apps_server_internal_ip[0].address
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/scripts/jde-linux-startup.sh")
  }

  tags = local.vm_network_tags.app

  service_account {
    email  = google_service_account.project_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    managed-by = "terraform"
  }

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

}

resource "google_compute_instance" "dbs" {
  count        = var.oracle_jde_vision ? 0 : 1
  name         = "oracle-ebs-db"
  machine_type = var.dbs_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.dbs_image.self_link
      size  = var.dbs_boot_disk_size
      type  = var.dbs_boot_disk_type
    }
    auto_delete = var.dbs_boot_disk_auto_delete
  }

  network_interface {
    subnetwork = values(module.network.subnets)[0].self_link
    network_ip = google_compute_address.ebs_db_server_internal_ip[0].address
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/scripts/jde-linux-startup.sh")
  }

  tags = local.vm_network_tags.db

  service_account {
    email  = google_service_account.project_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    managed-by = "terraform"
  }

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

}

## JDE DEMO

resource "google_compute_instance" "jde_demo_prov" {
  count        = var.oracle_jde_vision ? 1 : 0
  name         = var.jde_demo_prov_vm_name
  machine_type = var.jde_demo_prov_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.jde_demo_prov_image.self_link
      size  = var.jde_demo_prov_boot_disk_size
      type  = var.jde_demo_prov_boot_disk_type
    }
    auto_delete = var.jde_demo_prov_boot_disk_auto_delete
  }

  network_interface {
    subnetwork = values(module.network.subnets)[0].self_link
    network_ip = google_compute_address.jde_demo_prov_server_internal_ip[0].address
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/scripts/jde-linux-startup.sh")
  }

  tags = local.vm_network_tags.vision

  service_account {
    email  = google_service_account.project_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    managed-by  = "terraform"
    application = "oracle-jde-vision"
  }

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

}

resource "google_compute_instance" "jde_demo_db" {
  count        = var.oracle_jde_vision ? 1 : 0
  name         = var.jde_demo_db_vm_name
  machine_type = var.jde_demo_db_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.jde_demo_prov_image.self_link
      size  = var.jde_demo_db_boot_disk_size
      type  = var.jde_demo_db_boot_disk_type
    }
    auto_delete = var.jde_demo_db_boot_disk_auto_delete
  }

  network_interface {
    subnetwork = values(module.network.subnets)[0].self_link
    network_ip = google_compute_address.jde_demo_db_server_internal_ip[0].address
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/scripts/jde-linux-startup.sh")
  }

  tags = local.vm_network_tags.vision

  service_account {
    email  = google_service_account.project_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    managed-by  = "terraform"
    application = "oracle-jde-vision"
  }

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

}

resource "google_compute_instance" "jde_demo_ent" {
  count        = var.oracle_jde_vision ? 1 : 0
  name         = var.jde_demo_ent_vm_name
  machine_type = var.jde_demo_ent_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.jde_demo_prov_image.self_link
      size  = var.jde_demo_ent_boot_disk_size
      type  = var.jde_demo_ent_boot_disk_type
    }
    auto_delete = var.jde_demo_ent_boot_disk_auto_delete
  }

  network_interface {
    subnetwork = values(module.network.subnets)[0].self_link
    network_ip = google_compute_address.jde_demo_ent_server_internal_ip[0].address
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/scripts/jde-linux-startup.sh")
  }

  tags = local.vm_network_tags.vision

  service_account {
    email  = google_service_account.project_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    managed-by  = "terraform"
    application = "oracle-jde-vision"
  }

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

}

resource "google_compute_instance" "jde_demo_web" {
  count        = var.oracle_jde_vision ? 1 : 0
  name         = var.jde_demo_web_vm_name
  machine_type = var.jde_demo_web_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.jde_demo_prov_image.self_link
      size  = var.jde_demo_web_boot_disk_size
      type  = var.jde_demo_web_boot_disk_type
    }
    auto_delete = var.jde_demo_web_boot_disk_auto_delete
  }

  network_interface {
    subnetwork = values(module.network.subnets)[0].self_link
    network_ip = google_compute_address.jde_demo_web_server_internal_ip[0].address
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/scripts/jde-linux-startup.sh")
  }

  tags = local.vm_network_tags.vision

  service_account {
    email  = google_service_account.project_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    managed-by  = "terraform"
    application = "oracle-jde-vision"
  }

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

}

resource "google_compute_instance" "jde_demo_dep" {
  count        = var.oracle_jde_vision ? 1 : 0
  name         = var.jde_demo_dep_vm_name
  machine_type = var.jde_demo_dep_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.jde_demo_prov_image_win.self_link
      size  = var.jde_demo_dep_boot_disk_size
      type  = var.jde_demo_dep_boot_disk_type
    }
    auto_delete = var.jde_demo_dep_boot_disk_auto_delete
  }

  network_interface {
    subnetwork = values(module.network.subnets)[0].self_link
    network_ip = google_compute_address.jde_demo_dep_server_internal_ip[0].address
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/scripts/jde-linux-startup.sh")
  }

  tags = local.vm_network_tags.vision

  service_account {
    email  = google_service_account.project_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    managed-by  = "terraform"
    application = "oracle-jde-vision"
  }

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

}
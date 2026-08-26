resource "google_dns_managed_zone" "jde_demo_dns" {
  count = var.oracle_jde_vision ? 1 : 0

  name       = "jde-demo-dns"
  dns_name   = "${var.project_id}.internal."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = module.network.network_self_link
    }
  }
}

locals {
  jde_demo_dns_records = var.oracle_jde_vision ? {
    (var.jde_demo_prov_vm_name) = google_compute_address.jde_demo_prov_server_internal_ip[0].address
    (var.jde_demo_db_vm_name)   = google_compute_address.jde_demo_db_server_internal_ip[0].address
    (var.jde_demo_ent_vm_name)  = google_compute_address.jde_demo_ent_server_internal_ip[0].address
    (var.jde_demo_web_vm_name)  = google_compute_address.jde_demo_web_server_internal_ip[0].address
    (var.jde_demo_dep_vm_name)  = google_compute_address.jde_demo_dep_server_internal_ip[0].address
  } : {}
}

resource "google_dns_record_set" "jde_demo_server" {
  for_each = local.jde_demo_dns_records

  name         = "${each.key}.c.${var.project_id}.internal."
  managed_zone = google_dns_managed_zone.jde_demo_dns[0].name
  type         = "A"
  ttl          = 300
  rrdatas      = [each.value]
}
module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "9.2.0"
  project_id   = var.project_id
  network_name = module.network.network_name

  ingress_rules = [
    {
      name          = "jde-allow-iap-in"
      description   = "Allow IAP traffic inbound"
      source_ranges = [var.iap_cidr]
      allow = [
        {
          protocol = "tcp"
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
      target_tags = ["iap-access"]
    },
    {
      name        = "jde-allow-icmp-in"
      description = "Allow ICMP traffic inbound"
      source_tags = ["icmp-access"]
      allow = [
        {
          protocol = "icmp"
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
      target_tags = ["icmp-access"]
    }
  ]

  egress_rules = []
}

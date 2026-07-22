output "exascale_peoplesoft_instance_zone" {
  description = "The zone of the Oracle ExaScale PeopleSoft application instance."
  value       = try(regex("zones/([^/]+)/", google_compute_instance.exascale_peoplesoft[0].self_link)[0], "")
}

output "exascale_deployment_summary" {
  description = "Summary of the Oracle PeopleSoft on ExaScale deployment."
  value       = <<-EOT

=========================================
 Oracle PeopleSoft on ExaScale @ GCP
-----------------------------------------
 Project ID     : ${var.project_id}
 Region         : ${var.region}
 Zone           : ${var.zone}
 ExaScale Region: ${var.exascale_location}
-----------------------------------------
 Application Tier (GCE)
-----------------------------------------
   • Name         : ${try(google_compute_instance.exascale_peoplesoft[0].name, "N/A")}
   • Internal IP  : ${try(google_compute_instance.exascale_peoplesoft[0].network_interface[0].network_ip, "N/A")}
-----------------------------------------
 Database Tier (Oracle Database@Google Cloud)
-----------------------------------------
   • Type         : Oracle Database@Google Cloud (ExaScale)
   • Cluster Name : ${try(google_oracle_database_exadb_vm_cluster.exadb_vm_cluster[0].display_name, "N/A")}
   • CDB Name     : ${var.cdb_name}
   • SSH Key      : ./exadb_private_key.pem
   • Connection   : ./exascale_outputs.yaml (TNS, SCAN DNS)
=========================================
EOT
}

output "apps_instance_zone" {
  description = "The zone where the PeopleSoft application VM is deployed."
  value       = try(google_compute_instance.apps[0].zone, "")
}

output "deployment_summary" {
  description = "Summary of the Oracle PeopleSoft deployment."
  value       = var.oracle_peoplesoft_exascale ? "PeopleSoft is deployed in ExaScale mode - see 'exascale_deployment_summary'." : <<-EOT

=========================================
 PeopleSoft VM Configuration
-----------------------------------------
   • Instance Name  : ${try(google_compute_instance.apps[0].name, "N/A")}
   • Internal IP    : ${try(google_compute_instance.apps[0].network_interface[0].network_ip, "N/A")}
   • Zone           : ${var.zone}
   • Machine Type   : ${try(google_compute_instance.apps[0].machine_type, "N/A")}
   • SSH Command    : 
       gcloud compute ssh --zone "${var.zone}" "${try(google_compute_instance.apps[0].name, "N/A")}" --tunnel-through-iap --project "${var.project_id}" -- -L 8000:localhost:8000

-----------------------------------------
 Storage
-----------------------------------------
   • Bucket Name    : ${module.peoplesoft_storage_bucket.name}
   • Bucket URL     : gs://${module.peoplesoft_storage_bucket.name}

=========================================
 Summary
-----------------------------------------
   • Total Instances: 1
   • Storage Bucket : ${module.peoplesoft_storage_bucket.name}
   • Generated At   : ${timestamp()}
=========================================
EOT
}

output "vision_instance_zone" {
  description = "The zone of the Oracle Vision instance."
  value       = try(var.oracle_jde_vision ? google_compute_instance.jde_demo_prov[0].zone : "", "")
}

output "jde_storage_bucket" {
  description = "The URL of the storage bucket."
  value       = module.jde_storage_bucket.url
}

output "deployment_summary" {
  value = var.oracle_jde_vision ? (
    <<EOT
==================================================================================
        Oracle JD Edwards EnterpriseOne One-Click Provisioning Demo 
==================================================================================

 Project ID         : ${var.project_id}
 Region             : ${var.region}
 Zone               : ${var.zone}
 VPC Network        : ${module.network.network_name}

----------------------------------------------------------------------------------
 JD Edwards Demo Instances
----------------------------------------------------------------------------------
   • Provisoning Server Name : ${google_compute_instance.jde_demo_prov[0].name}
   • Internal IP             : ${google_compute_instance.jde_demo_prov[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_demo_prov[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • SSH Command             : gcloud compute ssh --zone "${var.zone}" "${google_compute_instance.jde_demo_prov[0].name}" --tunnel-through-iap --project "${var.project_id}" -- -L 3000:localhost:3000 -L 8998:localhost:8998

   • Database Server Name    : ${google_compute_instance.jde_demo_db[0].name}
   • Internal IP             : ${google_compute_instance.jde_demo_db[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_demo_db[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • SSH Command             : gcloud compute ssh --zone "${var.zone}" "${google_compute_instance.jde_demo_db[0].name}" --tunnel-through-iap --project "${var.project_id}" -- -L 1521:localhost:1521

   • Enterprise Server Name  : ${google_compute_instance.jde_demo_ent[0].name}
   • Internal IP             : ${google_compute_instance.jde_demo_ent[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_demo_ent[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • SSH Command             : gcloud compute ssh --zone "${var.zone}" "${google_compute_instance.jde_demo_ent[0].name}" --tunnel-through-iap --project "${var.project_id}"

   • Web Server Name         : ${google_compute_instance.jde_demo_web[0].name}
   • Internal IP             : ${google_compute_instance.jde_demo_web[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_demo_web[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • SSH Command             : gcloud compute ssh --zone "${var.zone}" "${google_compute_instance.jde_demo_web[0].name}" --tunnel-through-iap --project "${var.project_id}"  -- -L 7001:localhost:7001 -L 8000:localhost:8000

   • Deployment Server Name  : ${google_compute_instance.jde_demo_dep[0].name}
   • Internal IP             : ${google_compute_instance.jde_demo_dep[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_demo_dep[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • RDP Reset Password      : gcloud compute reset-windows-password ${google_compute_instance.jde_demo_dep[0].name} 
   • RDP Command             : gcloud compute start-iap-tunnel ${google_compute_instance.jde_demo_dep[0].name} 3389 --local-host-port=localhost:3389 

----------------------------------------------------------------------------------
 Local /etc/hosts file for IAP tunneling
----------------------------------------------------------------------------------
   127.0.0.1 ${google_compute_instance.jde_demo_prov[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_demo_prov[0].name}
   127.0.0.1 ${google_compute_instance.jde_demo_db[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_demo_db[0].name}
   127.0.0.1 ${google_compute_instance.jde_demo_ent[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_demo_ent[0].name}
   127.0.0.1 ${google_compute_instance.jde_demo_web[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_demo_web[0].name}
   127.0.0.1 ${google_compute_instance.jde_demo_dep[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_demo_dep[0].name}

----------------------------------------------------------------------------------
 Storage
----------------------------------------------------------------------------------
   • Bucket Name    : ${module.jde_storage_bucket.name}
   • Bucket URL     : ${module.jde_storage_bucket.url}

----------------------------------------------------------------------------------
   • Generated At   : ${timestamp()}
==================================================================================
EOT
    ) : (
    <<EOT
==================================================================================
        Oracle JD Edwards EnterpriseOne: Customer Data Setup 
==================================================================================

 Project ID         : ${var.project_id}
 Region             : ${var.region}
 Zone               : ${var.zone}
 VPC Network        : ${module.network.network_name}

----------------------------------------------------------------------------------
 JD Edwards Instances: Customer Data
----------------------------------------------------------------------------------
   • Provisoning Server Name : ${google_compute_instance.jde_prov[0].name}
   • Internal IP             : ${google_compute_instance.jde_prov[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_prov[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • SSH Command             : gcloud compute ssh --zone "${var.zone}" "${google_compute_instance.jde_prov[0].name}" --tunnel-through-iap --project "${var.project_id}" -- -L 3000:localhost:3000 -L 8998:localhost:8998

   • Database Server Name    : ${google_compute_instance.jde_db[0].name}
   • Internal IP             : ${google_compute_instance.jde_db[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_db[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • SSH Command             : gcloud compute ssh --zone "${var.zone}" "${google_compute_instance.jde_db[0].name}" --tunnel-through-iap --project "${var.project_id}" -- -L 1521:localhost:1521

   • Enterprise Server Name  : ${google_compute_instance.jde_ent[0].name}
   • Internal IP             : ${google_compute_instance.jde_ent[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_ent[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • SSH Command             : gcloud compute ssh --zone "${var.zone}" "${google_compute_instance.jde_ent[0].name}" --tunnel-through-iap --project "${var.project_id}"

   • Web Server Name         : ${google_compute_instance.jde_web[0].name}
   • Internal IP             : ${google_compute_instance.jde_web[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_web[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • SSH Command             : gcloud compute ssh --zone "${var.zone}" "${google_compute_instance.jde_web[0].name}" --tunnel-through-iap --project "${var.project_id}"  -- -L 7001:localhost:7001 -L 8000:localhost:8000

   • Deployment Server Name  : ${google_compute_instance.jde_dep[0].name}
   • Internal IP             : ${google_compute_instance.jde_dep[0].network_interface[0].network_ip}
   • External IP             : ${try(google_compute_instance.jde_dep[0].network_interface[0].access_config[0].nat_ip, "N/A")}
   • RDP Reset Password      : gcloud compute reset-windows-password ${google_compute_instance.jde_dep[0].name} 
   • RDP Command             : gcloud compute start-iap-tunnel ${google_compute_instance.jde_dep[0].name} 3389 --local-host-port=localhost:3389 

----------------------------------------------------------------------------------
 Local /etc/hosts file for IAP tunneling
----------------------------------------------------------------------------------
   127.0.0.1 ${google_compute_instance.jde_prov[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_prov[0].name}
   127.0.0.1 ${google_compute_instance.jde_db[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_db[0].name}
   127.0.0.1 ${google_compute_instance.jde_ent[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_ent[0].name}
   127.0.0.1 ${google_compute_instance.jde_web[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_web[0].name}
   127.0.0.1 ${google_compute_instance.jde_dep[0].name}.c.${var.project_id}.internal ${google_compute_instance.jde_dep[0].name}

----------------------------------------------------------------------------------
 Storage
----------------------------------------------------------------------------------
   • Bucket Name    : ${module.jde_storage_bucket.name}
   • Bucket URL     : ${module.jde_storage_bucket.url}

----------------------------------------------------------------------------------
   • Generated At   : ${timestamp()}
==================================================================================
EOT
  )
  description = "Auto-calculated summary of either Oracle JDE Enterprise One depending on the toggle."
}

#Enable the AlloyDB, Compute Engine,  Service Networking API and Resource Manager APIs.
#roles/alloydb.admin service account access to AlloyDB resources in a project.
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "4.15.0"
    }
  }
}

module "alloy-db" {
  source               = "GoogleCloudPlatform/alloy-db/google"
  project_id           = "${var.project_id}"
  cluster_id           = "${var.cluster_name}"
  cluster_location     = "${var.region}"
  cluster_labels       = {}
  cluster_display_name = "${var.cluster_name}"
  cluster_initial_user = {
    user     = "postgres",
    password = "${var.db_password}"
  }
  network_self_link = "projects/${var.project_id}/global/networks/${var.vpc_name}"

  automated_backup_policy = null

  primary_instance = {
    instance_id       = "${var.instance_name}",
    instance_type     = "PRIMARY",
    machine_cpu_count = 8,
    database_flags    = {},
    display_name      = "${var.instance_name}"
  }
  read_pool_instance = null
}
/*
#preparing script file to fetch the ip of instance first
resource "null_resource" "replace_necessary_values" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
sed "s/REPLACE-INSTANCE-NAME/${var.instance_name}/g" "./Alloy_DB/before_subs/get_alloydb_ip.sh" > "./Alloy_DB/after_subs/get_alloydb_ip.sh.tmp"
sed "s/REPLACE-CLUSTER-NAME/${var.cluster_name}/g" "./Alloy_DB/after_subs/get_alloydb_ip.sh.tmp" > "./Alloy_DB/after_subs/get_alloydb_ip.sh"
chmod +x ./Alloy_DB/after_subs/get_alloydb_ip.sh
EOF
  }
  depends_on = [module.alloy-db]
}

data "external" "get_alloydb_ip" {
  program = ["./Alloy_DB/after_subs/get_alloydb_ip.sh"]
  # Specify the dependency on the AlloyDB instance resource
  depends_on = [null_resource.replace_necessary_values]
}

# Output the IP address so it can be used in other modules.
output "alloydb_ip" {
  value = data.external.get_alloydb_ip.result["ip_address"]
}
*/
output "alloydb_ip" {
  value = module.alloy-db.primary_instance.ip_address
}
resource "time_sleep" "wait_for_alloycluster" {
  depends_on      = [module.alloy-db]
  create_duration = "30s"
}

resource "null_resource" "create_new_user_with_role" {
  provisioner "local-exec" {
    command = <<EOF
gcloud beta alloydb users create ${var.db_new_user} --cluster=${var.cluster_name} --region=${var.region} --password=${var.db_password}
gcloud alloydb users set-superuser ${var.db_new_user} \--superuser=true \--cluster=${var.cluster_name} \--region=${var.region}
EOF
  }
  depends_on = [time_sleep.wait_for_alloycluster]
}

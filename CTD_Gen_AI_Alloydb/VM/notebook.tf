terraform {
  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "4.15.0"
    }
  }
}

resource "random_id" "server" {
  byte_length = 4
}
resource "null_resource" "bucket_creation_editing_startup_script_copying" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
gsutil mb -p ${var.project_id} -l US -b on gs://artifacts-${random_id.server.hex}
sed "s/REPLACE-PASSWORD/${var.db_password}/g" "./VM/before_substituion/script.sh" > "./VM/after_substituion/script.sh.tmp1"
sed "s/REPLACE-PRIVATE-IP/${var.private_ip_address}/g" "./VM/after_substituion/script.sh.tmp1" > "./VM/after_substituion/script.sh.tmp2"
sed "s/REPLACE-USERNAME/${var.db_username}/g" "./VM/after_substituion/script.sh.tmp2" > "./VM/after_substituion/script.sh.tmp3"
sed "s/REPLACE-BUCKET-NAME/artifacts-${random_id.server.hex}/g" "./VM/after_substituion/script.sh.tmp3" > "./VM/after_substituion/script.sh.tmp4"
sed "s/REPLACE-DATABASE-NAME/${var.database_name}/g" "./VM/after_substituion/script.sh.tmp4" > "./VM/after_substituion/script.sh"
sed "s/REPLACE-CLUSTER-NAME/${var.cluster_name}/g" "./VM/before_substituion/GenAI_for_AlloyDB.ipynb" > "./VM/after_substituion/GenAI_for_AlloyDB.ipynb.tmp1"
sed "s/REPLACE-INSTANCE-NAME/${var.instance_name}/g" "./VM/after_substituion/GenAI_for_AlloyDB.ipynb.tmp1" > "./VM/after_substituion/GenAI_for_AlloyDB.ipynb.tmp2"
sed "s/REPLACE-DATABASE-NAME/${var.database_name}/g" "./VM/after_substituion/GenAI_for_AlloyDB.ipynb.tmp2" > "./VM/after_substituion/GenAI_for_AlloyDB.ipynb.tmp3"
sed "s/REPLACE-NETWORK-NAME/${var.network}/g" "./VM/after_substituion/GenAI_for_AlloyDB.ipynb.tmp3" > "./VM/after_substituion/GenAI_for_AlloyDB.ipynb.tmp4"
sed "s/REPLACE-BUCKET-NAME/artifacts-${random_id.server.hex}/g" "./VM/after_substituion/GenAI_for_AlloyDB.ipynb.tmp4" > "./VM/after_substituion/GenAI_for_AlloyDB.ipynb"
cp ./VM/after_substituion/GenAI_for_AlloyDB.ipynb ./VM/files/
cp ./VM/after_substituion/script.sh ./VM/files/
gsutil cp ./VM/files/* gs://artifacts-${random_id.server.hex}/
EOF
  }
}

resource "google_notebooks_instance" "instance" {
  project = var.project_id
  name = var.vm_instance_name
  location = var.vm_zone
  service_account = var.service_account
  machine_type = var.vm_machine_type
  network = "projects/${var.project_id}/global/networks/${var.network}"
  post_startup_script = "gs://artifacts-${random_id.server.hex}/script.sh"
  shielded_instance_config {
        enable_integrity_monitoring = true
        enable_secure_boot          = true
        }
  vm_image {
    project      = "deeplearning-platform-release"
    image_family = "tf-2-11-cpu-debian-11-py310"
  }
  depends_on = [
    null_resource.bucket_creation_editing_startup_script_copying
  ]
}



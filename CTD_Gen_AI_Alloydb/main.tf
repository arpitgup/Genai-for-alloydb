terraform {
  required_providers {
    google = {
      source                = "hashicorp/google-beta"
      version               = "4.15.0"
      configuration_aliases = [google.service_principal_impersonation]
    }
  }
}
provider "google" {
  project = local.project_id
}
provider "google" {
  alias                       = "service_principal_impersonation"
  impersonate_service_account = "${local.project_id}@${local.project_id}.iam.gserviceaccount.com"
  project                     = local.project_id
  region                      = local.region
}
resource "random_id" "server" {
  byte_length = 4
}

locals {
private_addresss = "gen-ai-alloydb-private-addresss-${random_id.server.hex}"
network = "gen-ai-alloydb-vpc-${random_id.server.hex}"
project_id = var.project_id
vm_instance = "gen-ai-alloydb-instance-${random_id.server.hex}"
vm_machine = "n1-standard-4"
vm_zone = "us-central1-a"
service_account_email = "${local.project_id}@${local.project_id}.iam.gserviceaccount.com"
username = "postgres"
password = "CTD-${random_id.server.hex}"
region = "us-central1"
alloydb_cluster_name = "gen-ai-alloydb-cluster-${random_id.server.hex}"
alloydb_instance_name = "gen-ai-alloydb-instance-${random_id.server.hex}"
alloydb_database_name = "retail"
alloydb_new_user = "retail-admin"
repository_name = "genai-for-alloydb"
}

module "service_account" {
  source                = "./service_account"
  project_id            = local.project_id
  impersonation_account = var.deployment_service_account_name
}

module "vpc_setup" {
    providers = { google = google.service_principal_impersonation }
    source = "./VPC"
    project_id = "${local.project_id}"
    region_name = "${local.region}"
    network_name = "${local.network}"
    private_addresss_name = "${local.private_addresss}"
    depends_on = [module.service_account]
}

#loading random password to users secret manager for later use
module "secret-manager" {
  source     = "GoogleCloudPlatform/secret-manager/google"
  version    = "~> 0.1"
  project_id = var.project_id
  secrets = [
    {
      name                  = "GenAI_for_AlloyDB_database_usernames"
      automatic_replication = true
      secret_data           = "${local.alloydb_new_user}"
    },
    {
      name                  = "GenAI_for_AlloyDB_database_passwords"
      automatic_replication = true
      secret_data           = "${local.password}"
    },
  ]
  depends_on = [module.vpc_setup]
}
module "AlloyDB_setup" {
    providers = { google = google.service_principal_impersonation }
    source = "./Alloy_DB"
    project_id = "${local.project_id}"
    cluster_name = "${local.alloydb_cluster_name}"
    instance_name = "${local.alloydb_instance_name}"
    region = "${local.region}"
    vpc_name = "${local.network}"
    db_password = "${local.password}"
    db_new_user = "${local.alloydb_new_user}"
    depends_on = [
    module.secret-manager
  ]
}
module "notebook" {
    providers = { google = google.service_principal_impersonation }
    source = "./VM"
    project_id = "${local.project_id}"
    vm_zone = "${local.vm_zone}"
    network = "${local.network}"
    vm_machine_type = "${local.vm_machine}"
    vm_instance_name = "${local.vm_instance}"
    service_account = "${local.service_account_email}"
    private_ip_address = module.AlloyDB_setup.alloydb_ip
    db_username = "${local.username}"
    db_password = "${local.password}"
    database_name = "${local.alloydb_database_name}"
    cluster_name = "${local.alloydb_cluster_name}"
    instance_name = "${local.alloydb_instance_name}"
    depends_on = [module.AlloyDB_setup]
}

module "cloud_source_repo" {
  source  = "./SCR"
  project_id = var.project_id
  repository_name = "${local.repository_name}"
  depends_on = [module.AlloyDB_setup]
}

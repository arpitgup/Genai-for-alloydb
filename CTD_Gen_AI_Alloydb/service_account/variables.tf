variable "sa_roles" {
    default = [
    "roles/alloydb.admin",
    "roles/alloydb.client",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.networkAdmin",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/storage.objectAdmin",
    "roles/owner",
    "roles/notebooks.admin"
    ]
}
variable "project_id" {}
variable "impersonation_account" {}
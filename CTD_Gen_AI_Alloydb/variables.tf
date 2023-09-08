variable "project_id" {
  default = "genai-for-alloydb"
  description = "project id required"
}
variable "deployment_service_account_name" {
    default = "user:arpitgup@1987984870407.altostrat.com"
 description = "Cloudbuild_Service_account having permission to deploy terraform resources"
}
/*
variable "project_name" {
 type        = string
 description = "project name in which demo deploy"
}
variable "project_number" {
 type        = string
 description = "project number in which demo deploy"
}
variable "gcp_account_name" {
 description = "user performing the demo"
}

variable "org_id" {
 description = "Organization ID in which project created"
}
variable "data_location" {
 type        = string
 description = "Location of source data file in central bucket"
}
variable "secret_stored_project" {
  type        = string
  description = "Project where secret is accessing from"
}
*/
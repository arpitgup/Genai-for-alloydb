terraform {
  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "4.15.0"
    }
  }
}


resource "google_service_account" "service_account" {
  account_id   = var.project_id
  display_name = "Terraform Service Account"
}

# Add required permmissions to deployer service account
resource "google_project_iam_member" "new_sa_permissions" {
  for_each = toset(var.sa_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.service_account.email}"
  depends_on = [
     google_service_account.service_account
  ]
}

resource "google_service_account_iam_binding" "service_account_impersonation" {
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.serviceAccountTokenCreator"
  members = [
    var.impersonation_account
  ]
  depends_on = [
    google_service_account.service_account
  ]
}

# It can take 60+ seconds or so for the permission to actually propragate
resource "time_sleep" "service_account_impersonation_time_delay" {
  depends_on      = [google_service_account_iam_binding.service_account_impersonation, google_project_iam_member.new_sa_permissions]
  create_duration = "90s"
}
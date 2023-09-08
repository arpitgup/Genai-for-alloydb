terraform {
  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "4.15.0"
    }
  }
}
resource "google_compute_network" "network" {
  name    = var.network_name
  project = var.project_id
  auto_create_subnetworks = true
}
resource "google_compute_global_address" "private_ip_address" {
  name          = var.private_addresss_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.network.id
}
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
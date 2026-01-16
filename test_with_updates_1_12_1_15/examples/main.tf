# This file provisions the necessary networking infrastructure and then
# instantiates the Cloud SQL module to create a private PostgreSQL instance.

# Enable required Google Cloud APIs
resource "google_project_service" "apis" {
  project                    = var.project_id
  service                    = "sqladmin.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_service" "compute" {
  project                    = var.project_id
  service                    = "compute.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_service" "servicenetworking" {
  project                    = var.project_id
  service                    = "servicenetworking.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = true
}

# Use random_string to ensure the Cloud SQL instance name is unique
resource "random_string" "db_name_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Generate a random password for the database user
resource "random_password" "db_user_password" {
  length  = 16
  special = true
}

# Create a VPC network for the Cloud SQL instance
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "example-sql-network-${random_string.db_name_suffix.result}"
  auto_create_subnetworks = false
}

# Reserve an IP range for Private Services Access
resource "google_compute_global_address" "private_ip_alloc" {
  project       = var.project_id
  name          = "example-sql-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# Create the Private Services Access connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  depends_on              = [google_project_service.servicenetworking]
}

# Instantiate the Cloud SQL module
module "cloud_sql_instance" {
  source = "../../"

  # Wait for APIs and networking to be ready before creating the instance
  depends_on = [
    google_project_service.apis,
    google_service_networking_connection.private_vpc_connection
  ]

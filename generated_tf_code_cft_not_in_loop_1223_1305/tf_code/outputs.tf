# This file defines the outputs of the Terraform module.
# Outputs are values that are exposed to the user of the module, which can be used to
# configure other resources or to provide information about the created resources.

output "primary_instance" {
  description = "The full `google_sql_database_instance` resource object for the primary instance."
  value       = google_sql_database_instance.primary
  sensitive   = true
}

output "instance_name" {
  description = "The name of the primary Cloud SQL instance."
  value       = google_sql_database_instance.primary.name
}

output "instance_connection_name" {
  description = "The connection name of the primary Cloud SQL instance, used for connecting via the Cloud SQL Auth Proxy."
  value       = google_sql_database_instance.primary.connection_name
}

output "private_ip_address" {
  description = "The private IP address of the primary Cloud SQL instance."
  value       = google_sql_database_instance.primary.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the primary Cloud SQL instance."
  value       = google_sql_database_instance.primary.public_ip_address
}

output "service_account_email_address" {
  description = "The email address of the service account that is used to access the Cloud SQL instance."
  value       = google_sql_database_instance.primary.service_account_email_address
}

output "databases" {
  description = "A map of the `google_sql_database` resources created, keyed by their names."
  value       = google_sql_database.dbs
}

output "users" {
  description = "A map of the `google_sql_user` resources created, keyed by their names."
  value       = google_sql_user.db_users
  sensitive   = true
}

output "generated_user_passwords" {
  description = "A map of passwords generated for users that did not have one specified. The map is keyed by username."
  value       = { for k, v in random_password.user_passwords : k => v.result }
  sensitive   = true
}

output "read_replica_instances" {
  description = "A map of the full `google_sql_database_instance` resource objects for the read replicas, keyed by their names."
  value       = google_sql_database_instance.replicas
  sensitive   = true
}

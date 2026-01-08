# The outputs.tf file defines the values that the module will return.
# These outputs can be used by other parts of your Terraform configuration.

output "instance" {
  description = "The full `google_sql_database_instance` resource object for the primary instance."
  value       = google_sql_database_instance.primary
  sensitive   = true
}

output "instance_connection_name" {
  description = "The connection name of the primary Cloud SQL instance, used by proxy and connectors."
  value       = google_sql_database_instance.primary.connection_name
}

output "instance_name" {
  description = "The name of the primary Cloud SQL instance."
  value       = google_sql_database_instance.primary.name
}

output "private_ip_address" {
  description = "The private IP address assigned to the primary Cloud SQL instance."
  value       = google_sql_database_instance.primary.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address assigned to the primary Cloud SQL instance."
  value       = google_sql_database_instance.primary.public_ip_address
}

output "read_replica_connection_names" {
  description = "A map of read replica names to their connection names."
  value = {
    for name, replica in google_sql_database_instance.replicas : name => replica.connection_name
  }
}

output "read_replicas" {
  description = "A map of all created read replica `google_sql_database_instance` objects, keyed by their names."
  value       = google_sql_database_instance.replicas
  sensitive   = true
}

output "service_account_email_address" {
  description = "The email address of the service account delegated to the primary Cloud SQL instance."
  value       = google_sql_database_instance.primary.service_account_email_address
}

output "generated_root_password" {
  description = "The randomly generated root password, if `root_password` was not provided. Store this securely."
  value       = var.root_password == null ? random_password.root_password[0].result : null
  sensitive   = true
}

output "generated_user_passwords" {
  description = "A map of usernames to their randomly generated passwords for users where no password was provided."
  value       = { for name, pwd in random_password.user_passwords : name => pwd.result }
  sensitive   = true
}

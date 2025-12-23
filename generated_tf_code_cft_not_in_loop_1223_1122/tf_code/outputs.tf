# This file contains the output definitions for the Cloud SQL module.

# The full resource object for the primary Cloud SQL instance.
output "instance" {
  description = "The full resource object for the primary Cloud SQL instance."
  value       = google_sql_database_instance.main
}

# The connection name of the primary instance, used by proxies and connectors.
output "instance_connection_name" {
  description = "The connection name of the primary Cloud SQL instance."
  value       = google_sql_database_instance.main.connection_name
}

# The private IP address assigned to the primary instance.
output "private_ip_address" {
  description = "The private IP address of the primary Cloud SQL instance."
  value       = google_sql_database_instance.main.private_ip_address
}

# The public IP address assigned to the primary instance.
output "public_ip_address" {
  description = "The public IP address of the primary Cloud SQL instance."
  value       = google_sql_database_instance.main.public_ip_address
}

# A map of the full resource objects for the read replica instances.
output "replicas" {
  description = "A map of the full resource objects for the read replica instances, keyed by their suffix."
  value       = google_sql_database_instance.replicas
}

# A map of connection names for the read replica instances.
output "replica_connection_names" {
  description = "A map of connection names for the read replica instances, keyed by their suffix."
  value = {
    for k, v in google_sql_database_instance.replicas : k => v.connection_name
  }
}

# A map of generated passwords for the created 'BUILT_IN' database users.
output "generated_user_passwords" {
  description = "A map of generated passwords for the 'BUILT_IN' database users, keyed by username. Treat this output as sensitive."
  value       = { for k, v in random_password.users : k => v.result }
  sensitive   = true
}

# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

# This file defines the outputs of the Terraform module.
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# The name of the initial database created, if any.
output "database_name" {
  description = "The name of the initial database created, if any."
  value       = try(google_sql_database.default["db"].name, null)
}

# The password for the initial user if it was randomly generated.
output "generated_user_password" {
  description = "The password for the initial user if it was randomly generated."
  value       = var.user_password == null && var.create_user && var.user_name != null ? local.user_password : null
  sensitive   = true
}

# The full `google_sql_database_instance` resource object for the primary instance.
output "instance" {
  description = "The full `google_sql_database_instance` resource object for the primary instance."
  value       = google_sql_database_instance.default
  sensitive   = true
}

# The connection name of the primary instance, used by the Cloud SQL Proxy.
output "instance_connection_name" {
  description = "The connection name of the primary instance, used by the Cloud SQL Proxy."
  value       = google_sql_database_instance.default.connection_name
}

# The globally unique name of the primary Cloud SQL instance.
output "instance_name" {
  description = "The globally unique name of the primary Cloud SQL instance."
  value       = google_sql_database_instance.default.name
}

# The private IP address of the primary instance.
output "private_ip_address" {
  description = "The private IP address of the primary instance."
  value       = google_sql_database_instance.default.private_ip_address
}

# The public IP address of the primary instance, if enabled.
output "public_ip_address" {
  description = "The public IP address of the primary instance, if enabled."
  value       = google_sql_database_instance.default.public_ip_address
}

# A map of all the `google_sql_database_instance` read replica resource objects, keyed by their logical name.
output "read_replicas" {
  description = "A map of all the `google_sql_database_instance` read replica resource objects, keyed by their logical name."
  value       = google_sql_database_instance.replicas
  sensitive   = true
}

# The name of the initial user created, if any.
output "user_name" {
  description = "The name of the initial user created, if any."
  value       = try(google_sql_user.default["user"].name, null)
}

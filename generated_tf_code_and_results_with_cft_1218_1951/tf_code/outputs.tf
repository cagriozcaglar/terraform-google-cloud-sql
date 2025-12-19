output "instance_name" {
  description = "The name of the Cloud SQL instance."
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "The connection name of the instance to be used by the Cloud SQL Proxy."
  value       = google_sql_database_instance.main.connection_name
}

output "private_ip_address" {
  description = "The private IP address assigned to the instance."
  value       = try(google_sql_database_instance.main.private_ip_address, "")
}

output "public_ip_address" {
  description = "The public IP address assigned to the instance."
  value       = try(google_sql_database_instance.main.public_ip_address, "")
}

output "self_link" {
  description = "The URI of the created resource."
  value       = google_sql_database_instance.main.self_link
}

output "created_databases" {
  description = "A map of the databases created in the instance."
  value       = google_sql_database.main
}

output "created_users" {
  description = "A map of the users created in the instance."
  value       = google_sql_user.main
  sensitive   = true
}

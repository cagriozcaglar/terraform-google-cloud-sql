output "instance_name" {
  description = "The name of the Cloud SQL instance."
  value       = module.cloud_sql_instance.instance_name
}

output "instance_connection_name" {
  description = "The connection name of the instance, used by the Cloud SQL Auth Proxy."
  value       = module.cloud_sql_instance.instance_connection_name
}

output "private_ip_address" {
  description = "The private IP address assigned to the Cloud SQL instance."
  value       = module.cloud_sql_instance.private_ip_address
}

output "database_names" {
  description = "A list of the names of the databases created."
  value       = [for db in module.cloud_sql_instance.databases : db.name]
}

output "user_names" {
  description = "A list of the names of the users created."
  value       = [for user in module.cloud_sql_instance.users : user.name]
}

output "generated_user_password" {
  description = "The randomly generated password for the 'app_user'. NOTE: In a real environment, this should be stored in a secret manager."
  value       = module.cloud_sql_instance.users["app_user"].password
  sensitive   = true
}

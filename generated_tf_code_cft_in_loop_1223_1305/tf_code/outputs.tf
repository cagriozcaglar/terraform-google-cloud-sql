output "instance_name" {
  description = "The name of the primary Cloud SQL instance."
  value       = google_sql_database_instance.primary.name
}

output "instance_connection_name" {
  description = "The connection name of the primary instance, used by proxies and connectors."
  value       = google_sql_database_instance.primary.connection_name
}

output "instance_self_link" {
  description = "The URI of the primary instance."
  value       = google_sql_database_instance.primary.self_link
}

output "private_ip_address" {
  description = "The private IP address assigned to the primary instance."
  value       = try(google_sql_database_instance.primary.private_ip_address, null)
}

output "public_ip_address" {
  description = "The public IP address assigned to the primary instance."
  value       = try(google_sql_database_instance.primary.public_ip_address, null)
}

output "service_account_email_address" {
  description = "The email address of the service account for this instance."
  value       = google_sql_database_instance.primary.service_account_email_address
}

output "generated_user_passwords" {
  description = "A map of usernames to their randomly generated passwords. Only users with an empty password in the input variable will be present here."
  value       = { for i, u in local.users_needing_password : u.name => random_password.user_password[i].result }
  sensitive   = true
}

output "generated_root_password" {
  description = "The randomly generated password for the root user. Only set when `root_password` is not provided."
  value       = var.root_password == null ? random_password.root_password[0].result : null
  sensitive   = true
}

output "read_replica_details" {
  description = "A map containing details of the created read replicas."
  value = {
    for k, v in google_sql_database_instance.replica : k => {
      name               = v.name
      connection_name    = v.connection_name
      region             = v.region
      private_ip_address = try(v.private_ip_address, null)
      public_ip_address  = try(v.public_ip_address, null)
    }
  }
}

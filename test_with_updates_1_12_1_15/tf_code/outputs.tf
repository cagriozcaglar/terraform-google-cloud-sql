# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# ## Requirements
#
# | Name | Version |
# |------|---------|
# | <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
# | <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |
#
# ## Providers
#
# | Name | Version |
# |------|---------|
# | <a name="provider_google"></a> [google](#provider\_google) | ~> 5.0 |
#
# ## Modules
#
# No modules.
#
# ## Resources
#
# | Name | Type |
# |------|------|
# | [google_sql_database.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | resource |
# | [google_sql_database_instance.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
# | [google_sql_user.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
# | [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
#
# ## Inputs
#
# | Name | Description | Type | Default | Required |
# |------|-------------|------|---------|:--------:|
# | <a name="input_availability_type"></a> [availability\_type](#input\_availability\_type) | The availability type of the Cloud SQL instance. A `REGIONAL` instance will have a standby in a different zone. A `ZONAL` instance will be a single-zone instance. `REGIONAL` is the default and recommended for production. | `string` | `"REGIONAL"` | no |
# | <a name="input_backup_configuration"></a> [backup\_configuration](#input\_backup\_configuration) | Configuration for backups and point-in-time recovery. Set `enabled = true` to activate. `point_in_time_recovery_enabled` requires binary logging to be enabled for MySQL. | <pre>object({<br>    enabled                        = optional(bool, true)<br>    start_time                     = optional(string, "03:00")<br>    point_in_time_recovery_enabled = optional(bool, true)<br>    retained_backups               = optional(number)<br>    transaction_log_retention_days = optional(number)<br>  })</pre> | `{}` | no |
# | <a name="input_cloudsql_iam_authentication"></a> [cloudsql\_iam\_authentication](#input\_cloudsql\_iam\_authentication) | Enables IAM database authentication for the instance. This is a best practice, eliminating the need for static passwords. | `bool` | `true` | no |
# | <a name="input_database_flags"></a> [database\_flags](#input\_database\_flags) | A list of key-value pairs to set as database flags. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
# | <a name="input_database_version"></a> [database\_version](#input\_database\_version) | The database engine version to use. See https://cloud.google.com/sql/docs/db-versions for supported versions. Examples: `POSTGRES_14`, `MYSQL_8_0`, `SQLSERVER_2019_STANDARD`. | `string` | `"MYSQL_8_0"` | no |
# | <a name="input_databases"></a> [databases](#input\_databases) | A list of database objects to create in the Cloud SQL instance. | <pre>list(object({<br>    name      = string<br>    charset   = optional(string)<br>    collation = optional(string)<br>  }))</pre> | `[]` | no |
# | <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether or not to allow Terraform to destroy the instance. It is recommended to set this to `true` for production environments. | `bool` | `true` | no |
# | <a name="input_disk_autoresize"></a> [disk\_autoresize](#input\_disk\_autoresize) | Whether to allow the instance to automatically increase storage size. Recommended to be `true` to prevent outages due to full disks. | `bool` | `true` | no |
# | <a name="input_disk_autoresize_limit"></a> [disk\_autoresize\_limit](#input\_disk\_autoresize\_limit) | The maximum size to which storage can be auto-increased. A value of `0` means no limit. A non-zero value is recommended for cost control. | `number` | `100` | no |
# | <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | The initial size of the disk in GB. | `number` | `10` | no |
# | <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | The type of disk to use for storage. `PD_SSD` is recommended for most workloads. | `string` | `"PD_SSD"` | no |
# | <a name="input_encryption_key_name"></a> [encryption\_key\_name](#input\_encryption\_key\_name) | The full resource name of the KMS key to use for encryption. If not provided, a Google-managed key will be used. | `string` | `null` | no |
# | <a name="input_ip_configuration"></a> [ip\_configuration](#input\_ip\_configuration) | Network configuration for the instance. Best practice is to disable public IP (`ipv4_enabled = false`) and use a `private_network` for internal traffic. | <pre>object({<br>    ipv4_enabled    = optional(bool, false)<br>    private_network = optional(string)<br>    authorized_networks = optional(list(object({<br>      name  = string<br>      value = string<br>    })), [])<br>  })</pre> | `{}` | no |
# | <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The maintenance window for the instance. If not provided, a default window will be assigned. | <pre>object({<br>    day  = number<br>    hour = number<br>  })</pre> | `null` | no |
# | <a name="input_name"></a> [name](#input\_name) | The name of the Cloud SQL instance. This does not have to be unique, but it's a good practice. | `string` | `"default-sql-instance"` | no |
# | <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. If it is not provided, the provider project is used. | `string` | `null` | no |
# | <a name="input_region"></a> [region](#input\_region) | The region where the Cloud SQL instance will be created. | `string` | `"us-central1"` | no |
# | <a name="input_require_ssl"></a> [require\_ssl](#input\_require\_ssl) | Whether to require SSL/TLS for all client connections. | `bool` | `true` | no |
# | <a name="input_tier"></a> [tier](#input\_tier) | The machine type to use. See https://cloud.google.com/sql/pricing for more details. Example: `db-n1-standard-1`. | `string` | `"db-n1-standard-1"` | no |
# | <a name="input_user_labels"></a> [user\_labels](#input\_user\_labels) | A map of labels to assign to the instance. | `map(string)` | `{}` | no |
# | <a name="input_users"></a> [users](#input\_users) | A list of database users to create. The `password` field is sensitive and will not be displayed in logs. | <pre>list(object({<br>    name     = string<br>    password = string<br>    host     = optional(string)<br>    type     = optional(string)<br>  }))</pre> | `[]` | no |
#
# ## Outputs
#
# | Name | Description |
# |------|-------------|
# | <a name="output_databases"></a> [databases](#output\_databases) | A map of the database resources created, keyed by database name. |
# | <a name="output_instance_connection_name"></a> [instance\_connection\_name](#output\_instance\_connection\_name) | The connection name of the Cloud SQL instance, used for connecting via the Cloud SQL Auth proxy. |
# | <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | The name of the Cloud SQL instance. |
# | <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | The private IPv4 address assigned to the instance. |
# | <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The public IPv4 address assigned to the instance. |
# | <a name="output_self_link"></a> [self\_link](#output\_self\_link) | The URI of the created resource. |
# | <a name="output_service_account_email_address"></a> [service\_account\_email\_address](#output\_service\_account\_email\_address) | The email address of the service account granted `cloudsql.client` permissions. |
# | <a name="output_users"></a> [users](#output\_users) | A map of the user resources created, keyed by user name. |
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

# The outputs.tf file is used to declare output values for the Terraform module.
# These outputs can be used to access information about the resources that were created by the module.

output "instance_name" {
  description = "The name of the Cloud SQL instance."
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance, used for connecting via the Cloud SQL Auth proxy."
  value       = google_sql_database_instance.main.connection_name
}

output "private_ip_address" {
  description = "The private IPv4 address assigned to the instance."
  value       = google_sql_database_instance.main.private_ip_address
}

output "public_ip_address" {
  description = "The public IPv4 address assigned to the instance."
  value       = google_sql_database_instance.main.public_ip_address
}

output "self_link" {
  description = "The URI of the created resource."
  value       = google_sql_database_instance.main.self_link
}

output "service_account_email_address" {
  description = "The email address of the service account granted `cloudsql.client` permissions."
  value       = google_sql_database_instance.main.service_account_email_address
}

output "databases" {
  description = "A map of the database resources created, keyed by database name."
  value       = google_sql_database.main
}

output "users" {
  description = "A map of the user resources created, keyed by user name."
  value       = google_sql_user.main
  sensitive   = true
}

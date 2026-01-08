# Google Cloud SQL Terraform Module

This module provisions a Google Cloud SQL instance, including a primary instance and optional read replicas. It is designed to be a flexible and secure foundation for deploying database instances on Google Cloud Platform.

The module supports creating databases and users, configuring networking (public/private IP), setting up high availability, managing backups, and applying custom database flags. It also includes convenience features like automatic random password generation for the root user and other specified database users.

## Usage

Below is a basic example of how to use the module to create a high-availability (regional) PostgreSQL instance with a private IP address, a database, and a user.

```terraform
module "sql_instance" {
  source = "./" # Replace with the actual source path or Git URL

  project_id                = "your-gcp-project-id"
  name                      = "my-postgres-instance"
  database_version          = "POSTGRES_14"
  region                    = "us-central1"
  tier                      = "db-n1-standard-1"
  availability_type         = "REGIONAL"

  // Networking configuration
  enable_private_ip         = true
  private_network_self_link = "projects/your-gcp-project-id/global/networks/your-vpc-name"

  // Create an initial database
  databases = [
    {
      name    = "app_db",
      charset = "UTF8"
    }
  ]

  // Create a user with a randomly generated password
  users = [
    {
      name = "app_user"
    }
  ]

  // Example of a read replica
  read_replicas = [
    {
      name = "my-postgres-instance-replica-1"
      tier = "db-n1-standard-1"
      zone = "us-central1-b"
    }
  ]
}
```

## Requirements

The following requirements are needed by this module.

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.40.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |

## Providers

The following providers are used by this module.

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.40.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |

## Resources

The following resources are used by this module.

| Name | Type |
|------|------|
| [google_sql_database.databases](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | resource |
| [google_sql_database_instance.primary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_database_instance.replicas](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_user.users](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
| [random_password.root_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.user_passwords](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

The following input variables are supported:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_ip_range_name"></a> [allocated\_ip\_range\_name](#input\_allocated\_ip\_range\_name) | The name of the allocated IP range for private services access, if required. | `string` | `null` | no |
| <a name="input_authorized_networks"></a> [authorized\_networks](#input\_authorized\_networks) | A list of authorized networks for public IP access. Each object can have `value` (CIDR), `name`, and `expiration_time`. | <pre>list(object({<br>    value           = string<br>    name            = optional(string)<br>    expiration_time = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_availability_type"></a> [availability\_type](#input\_availability\_type) | The availability type of the instance. `ZONAL` for a single-zone instance, `REGIONAL` for a high-availability instance with a failover replica. For production, `REGIONAL` is strongly recommended. | `string` | `"REGIONAL"` | no |
| <a name="input_backup_start_time"></a> [backup\_start\_time](#input\_backup\_start\_time) | The start time of the daily backup window in HH:MM format (UTC). | `string` | `"02:00"` | no |
| <a name="input_database_flags"></a> [database\_flags](#input\_database\_flags) | A list of database flags to apply to the instance. Each object should have a `name` and `value`. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | The database version to use. See the official documentation for supported versions. Examples: `POSTGRES_14`, `MYSQL_8_0`, `SQLSERVER_2019_STANDARD`. | `string` | `"POSTGRES_14"` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | A list of database objects to create in the instance. Each object can have `name`, `charset`, and `collation`. | <pre>list(object({<br>    name      = string<br>    charset   = optional(string)<br>    collation = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | If set to true, the instance cannot be accidentally deleted. This is a best practice for production instances. | `bool` | `true` | no |
| <a name="input_disk_autoresize"></a> [disk\_autoresize](#input\_disk\_autoresize) | If set to true, the storage will automatically increase when it hits a threshold. This is a best practice to prevent outages. | `bool` | `true` | no |
| <a name="input_disk_autoresize_limit"></a> [disk\_autoresize\_limit](#input\_disk\_autoresize\_limit) | The maximum size to which the disk can be automatically resized. A value of 0 means no limit. It is recommended to set a limit for cost control. | `number` | `0` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | The size of the data disk in GB. | `number` | `10` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | The type of data disk: `PD_SSD` or `PD_HDD`. | `string` | `"PD_SSD"` | no |
| <a name="input_enable_backup"></a> [enable\_backup](#input\_enable\_backup) | If set to true, automated daily backups will be enabled. | `bool` | `true` | no |
| <a name="input_enable_iam_authentication"></a> [enable\_iam\_authentication](#input\_enable\_iam\_authentication) | If set to true, allows IAM users and service accounts to authenticate to the database. This is a security best practice over password-based authentication. | `bool` | `true` | no |
| <a name="input_enable_point_in_time_recovery"></a> [enable\_point\_in\_time\_recovery](#input\_enable\_point\_in\_time\_recovery) | If set to true, point-in-time recovery will be enabled using write-ahead logs. | `bool` | `true` | no |
| <a name="input_enable_private_ip"></a> [enable\_private\_ip](#input\_enable\_private\_ip) | If set to true, the instance will have a private IP address in the specified VPC network. This is a security best practice. | `bool` | `false` | no |
| <a name="input_enable_public_ip"></a> [enable\_public\_ip](#input\_enable\_public\_ip) | If set to true, the instance will have a public IP address. Access should be restricted via `authorized_networks`. | `bool` | `false` | no |
| <a name="input_encryption_key_name"></a> [encryption\_key\_name](#input\_encryption\_key\_name) | The full resource name of a Cloud KMS key for Customer-Managed Encryption Keys (CMEK). | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The maintenance window for the instance. Object with `day` (1-7, Sun-Sat), `hour` (0-23, UTC), and `update_track` ('stable' or 'canary'). | <pre>object({<br>    day          = number<br>    hour         = number<br>    update_track = optional(string, "stable")<br>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud SQL instance. This should be unique within the project. | `string` | `"my-cloudsql-instance"` | no |
| <a name="input_private_network_self_link"></a> [private\_network\_self\_link](#input\_private\_network\_self\_link) | The self-link of the VPC network for private IP. Required if `enable_private_ip` is true. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which to create the Cloud SQL instance. | `string` | `null` | no |
| <a name="input_read_replicas"></a> [read\_replicas](#input\_read\_replicas) | A list of read replica configurations to create. Replicas inherit some settings from the primary but can be customized. | <pre>list(object({<br>    name                = string<br>    tier                = string<br>    zone                = optional(string)<br>    disk_type           = optional(string, "PD_SSD")<br>    disk_size           = optional(number)<br>    disk_autoresize     = optional(bool, true)<br>    user_labels         = optional(map(string), {})<br>    database_flags      = optional(list(object({ name = string, value = string })), [])<br>    enable_public_ip    = optional(bool, false)<br>    authorized_networks = optional(list(object({ value = string, name = optional(string) })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where the Cloud SQL instance will be created. | `string` | `"us-central1"` | no |
| <a name="input_root_password"></a> [root\_password](#input\_root\_password) | The password for the root user. If not set, a random password will be generated. | `string` | `null` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | The machine type for the instance. See the official documentation for available tiers. | `string` | `"db-g1-small"` | no |
| <a name="input_user_labels"></a> [user\_labels](#input\_user\_labels) | A map of key/value labels to apply to the instance. | `map(string)` | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | A list of user objects to create in the instance. Each object can have `name`, `password`, `host`, and `type`. If `password` is null for a `BUILT_IN` user, a random one will be generated. | <pre>list(object({<br>    name     = string<br>    password = optional(string)<br>    host     = optional(string)<br>    type     = optional(string, "BUILT_IN")<br>  }))</pre> | `[]` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone for the primary instance. Only applicable if availability\_type is ZONAL. | `string` | `null` | no |

## Outputs

The following outputs are exported:

| Name | Description | Sensitive |
|------|-------------|:---------:|
| <a name="output_generated_root_password"></a> [generated\_root\_password](#output\_generated\_root\_password) | The randomly generated root password, if `root_password` was not provided. Store this securely. | yes |
| <a name="output_generated_user_passwords"></a> [generated\_user\_passwords](#output\_generated\_user\_passwords) | A map of usernames to their randomly generated passwords for users where no password was provided. | yes |
| <a name="output_instance"></a> [instance](#output\_instance) | The full `google_sql_database_instance` resource object for the primary instance. | yes |
| <a name="output_instance_connection_name"></a> [instance\_connection\_name](#output\_instance\_connection\_name) | The connection name of the primary Cloud SQL instance, used by proxy and connectors. | no |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | The name of the primary Cloud SQL instance. | no |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | The private IP address assigned to the primary Cloud SQL instance. | no |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The public IP address assigned to the primary Cloud SQL instance. | no |
| <a name="output_read_replica_connection_names"></a> [read\_replica\_connection\_names](#output\_read\_replica\_connection\_names) | A map of read replica names to their connection names. | no |
| <a name="output_read_replicas"></a> [read\_replicas](#output\_read\_replicas) | A map of all created read replica `google_sql_database_instance` objects, keyed by their names. | yes |
| <a name="output_service_account_email_address"></a> [service\_account\_email\_address](#output\_service\_account\_email\_address) | The email address of the service account delegated to the primary Cloud SQL instance. | no |

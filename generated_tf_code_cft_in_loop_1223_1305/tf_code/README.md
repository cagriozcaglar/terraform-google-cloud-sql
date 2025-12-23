# Google Cloud SQL Terraform Module

This module provisions a Google Cloud SQL instance following enterprise best practices for security, availability, and data protection. It simplifies the creation of a Cloud SQL instance by providing a secure-by-default configuration while allowing for extensive customization.

The module supports creating databases, users (including IAM database authentication), and read replicas.

Key best practices implemented:
-   **Network Security**: Defaults to using a private IP address, discouraging public IP exposure.
-   **IAM Database Authentication**: Enabled by default for password-less, secure access using IAM principles.
-   **High Availability**: Easily configure a `REGIONAL` instance for production workloads.
-   **Data Protection**: Deletion protection and automated backups are enabled by default.
-   **Cost Control**: Automatic storage increase is enabled to prevent outages, with an optional limit for cost governance.
-   **Workload Isolation**: Supports easy configuration of read replicas to offload analytical queries.

## Usage

### Basic Example
The following example creates a simple private Cloud SQL for MySQL instance.

```terraform
module "sql_instance" {
  source           = "./" // Or a Git repository URL
  project_id       = "your-gcp-project-id"
  name             = "my-sql-instance"
  database_version = "MYSQL_8_0"
  region           = "us-central1"
  private_network  = "projects/your-gcp-project-id/global/networks/your-vpc-name"
}
```

### Advanced Example
This example creates a regional Cloud SQL for PostgreSQL instance with high availability, a database, a built-in user (with a generated password), an IAM user, and a read replica in a different region.

```terraform
module "sql_instance_advanced" {
  source             = "./"
  project_id         = "your-gcp-project-id"
  name               = "my-advanced-instance"
  database_version   = "POSTGRES_14"
  region             = "us-east1"
  availability_type  = "REGIONAL"
  tier               = "db-custom-2-8192"
  private_network    = "projects/your-gcp-project-id/global/networks/your-vpc-name"
  deletion_protection = true

  databases = [
    { name = "app_db" }
  ]

  users = [
    // Password for this user will be randomly generated
    { name = "app_user" }, 
    
    // IAM user for password-less authentication
    {
      name = "iam_user@example.com"
      type = "CLOUD_IAM_USER"
    }
  ]

  read_replicas = {
    "replica-1" = {
      region = "us-east4"
    }
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.15.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.15.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.0 |

## Resources

| Name | Type |
|------|------|
| [google_sql_database.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | resource |
| [google_sql_database_instance.primary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_database_instance.replica](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_user.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
| [random_password.root_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.user_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authorized_networks"></a> [authorized\_networks](#input\_authorized\_networks) | A list of authorized networks that can connect to the public IP. Never use `0.0.0.0/0` in production. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_availability_type"></a> [availability\_type](#input\_availability\_type) | The availability type of the SQL instance, `ZONAL` or `REGIONAL`. `REGIONAL` provides high availability by failing over to a standby instance in another zone. | `string` | `"ZONAL"` | no |
| <a name="input_backup_enabled"></a> [backup\_enabled](#input\_backup\_enabled) | Set to true to enable automated daily backups. | `bool` | `true` | no |
| <a name="input_backup_location"></a> [backup\_location](#input\_backup\_location) | The location to store automated backups. If not set, they are stored in the closest multi-region. | `string` | `null` | no |
| <a name="input_backup_start_time"></a> [backup\_start\_time](#input\_backup\_start\_time) | The start time of the daily backup window in HH:MM format from the instance's timezone. It is recommended to supplement backups with database exports for disaster recovery. | `string` | `"03:00"` | no |
| <a name="input_database_flags"></a> [database\_flags](#input\_database\_flags) | A list of database flags to apply to the instance. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | The database version to use, e.g., `MYSQL_8_0`, `POSTGRES_14`, `SQLSERVER_2019_STANDARD`. | `string` | `"MYSQL_8_0"` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | A list of databases to be created in the instance. | <pre>list(object({<br>    name      = string<br>    charset   = optional(string)<br>    collation = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Used to block accidental deletion of the instance. This is a best practice for production instances. | `bool` | `true` | no |
| <a name="input_disk_autoresize"></a> [disk\_autoresize](#input\_disk\_autoresize) | If set to true, the storage disk will be automatically increased if it runs out of space. This is a best practice to prevent outages. | `bool` | `true` | no |
| <a name="input_disk_autoresize_limit"></a> [disk\_autoresize\_limit](#input\_disk\_autoresize\_limit) | The maximum size to which the storage disk can be automatically increased. A value of 0 means no limit. Setting a limit is recommended for cost control. | `number` | `0` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | The size of the storage disk in GB. | `number` | `20` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | The type of storage disk. Can be `PD_SSD` or `PD_HDD`. | `string` | `"PD_SSD"` | no |
| <a name="input_encryption_key_name"></a> [encryption\_key\_name](#input\_encryption\_key\_name) | The self-link of the Cloud KMS key to be used for disk encryption. If not set, a Google-managed key will be used. | `string` | `null` | no |
| <a name="input_iam_authentication_enabled"></a> [iam\_authentication\_enabled](#input\_iam\_authentication\_enabled) | If true, enables IAM database authentication, allowing IAM users and service accounts to log in to the database without a password. This is a security best practice. | `bool` | `true` | no |
| <a name="input_ip_configuration_ipv4_enabled"></a> [ip\_configuration\_ipv4\_enabled](#input\_ip\_configuration\_ipv4\_enabled) | If true, the instance will be assigned a public IPv4 address. For security, it is best practice to use a private IP instead. | `bool` | `false` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Defines the maintenance window for the instance. If not set, maintenance can occur at any time. | <pre>object({<br>    day  = number # 1-7 (Monday-Sunday)<br>    hour = number # 0-23 in UTC<br>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud SQL instance. This does not include the project ID. | `string` | `"gcp-sql-instance"` | no |
| <a name="input_point_in_time_recovery_enabled"></a> [point\_in\_time\_recovery\_enabled](#input\_point\_in\_time\_recovery\_enabled) | Set to true to enable point-in-time recovery. For MySQL, this enables the `binary_log_enabled` option. For PostgreSQL and SQL Server, this enables the `point_in_time_recovery_enabled` option. Note that for some database versions, this may require other flags to be set. | `bool` | `true` | no |
| <a name="input_private_network"></a> [private\_network](#input\_private\_network) | The self-link of the VPC network to which the instance is connected for private IP. E.g., `projects/my-project/global/networks/my-vpc`. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. If not provided, the provider project is used. | `string` | `null` | no |
| <a name="input_read_replicas"></a> [read\_replicas](#input\_read\_replicas) | A map of read replica configurations. The key is the replica name suffix. Replicas inherit tier, disk size, and availability type from the primary instance and are used to offload read traffic. | <pre>map(object({<br>    region                        = optional(string)<br>    zone                          = optional(string)<br>    database_flags                = optional(list(object({ name = string, value = string })))<br>    user_labels                   = optional(map(string))<br>    ip_configuration_ipv4_enabled = optional(bool)<br>    private_network               = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where the Cloud SQL instance will be created. | `string` | `"us-central1"` | no |
| <a name="input_root_password"></a> [root\_password](#input\_root\_password) | The initial password for the root user. If not set, a random password will be generated. Note: This is only set on creation. | `string` | `null` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | The machine type to use for the instance, e.g., `db-n1-standard-1`. | `string` | `"db-n1-standard-1"` | no |
| <a name="input_user_labels"></a> [user\_labels](#input\_user\_labels) | A map of key/value user labels to assign to the instance. | `map(string)` | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | A list of users to be created in the instance. For BUILT\_IN users, if password is not set, a random one will be generated and the host defaults to '%' if not provided. For IAM users (CLOUD\_IAM\_USER or CLOUD\_IAM\_SERVICE\_ACCOUNT), the name must be an email address and password/host are not applicable. | <pre>list(object({<br>    name     = string<br>    type     = optional(string, "BUILT_IN")<br>    password = optional(string)<br>    host     = optional(string)<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|:---------:|
| <a name="output_generated_root_password"></a> [generated\_root\_password](#output\_generated\_root\_password) | The randomly generated password for the root user. Only set when `root_password` is not provided. | true |
| <a name="output_generated_user_passwords"></a> [generated\_user\_passwords](#output\_generated\_user\_passwords) | A map of usernames to their randomly generated passwords. Only users with an empty password in the input variable will be present here. | true |
| <a name="output_instance_connection_name"></a> [instance\_connection\_name](#output\_instance\_connection\_name) | The connection name of the primary instance, used by proxies and connectors. | false |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | The name of the primary Cloud SQL instance. | false |
| <a name="output_instance_self_link"></a> [instance\_self\_link](#output\_instance\_self\_link) | The URI of the primary instance. | false |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | The private IP address assigned to the primary instance. | false |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The public IP address assigned to the primary instance. | false |
| <a name="output_read_replica_details"></a> [read\_replica\_details](#output\_read\_replica\_details) | A map containing details of the created read replicas. | false |
| <a name="output_service_account_email_address"></a> [service\_account\_email\_address](#output\_service\_account\_email\_address) | The email address of the service account for this instance. | false |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

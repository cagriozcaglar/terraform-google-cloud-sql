# Google Cloud SQL Terraform Module

This module simplifies the creation and management of Google Cloud SQL instances on Google Cloud Platform. It provides a flexible and secure way to deploy PostgreSQL, MySQL, or SQL Server databases.

Key features include:
-   Creation of a primary Cloud SQL instance with a random suffix for uniqueness.
-   Support for high availability (`REGIONAL`) configurations.
-   Configuration of read replicas to scale read traffic.
-   Support for both public and private IP networking.
-   Automated backups and point-in-time recovery.
-   Support for IAM database authentication (PostgreSQL and MySQL).
-   Optional creation of an initial database and user.
-   Configurable disk settings, machine types, database flags, and maintenance windows.

## Usage

Below is a basic example of how to use the module to create a highly available PostgreSQL instance with a private IP address.

```hcl
module "sql_instance" {
  source = "./" # Replace with the module source, e.g., "github.com/your-repo/terraform-google-cloud-sql"

  project_id       = "your-gcp-project-id"
  name             = "my-database-instance"
  region           = "us-central1"
  database_version = "POSTGRES_14"
  tier             = "db-custom-2-8192"

  # For private IP, provide the VPC network self-link.
  # This is the recommended approach for production.
  vpc_network = "projects/your-gcp-project-id/global/networks/your-vpc-name"

  # Optionally create an initial database and user
  create_database = true
  database_name   = "app_db"
  create_user     = true
  user_name       = "app_user"

  # Example of setting up a read replica
  read_replicas = {
    "replica-1" = {
      tier      = "db-custom-2-8192"
      disk_size = 20
    }
  }
}
```

## Requirements

### Terraform
-   Terraform `1.3` or later.

### Providers
The following providers are required:
-   `google` version `~> 4.40`
-   `random` version `~> 3.1`

### APIs
The following APIs must be enabled on the project:
-   Cloud SQL Admin API: `sqladmin.googleapis.com`
-   Service Networking API: `servicenetworking.googleapis.com`

The module will attempt to enable these APIs for you.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-------:|:--------:|
| <a name="input_authorized_networks"></a> [authorized\_networks](#input\_authorized\_networks) | A list of authorized networks that can connect to the instance's public IP. Each network is an object with `name` and `value` (CIDR block). This should be as restrictive as possible. Avoid `0.0.0.0/0`. | `list(object({ name = string, value = string }))` | `[]` | no |
| <a name="input_availability_type"></a> [availability\_type](#input\_availability\_type) | The availability type of the Cloud SQL instance. `REGIONAL` provides high availability by creating a standby instance in a different zone. For production, `REGIONAL` is strongly recommended. `ZONAL` is suitable for development or non-critical workloads. | `string` | `"REGIONAL"` | no |
| <a name="input_backup_configuration"></a> [backup\_configuration](#input\_backup\_configuration) | Configuration for automated backups. Backups are critical for data protection. Point-in-time recovery is required for creating read replicas. | `object({ enabled = bool, start_time = optional(string), location = optional(string), point_in_time_recovery_enabled = bool })` | `{ enabled = true, point_in_time_recovery_enabled = true }` | no |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | Set to `true` to create an initial database within the instance. | `bool` | `true` | no |
| <a name="input_create_user"></a> [create\_user](#input\_create\_user) | Set to `true` to create an an initial user for the database. | `bool` | `true` | no |
| <a name="input_database_flags"></a> [database\_flags](#input\_database\_flags) | A list of database flags to apply to the instance. Each flag is an object with `name` and `value`. | `list(object({ name = string, value = string }))` | `[]` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the initial database to create. Required if `create_database` is `true`. | `string` | `"default_db"` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | The database version to use. For example, `MYSQL_8_0`, `POSTGRES_14`, `SQLSERVER_2019_STANDARD`. It is a best practice to use a recent, non-EOL version. | `string` | `"POSTGRES_14"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Used to block accidental instance deletion. It is a best practice to set this to `true` for production instances. | `bool` | `true` | no |
| <a name="input_disk_autoresize"></a> [disk\_autoresize](#input\_disk\_autoresize) | If set to `true`, the instance's storage will be automatically increased as it runs out of space. This is a best practice to prevent outages due to full disks. | `bool` | `true` | no |
| <a name="input_disk_autoresize_limit"></a> [disk\_autoresize\_limit](#input\_disk\_autoresize\_limit) | The maximum size to which storage can be automatically increased. A value of `0` means no limit. It is a best practice to set a non-zero limit for cost control. | `number` | `0` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | The initial size of the disk in GB. | `number` | `20` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | The type of storage. `PD_SSD` is recommended for most workloads. `PD_HDD` is a lower-cost option for less performance-sensitive workloads. | `string` | `"PD_SSD"` | no |
| <a name="input_enable_public_ip"></a> [enable\_public\_ip](#input\_enable\_public\_ip) | Set to `true` to enable a public IP address on the instance. For security, the best practice is to keep this `false` and connect via private IP. If not set (`null`), a public IP will be enabled if `vpc_network` is not provided. | `bool` | `null` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | Enables IAM database authentication for PostgreSQL and MySQL instances, allowing GCP IAM users and service accounts to log in to the database without a password. This is a security best practice. | `bool` | `true` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The preferred maintenance window for the instance. If not set, maintenance can occur at any time. Format is an object with `day` (1-7, Sunday is 7) and `hour` (0-23). | `object({ day = number, hour = number })` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The base name for the Cloud SQL instance. A random suffix will be appended to this name. | `string` | `"cloudsql-instance"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. If not provided, the provider project is used. | `string` | `null` | no |
| <a name="input_read_replicas"></a> [read\_replicas](#input\_read\_replicas) | A map of read replica configurations to create, keyed by a logical name for the replica. Offloading read traffic to replicas is a best practice for high-traffic applications. | `map(object({ tier = string, disk_type = optional(string, "PD_SSD"), disk_autoresize = optional(bool, true), disk_autoresize_limit = optional(number, 0), disk_size = optional(number) }))` | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where the Cloud SQL instance will be created. | `string` | `"us-central1"` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | The machine type to use. For example, `db-n1-standard-1`. | `string` | `"db-g1-small"` | no |
| <a name="input_user_name"></a> [user\_name](#input\_user\_name) | The name of the initial user to create. Required if `create_user` is `true`. | `string` | `"default_user"` | no |
| <a name="input_user_password"></a> [user\_password](#input\_user\_password) | The password for the initial user. If not provided, a random password will be generated. It is strongly recommended to manage secrets using a secret manager like Google Secret Manager. | `string` | `null` | no |
| <a name="input_user_type"></a> [user\_type](#input\_user\_type) | The type of the user. Applicable only for SQL Server instances. Can be `BUILT_IN`, `SQL_USER`, or `IAM_USER`. | `string` | `null` | no |
| <a name="input_vpc_network"></a> [vpc\_network](#input\_vpc\_network) | The full self-link of the VPC network to which the instance will be connected for private IP. If not provided, a public IP will be created. One of `vpc_network` or `enable_public_ip` must be specified. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | The name of the initial database created, if any. |
| <a name="output_generated_user_password"></a> [generated\_user\_password](#output\_generated\_user\_password) | The password for the initial user if it was randomly generated. |
| <a name="output_instance"></a> [instance](#output\_instance) | The full `google_sql_database_instance` resource object for the primary instance. |
| <a name="output_instance_connection_name"></a> [instance\_connection\_name](#output\_instance\_connection\_name) | The connection name of the primary instance, used by the Cloud SQL Proxy. |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | The globally unique name of the primary Cloud SQL instance. |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | The private IP address of the primary instance. |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The public IP address of the primary instance, if enabled. |
| <a name="output_read_replicas"></a> [read\_replicas](#output\_read\_replicas) | A map of all the `google_sql_database_instance` read replica resource objects, keyed by their logical name. |
| <a name="output_user_name"></a> [user\_name](#output\_user\_name) | The name of the initial user created, if any. |

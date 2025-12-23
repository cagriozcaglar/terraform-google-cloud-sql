# Terraform Google Cloud SQL Module

This module handles the deployment of a Google Cloud SQL instance, following Google's best practices for security and reliability. It simplifies the creation of a primary instance, read replicas, databases, and users (both native and IAM).

The module is designed with enterprise needs in mind, providing defaults for:
-   High Availability (`REGIONAL`)
-   Deletion Protection
-   Private Networking
-   Automated Backups and Point-in-Time Recovery
-   Automated storage increases
-   Enforced IAM Database Authentication

## Usage

Below is a basic example of how to use the module to create a private, highly-available PostgreSQL instance.

```hcl
module "sql" {
  source  = "path/to/this/module"

  project_id       = "your-gcp-project-id"
  name             = "my-app-db"
  region           = "us-central1"
  database_version = "POSTGRES_15"
  private_network  = "projects/your-gcp-project-id/global/networks/your-vpc-name"
  tier             = "db-n1-standard-2"

  databases = [
    {
      name      = "app_main_db"
      charset   = "UTF8"
      collation = "en_US.UTF8"
    }
  ]

  users = [
    {
      name = "app_user"
      type = "BUILT_IN"
    },
    {
      name = "gcp-iam-user@example.com"
      type = "CLOUD_IAM_USER"
    }
  ]

  read_replicas = {
    "replica-1" = {
      tier = "db-n1-standard-1"
    }
  }
}
```

## Requirements

The following requirements are needed by this module.

### Software

The following software is required to use this module:
- [Terraform](https://www.terraform.io/downloads.html): `>= 1.3`

### Providers

The following providers are required by this module:
- **google:** `>= 4.50.0`
- **random:** `>= 3.1.0`

### APIs

The following APIs must be enabled in the project:
-   Cloud SQL Admin API: `sqladmin.googleapis.com`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_type"></a> [availability\_type](#input\_availability\_type) | The availability type of the instance. 'REGIONAL' provides high availability. 'ZONAL' is a single-zone instance. | `string` | `"REGIONAL"` | no |
| <a name="input_authorized_networks"></a> [authorized\_networks](#input\_authorized\_networks) | A list of objects representing authorized networks. Each object has 'name' and 'value' (CIDR notation). | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_backup_configuration"></a> [backup\_configuration](#input\_backup\_configuration) | Configuration for automated backups. | <pre>object({<br>    enabled                        = bool<br>    start_time                     = string<br>    location                       = string<br>    point_in_time_recovery_enabled = bool<br>    transaction_log_retention_days = number<br>  })</pre> | <pre>{<br>  "enabled": true,<br>  "location": null,<br>  "point_in_time_recovery_enabled": true,<br>  "start_time": "03:00",<br>  "transaction_log_retention_days": 7<br>}</pre> | no |
| <a name="input_database_flags"></a> [database\_flags](#input\_database\_flags) | A list of database flags to apply to the instance. Each object has 'name' and 'value'. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | The database engine and version to use, e.g., 'POSTGRES\_15' or 'MYSQL\_8\_0'. | `string` | n/a | yes |
| <a name="input_databases"></a> [databases](#input\_databases) | A list of databases to create on the instance. Each object has 'name', and optional 'charset' and 'collation'. | <pre>list(object({<br>    name      = string<br>    charset   = optional(string)<br>    collation = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Enables deletion protection for the instance. | `bool` | `true` | no |
| <a name="input_disk_autoresize"></a> [disk\_autoresize](#input\_disk\_autoresize) | If set to true, storage will automatically increase when 90% full. | `bool` | `true` | no |
| <a name="input_disk_autoresize_limit"></a> [disk\_autoresize\_limit](#input\_disk\_autoresize\_limit) | The maximum size to which storage can be automatically increased. A value of 0 means no limit. | `number` | `0` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | The initial size of the disk in GB. | `number` | `10` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | The type of storage disk. Can be 'PD\_SSD' or 'PD\_HDD'. | `string` | `"PD_SSD"` | no |
| <a name="input_edition"></a> [edition](#input\_edition) | The edition of the instance, e.g., 'ENTERPRISE\_PLUS'. If null, the default edition is used. | `string` | `null` | no |
| <a name="input_enable_public_ip"></a> [enable\_public\_ip](#input\_enable\_public\_ip) | Set to true to assign a public IP address to the instance. | `bool` | `false` | no |
| <a name="input_encryption_key_name"></a> [encryption\_key\_name](#input\_encryption\_key\_name) | The full path to the customer-managed encryption key (CMEK) to use for disk encryption. | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The maintenance window for the instance. Object with 'day' (1-7), 'hour' (0-23), and 'update\_track'. | <pre>object({<br>    day          = number<br>    hour         = number<br>    update_track = string<br>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud SQL instance. | `string` | n/a | yes |
| <a name="input_private_network"></a> [private\_network](#input\_private\_network) | The self-link of the VPC network to attach the instance to for private IP. If null, no private IP is configured. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs. | `string` | n/a | yes |
| <a name="input_read_replicas"></a> [read\_replicas](#input\_read\_replicas) | A map of read replica configurations to create. The key will be used as a suffix for the replica name. | <pre>map(object({<br>    tier                  = string<br>    disk_type             = optional(string, null)<br>    disk_autoresize       = optional(bool, null)<br>    disk_autoresize_limit = optional(number, null)<br>    enable_public_ip      = optional(bool, null)<br>    deletion_protection   = optional(bool, null)<br>  }))</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where the Cloud SQL instance will be created. | `string` | n/a | yes |
| <a name="input_tier"></a> [tier](#input\_tier) | The machine type for the instance, e.g., 'db-n1-standard-1'. | `string` | `"db-n1-standard-1"` | no |
| <a name="input_users"></a> [users](#input\_users) | A list of users to create. Each object has 'name', 'host', and 'type'. For 'BUILT\_IN' users, passwords are auto-generated. For 'CLOUD\_IAM\_USER' or 'CLOUD\_IAM\_SERVICE\_ACCOUNT', the name should be an email address. | <pre>list(object({<br>    name = string<br>    host = optional(string)<br>    type = optional(string, "BUILT_IN")<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|:---------:|
| <a name="output_generated_user_passwords"></a> [generated\_user\_passwords](#output\_generated\_user\_passwords) | A map of generated passwords for the 'BUILT\_IN' database users, keyed by username. Treat this output as sensitive. | true |
| <a name="output_instance"></a> [instance](#output\_instance) | The full resource object for the primary Cloud SQL instance. | false |
| <a name="output_instance_connection_name"></a> [instance\_connection\_name](#output\_instance\_connection\_name) | The connection name of the primary Cloud SQL instance. | false |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | The private IP address of the primary Cloud SQL instance. | false |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The public IP address of the primary Cloud SQL instance. | false |
| <a name="output_replica_connection_names"></a> [replica\_connection\_names](#output\_replica\_connection\_names) | A map of connection names for the read replica instances, keyed by their suffix. | false |
| <a name="output_replicas"></a> [replicas](#output\_replicas) | A map of the full resource objects for the read replica instances, keyed by their suffix. | false |

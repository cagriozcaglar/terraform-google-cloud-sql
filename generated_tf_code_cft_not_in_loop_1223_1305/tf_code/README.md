# Google Cloud SQL Terraform Module

This module handles the deployment of a Google Cloud SQL instance, following enterprise best practices. It simplifies the creation of a primary instance, read replicas, databases, and users, while providing sensible defaults for security and reliability.

Key features include:
-   Configuration of a primary instance with optional high-availability (`REGIONAL`).
-   Support for private networking via VPC Peering.
-   Built-in support for IAM Database Authentication (enabled by default).
-   Automated backups and Point-in-Time Recovery (PITR).
-   Automatic disk resizing to prevent storage-related outages.
-   Creation of multiple databases and users (including IAM users/service accounts).
-   Automatic generation of secure passwords for built-in users if not provided.
-   Creation of one or more read replicas.
-   Instance deletion protection enabled by default for production safety.

## Requirements

Before this module can be used on a project, you must ensure that the following APIs are enabled:

-   Cloud SQL Admin API: `sqladmin.googleapis.com`
-   Compute Engine API: `compute.googleapis.com` (for VPC networking)
-   Service Networking API: `servicenetworking.googleapis.com` (for VPC networking)

## Usage

Here are some examples of how to use the module.

### Basic Zonal PostgreSQL Instance with Public IP

This example creates a simple PostgreSQL instance with a database and a user. A random password will be generated for the user.

```hcl
module "cloudsql_postgres" {
  source           = "./" // Or a Git repository
  name             = "my-postgres-instance"
  database_version = "POSTGRES_15"
  region           = "us-central1"
  tier             = "db-g1-small"

  databases = [
    {
      name = "my-application-db"
    }
  ]

  users = [
    {
      name = "my-application-user"
    }
  ]
}
```

### Production-Ready Regional MySQL Instance with Private IP

This example demonstrates a more complex setup for a production environment. It creates a highly available MySQL 8.0 instance with a private IP address, a read replica, and an IAM user.

```hcl
module "cloudsql_mysql_production" {
  source                      = "./" // Or a Git repository
  project_id                  = "your-gcp-project-id"
  name                        = "production-mysql-db"
  database_version            = "MYSQL_8_0"
  region                      = "us-east1"
  tier                        = "db-n1-standard-2"
  availability_type           = "REGIONAL"
  deletion_protection_enabled = true

  // Network Configuration
  enable_public_ip          = false
  private_network_self_link = "projects/your-gcp-project-id/global/networks/your-vpc-name"

  // Databases and Users
  databases = [
    {
      name = "production_main_db"
    }
  ]

  users = [
    {
      name = "iam-user@example.com"
      type = "CLOUD_IAM_USER"
    }
  ]

  // Read Replica Configuration
  read_replicas = [
    {
      name = "production-mysql-db-replica-1"
      tier = "db-n1-standard-2"
      ip_configuration = {
        private_network_self_link = "projects/your-gcp-project-id/global/networks/your-vpc-name"
      }
    }
  ]
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| availability\_type | The availability type of the Cloud SQL instance. `REGIONAL` provides high availability by creating a standby instance in a different zone. For all production workloads, this should be set to `REGIONAL`. `ZONAL` is suitable for development or non-critical workloads. | `string` | `"ZONAL"` | no |
| authorized\_networks | A list of objects representing authorized networks. Used to restrict access to the public IP. Never use `0.0.0.0/0` in production. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| backup\_location | The location to store the backups. If not set, backups are stored in the same multi-region as the instance. | `string` | `null` | no |
| backup\_start\_time | The start time of the daily backup window, in UTC (HH:MM format). | `string` | `"03:00"` | no |
| backups\_enabled | Set to `true` to enable automated daily backups. | `bool` | `true` | no |
| database\_flags | A list of database flags to apply to the instance. Each flag is an object with a `name` and `value`. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| database\_version | The database version to use. See the official documentation for the list of supported versions. Examples: `POSTGRES_15`, `MYSQL_8_0`, `SQLSERVER_2019_STANDARD`. | `string` | `"POSTGRES_15"` | no |
| databases | A list of databases to create in the instance. Each database is an object with a `name`, and optional `charset` and `collation`. | <pre>list(object({<br>    name      = string<br>    charset   = optional(string)<br>    collation = optional(string)<br>  }))</pre> | `[]` | no |
| deletion\_protection\_enabled | Used to block accidental deletion of the instance. A best practice for production environments. | `bool` | `true` | no |
| disk\_autoresize | If set to true, the disk will be automatically resized when it's full. This is a best practice to prevent service disruptions. | `bool` | `true` | no |
| disk\_autoresize\_limit | The maximum size to which the disk can be auto-resized. A value of 0 means no limit. Setting a non-zero limit is a best practice for cost control. | `number` | `0` | no |
| disk\_size | The initial size of the disk in gigabytes. | `number` | `20` | no |
| disk\_type | The type of disk to use. `PD_SSD` is recommended for most workloads. | `string` | `"PD_SSD"` | no |
| enable\_public\_ip | If set to true, the instance will have a public IP address. For security in production environments, it is strongly recommended to set this to `false` and connect via Private IP. The default value is `true` to make the module easier to use for development purposes. | `bool` | `true` | no |
| encryption\_key\_name | The full path to the CMEK key used to encrypt the database. If not specified, Google-managed encryption is used. | `string` | `null` | no |
| iam\_database\_authentication\_enabled | If set to true, enables IAM database authentication, allowing users to connect using their IAM credentials instead of passwords. This is a security best practice. | `bool` | `true` | no |
| name | The name of the Cloud SQL instance. This does not include the project ID. | `string` | `"cloudsql-instance-0"` | no |
| pitr\_enabled | Set to `true` to enable Point-in-Time Recovery. This requires `backups_enabled` to be `true`. | `bool` | `true` | no |
| private\_network\_self\_link | The self-link of the VPC network to which the instance will be connected for private IP access. Required if `enable_public_ip` is `false`. | `string` | `null` | no |
| project\_id | The ID of the project in which the resource belongs. If null, the provider's project will be used. | `string` | `null` | no |
| read\_replicas | A list of read replicas to create. Each replica is an object with its own configuration that can override the primary's settings. | <pre>list(object({<br>    name                  = string<br>    tier                  = string<br>    zone                  = optional(string)<br>    disk_size             = optional(number)<br>    disk_type             = optional(string)<br>    disk_autoresize       = optional(bool, true)<br>    disk_autoresize_limit = optional(number, 0)<br>    user_labels           = optional(map(string), {})<br>    ip_configuration = optional(object({<br>      enable_public_ip          = optional(bool, false)<br>      private_network_self_link = optional(string)<br>      authorized_networks = optional(list(object({<br>        name  = string<br>        value = string<br>      })), [])<br>    }), {})<br>  }))</pre> | `[]` | no |
| region | The region where the Cloud SQL instance will be created. | `string` | `"us-central1"` | no |
| tier | The machine type to use. See the official documentation for the list of supported tiers. | `string` | `"db-g1-small"` | no |
| transaction\_log\_retention\_days | The number of days to retain transaction logs for Point-in-Time Recovery. Must be between 1 and 7. | `number` | `7` | no |
| user\_labels | A map of labels to assign to the instance. | `map(string)` | `{}` | no |
| users | A list of users to create in the instance. Each user is an object with a `name`, and optional `password`, `host` and `type`. If `password` is not provided for a `BUILT_IN` user, a random one will be generated. The `type` can be `BUILT_IN`, `CLOUD_IAM_USER`, or `CLOUD_IAM_SERVICE_ACCOUNT`. | <pre>list(object({<br>    name     = string<br>    password = optional(string)<br>    host     = optional(string)<br>    type     = optional(string, "BUILT_IN")<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| databases | A map of the `google_sql_database` resources created, keyed by their names. |
| generated\_user\_passwords | A map of passwords generated for users that did not have one specified. The map is keyed by username. (Sensitive) |
| instance\_connection\_name | The connection name of the primary Cloud SQL instance, used for connecting via the Cloud SQL Auth Proxy. |
| instance\_name | The name of the primary Cloud SQL instance. |
| primary\_instance | The full `google_sql_database_instance` resource object for the primary instance. (Sensitive) |
| private\_ip\_address | The private IP address of the primary Cloud SQL instance. |
| public\_ip\_address | The public IP address of the primary Cloud SQL instance. |
| read\_replica\_instances | A map of the full `google_sql_database_instance` resource objects for the read replicas, keyed by their names. (Sensitive) |
| service\_account\_email\_address | The email address of the service account that is used to access the Cloud SQL instance. |
| users | A map of the `google_sql_user` resources created, keyed by their names. (Sensitive) |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

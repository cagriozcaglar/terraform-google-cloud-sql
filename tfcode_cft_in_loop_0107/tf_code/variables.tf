# This file defines the input variables for the Terraform module.
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# A list of authorized networks that can connect to the instance's public IP. Each network is an object with `name` and `value` (CIDR block). This should be as restrictive as possible. Avoid `0.0.0.0/0`.
variable "authorized_networks" {
  description = "A list of authorized networks that can connect to the instance's public IP. Each network is an object with `name` and `value` (CIDR block). This should be as restrictive as possible. Avoid `0.0.0.0/0`."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# The availability type of the Cloud SQL instance. `REGIONAL` provides high availability by creating a standby instance in a different zone. For production, `REGIONAL` is strongly recommended. `ZONAL` is suitable for development or non-critical workloads.
variable "availability_type" {
  description = "The availability type of the Cloud SQL instance. `REGIONAL` provides high availability by creating a standby instance in a different zone. For production, `REGIONAL` is strongly recommended. `ZONAL` is suitable for development or non-critical workloads."
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "The availability_type must be either ZONAL or REGIONAL."
  }
}

# Configuration for automated backups. Backups are critical for data protection. Point-in-time recovery is required for creating read replicas.
variable "backup_configuration" {
  description = "Configuration for automated backups. Backups are critical for data protection. Point-in-time recovery is required for creating read replicas."
  type = object({
    enabled                        = bool
    start_time                     = optional(string) # "HH:MM" format
    location                       = optional(string)
    point_in_time_recovery_enabled = bool
  })
  default = {
    enabled                        = true
    point_in_time_recovery_enabled = true
  }
}

# Set to `true` to create an initial database within the instance.
variable "create_database" {
  description = "Set to `true` to create an initial database within the instance."
  type        = bool
  default     = true
}

# Set to `true` to create an an initial user for the database.
variable "create_user" {
  description = "Set to `true` to create an an initial user for the database."
  type        = bool
  default     = true
}

# A list of database flags to apply to the instance. Each flag is an object with `name` and `value`.
variable "database_flags" {
  description = "A list of database flags to apply to the instance. Each flag is an object with `name` and `value`."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# The name of the initial database to create. Required if `create_database` is `true`.
variable "database_name" {
  description = "The name of the initial database to create. Required if `create_database` is `true`."
  type        = string
  default     = "default_db"
}

# The database version to use. For example, `MYSQL_8_0`, `POSTGRES_14`, `SQLSERVER_2019_STANDARD`. It is a best practice to use a recent, non-EOL version.
variable "database_version" {
  description = "The database version to use. For example, `MYSQL_8_0`, `POSTGRES_14`, `SQLSERVER_2019_STANDARD`. It is a best practice to use a recent, non-EOL version."
  type        = string
  default     = "POSTGRES_14"
}

# Used to block accidental instance deletion. It is a best practice to set this to `true` for production instances.
variable "deletion_protection" {
  description = "Used to block accidental instance deletion. It is a best practice to set this to `true` for production instances."
  type        = bool
  default     = true
}

# If set to `true`, the instance's storage will be automatically increased as it runs out of space. This is a best practice to prevent outages due to full disks.
variable "disk_autoresize" {
  description = "If set to `true`, the instance's storage will be automatically increased as it runs out of space. This is a best practice to prevent outages due to full disks."
  type        = bool
  default     = true
}

# The maximum size to which storage can be automatically increased. A value of `0` means no limit. It is a best practice to set a non-zero limit for cost control.
variable "disk_autoresize_limit" {
  description = "The maximum size to which storage can be automatically increased. A value of `0` means no limit. It is a best practice to set a non-zero limit for cost control."
  type        = number
  default     = 0
}

# The initial size of the disk in GB.
variable "disk_size" {
  description = "The initial size of the disk in GB."
  type        = number
  default     = 20
}

# The type of storage. `PD_SSD` is recommended for most workloads. `PD_HDD` is a lower-cost option for less performance-sensitive workloads.
variable "disk_type" {
  description = "The type of storage. `PD_SSD` is recommended for most workloads. `PD_HDD` is a lower-cost option for less performance-sensitive workloads."
  type        = string
  default     = "PD_SSD"
}

# Set to `true` to enable a public IP address on the instance. For security, the best practice is to keep this `false` and connect via private IP. If not set (`null`), a public IP will be enabled if `vpc_network` is not provided.
variable "enable_public_ip" {
  description = "Set to `true` to enable a public IP address on the instance. For security, the best practice is to keep this `false` and connect via private IP. If not set (`null`), a public IP will be enabled if `vpc_network` is not provided."
  type        = bool
  default     = null
}

# Enables IAM database authentication for PostgreSQL and MySQL instances, allowing GCP IAM users and service accounts to log in to the database without a password. This is a security best practice.
variable "iam_database_authentication_enabled" {
  description = "Enables IAM database authentication for PostgreSQL and MySQL instances, allowing GCP IAM users and service accounts to log in to the database without a password. This is a security best practice."
  type        = bool
  default     = true
}

# The preferred maintenance window for the instance. If not set, maintenance can occur at any time. Format is an object with `day` (1-7, Sunday is 7) and `hour` (0-23).
variable "maintenance_window" {
  description = "The preferred maintenance window for the instance. If not set, maintenance can occur at any time. Format is an object with `day` (1-7, Sunday is 7) and `hour` (0-23)."
  type = object({
    day  = number
    hour = number
  })
  default = null
}

# The base name for the Cloud SQL instance. A random suffix will be appended to this name.
variable "name" {
  description = "The base name for the Cloud SQL instance. A random suffix will be appended to this name."
  type        = string
  default     = "cloudsql-instance"
}

# The ID of the project in which the resource belongs. If not provided, the provider project is used.
variable "project_id" {
  description = "The ID of the project in which the resource belongs. If not provided, the provider project is used."
  type        = string
  default     = null
}

# A map of read replica configurations to create, keyed by a logical name for the replica. Offloading read traffic to replicas is a best practice for high-traffic applications.
variable "read_replicas" {
  description = "A map of read replica configurations to create, keyed by a logical name for the replica. Offloading read traffic to replicas is a best practice for high-traffic applications."
  type = map(object({
    tier                  = string
    disk_type             = optional(string, "PD_SSD")
    disk_autoresize       = optional(bool, true)
    disk_autoresize_limit = optional(number, 0)
    disk_size             = optional(number)
  }))
  default = {}
}

# The region where the Cloud SQL instance will be created.
variable "region" {
  description = "The region where the Cloud SQL instance will be created."
  type        = string
  default     = "us-central1"
}

# The machine type to use. For example, `db-n1-standard-1`.
variable "tier" {
  description = "The machine type to use. For example, `db-n1-standard-1`."
  type        = string
  default     = "db-g1-small"
}

# The name of the initial user to create. Required if `create_user` is `true`.
variable "user_name" {
  description = "The name of the initial user to create. Required if `create_user` is `true`."
  type        = string
  default     = "default_user"
}

# The password for the initial user. If not provided, a random password will be generated. It is strongly recommended to manage secrets using a secret manager like Google Secret Manager.
variable "user_password" {
  description = "The password for the initial user. If not provided, a random password will be generated. It is strongly recommended to manage secrets using a secret manager like Google Secret Manager."
  type        = string
  sensitive   = true
  default     = null
}

# The type of the user. Applicable only for SQL Server instances. Can be `BUILT_IN`, `SQL_USER`, or `IAM_USER`.
variable "user_type" {
  description = "The type of the user. Applicable only for SQL Server instances. Can be `BUILT_IN`, `SQL_USER`, or `IAM_USER`."
  type        = string
  default     = null
}

# The full self-link of the VPC network to which the instance will be connected for private IP. If not provided, a public IP will be created. One of `vpc_network` or `enable_public_ip` must be specified.
variable "vpc_network" {
  description = "The full self-link of the VPC network to which the instance will be connected for private IP. If not provided, a public IP will be created. One of `vpc_network` or `enable_public_ip` must be specified."
  type        = string
  default     = null
}

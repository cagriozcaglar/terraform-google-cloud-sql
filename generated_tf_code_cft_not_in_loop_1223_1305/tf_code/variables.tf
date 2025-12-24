# This file defines the input variables for the Terraform module.
# These variables allow users to customize the Cloud SQL instance and its related resources.
# Each variable has a type, a description, and an optional default value.
# Descriptions are aligned with best practices to guide users toward secure and robust configurations.

# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
variable "project_id" {
  description = "The ID of the project in which the resource belongs. If null, the provider's project will be used."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the Cloud SQL instance. This does not include the project ID."
  type        = string
  default     = "cloudsql-instance-0"
}

variable "database_version" {
  description = "The database version to use. See the official documentation for the list of supported versions. Examples: `POSTGRES_15`, `MYSQL_8_0`, `SQLSERVER_2019_STANDARD`."
  type        = string
  default     = "POSTGRES_15"
}

variable "region" {
  description = "The region where the Cloud SQL instance will be created."
  type        = string
  default     = "us-central1"
}

variable "tier" {
  description = "The machine type to use. See the official documentation for the list of supported tiers."
  type        = string
  default     = "db-g1-small"
}

variable "availability_type" {
  description = "The availability type of the Cloud SQL instance. `REGIONAL` provides high availability by creating a standby instance in a different zone. For all production workloads, this should be set to `REGIONAL`. `ZONAL` is suitable for development or non-critical workloads."
  type        = string
  default     = "ZONAL"
}

variable "deletion_protection_enabled" {
  description = "Used to block accidental deletion of the instance. A best practice for production environments."
  type        = bool
  default     = true
}

variable "disk_autoresize" {
  description = "If set to true, the disk will be automatically resized when it's full. This is a best practice to prevent service disruptions."
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "The maximum size to which the disk can be auto-resized. A value of 0 means no limit. Setting a non-zero limit is a best practice for cost control."
  type        = number
  default     = 0
}

variable "disk_size" {
  description = "The initial size of the disk in gigabytes."
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "The type of disk to use. `PD_SSD` is recommended for most workloads."
  type        = string
  default     = "PD_SSD"
}

variable "user_labels" {
  description = "A map of labels to assign to the instance."
  type        = map(string)
  default     = {}
}

variable "encryption_key_name" {
  description = "The full path to the CMEK key used to encrypt the database. If not specified, Google-managed encryption is used."
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = "If set to true, enables IAM database authentication, allowing users to connect using their IAM credentials instead of passwords. This is a security best practice."
  type        = bool
  default     = true
}

variable "enable_public_ip" {
  description = "If set to true, the instance will have a public IP address. For security in production environments, it is strongly recommended to set this to `false` and connect via Private IP. The default value is `true` to make the module easier to use for development purposes."
  type        = bool
  default     = true
}

variable "private_network_self_link" {
  description = "The self-link of the VPC network to which the instance will be connected for private IP access. Required if `enable_public_ip` is `false`."
  type        = string
  default     = null
}

variable "authorized_networks" {
  description = "A list of objects representing authorized networks. Used to restrict access to the public IP. Never use `0.0.0.0/0` in production."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "backups_enabled" {
  description = "Set to `true` to enable automated daily backups."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "The start time of the daily backup window, in UTC (HH:MM format)."
  type        = string
  default     = "03:00"
}

variable "backup_location" {
  description = "The location to store the backups. If not set, backups are stored in the same multi-region as the instance."
  type        = string
  default     = null
}

variable "pitr_enabled" {
  description = "Set to `true` to enable Point-in-Time Recovery. This requires `backups_enabled` to be `true`."
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "The number of days to retain transaction logs for Point-in-Time Recovery. Must be between 1 and 7."
  type        = number
  default     = 7
}

variable "database_flags" {
  description = "A list of database flags to apply to the instance. Each flag is an object with a `name` and `value`."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "databases" {
  description = "A list of databases to create in the instance. Each database is an object with a `name`, and optional `charset` and `collation`."
  type = list(object({
    name      = string
    charset   = optional(string)
    collation = optional(string)
  }))
  default = []
}

variable "users" {
  description = "A list of users to create in the instance. Each user is an object with a `name`, and optional `password`, `host` and `type`. If `password` is not provided for a `BUILT_IN` user, a random one will be generated. The `type` can be `BUILT_IN`, `CLOUD_IAM_USER`, or `CLOUD_IAM_SERVICE_ACCOUNT`."
  type = list(object({
    name     = string
    password = optional(string)
    host     = optional(string)
    type     = optional(string, "BUILT_IN")
  }))
  default = []
}

variable "read_replicas" {
  description = "A list of read replicas to create. Each replica is an object with its own configuration that can override the primary's settings."
  type = list(object({
    name                  = string
    tier                  = string
    zone                  = optional(string)
    disk_size             = optional(number)
    disk_type             = optional(string)
    disk_autoresize       = optional(bool, true)
    disk_autoresize_limit = optional(number, 0)
    user_labels           = optional(map(string), {})
    ip_configuration = optional(object({
      enable_public_ip          = optional(bool, false)
      private_network_self_link = optional(string)
      authorized_networks = optional(list(object({
        name  = string
        value = string
      })), [])
    }), {})
  }))
  default = []
}

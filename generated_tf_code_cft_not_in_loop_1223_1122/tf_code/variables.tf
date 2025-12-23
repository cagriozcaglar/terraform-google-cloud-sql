# This file contains the input variable definitions for the Cloud SQL module.

# The availability type of the Cloud SQL instance. Use 'REGIONAL' for production for high availability.
variable "availability_type" {
  description = "The availability type of the instance. 'REGIONAL' provides high availability. 'ZONAL' is a single-zone instance."
  type        = string
  default     = "REGIONAL"
}

# Configuration for automated backups. Backups are critical for data recovery but should be supplemented with exports for disaster recovery.
variable "backup_configuration" {
  description = "Configuration for automated backups."
  type = object({
    enabled                        = bool
    start_time                     = string
    location                       = string
    point_in_time_recovery_enabled = bool
    transaction_log_retention_days = number
  })
  default = {
    enabled                        = true
    start_time                     = "03:00"
    location                       = null
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 7
  }
}

# The database version to use. See https://cloud.google.com/sql/docs/db-versions for valid options.
variable "database_version" {
  description = "The database engine and version to use, e.g., 'POSTGRES_15' or 'MYSQL_8_0'."
  type        = string
}

# Protects the instance from accidental deletion. Recommended to be true for production.
variable "deletion_protection" {
  description = "Enables deletion protection for the instance."
  type        = bool
  default     = true
}

# Enables automatic storage increases. Best practice to prevent outages due to full disks.
variable "disk_autoresize" {
  description = "If set to true, storage will automatically increase when 90% full."
  type        = bool
  default     = true
}

# The limit for disk autoresize in GB. A value of 0 means no limit. A non-zero value is recommended for cost control.
variable "disk_autoresize_limit" {
  description = "The maximum size to which storage can be automatically increased. A value of 0 means no limit."
  type        = number
  default     = 0
}

# The initial size of the data disk in GB.
variable "disk_size" {
  description = "The initial size of the disk in GB."
  type        = number
  default     = 10
}

# The type of data disk: 'PD_SSD' or 'PD_HDD'. 'PD_SSD' is recommended for most workloads.
variable "disk_type" {
  description = "The type of storage disk. Can be 'PD_SSD' or 'PD_HDD'."
  type        = string
  default     = "PD_SSD"
}

# The edition of the instance, e.g., 'ENTERPRISE_PLUS'. Determines features and pricing.
variable "edition" {
  description = "The edition of the instance, e.g., 'ENTERPRISE_PLUS'. If null, the default edition is used."
  type        = string
  default     = null
}

# Whether to assign a public IP address to the instance. It is recommended to keep this false and use the Cloud SQL Auth Proxy.
variable "enable_public_ip" {
  description = "Set to true to assign a public IP address to the instance."
  type        = bool
  default     = false
}

# The self-link of a customer-managed encryption key (CMEK) to use for the instance.
variable "encryption_key_name" {
  description = "The full path to the customer-managed encryption key (CMEK) to use for disk encryption."
  type        = string
  default     = null
}

# The maintenance window for the instance.
variable "maintenance_window" {
  description = "The maintenance window for the instance. Object with 'day' (1-7), 'hour' (0-23), and 'update_track'."
  type = object({
    day          = number
    hour         = number
    update_track = string
  })
  default = null
}

# The name of the Cloud SQL instance.
variable "name" {
  description = "The name of the Cloud SQL instance."
  type        = string
}

# The self-link of the VPC network to associate with the instance for private IP access.
variable "private_network" {
  description = "The self-link of the VPC network to attach the instance to for private IP. If null, no private IP is configured."
  type        = string
  default     = null
}

# The ID of the Google Cloud project where the Cloud SQL instance will be created.
variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

# A map of read replica configurations. The key is a suffix for the replica name.
variable "read_replicas" {
  description = "A map of read replica configurations to create. The key will be used as a suffix for the replica name."
  type = map(object({
    tier                  = string
    disk_type             = optional(string, null)
    disk_autoresize       = optional(bool, null)
    disk_autoresize_limit = optional(number, null)
    enable_public_ip      = optional(bool, null)
    deletion_protection   = optional(bool, null)
  }))
  default = {}
}

# The region where the Cloud SQL instance will be located.
variable "region" {
  description = "The region where the Cloud SQL instance will be created."
  type        = string
}

# The machine type to use for the instance. See https://cloud.google.com/sql/pricing for options.
variable "tier" {
  description = "The machine type for the instance, e.g., 'db-n1-standard-1'."
  type        = string
  default     = "db-n1-standard-1"
}

# A list of users to create on the instance.
variable "users" {
  description = "A list of users to create. Each object has 'name', 'host', and 'type'. For 'BUILT_IN' users, passwords are auto-generated. For 'CLOUD_IAM_USER' or 'CLOUD_IAM_SERVICE_ACCOUNT', the name should be an email address."
  type = list(object({
    name = string
    host = optional(string)
    type = optional(string, "BUILT_IN")
  }))
  default = []
}

# A list of authorized networks that can connect to the public IP. Never use 0.0.0.0/0 for production.
variable "authorized_networks" {
  description = "A list of objects representing authorized networks. Each object has 'name' and 'value' (CIDR notation)."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# A list of database flags to apply to the instance. The module automatically adds 'cloudsql.iam_authentication=On'.
variable "database_flags" {
  description = "A list of database flags to apply to the instance. Each object has 'name' and 'value'."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# A list of databases to create on the instance.
variable "databases" {
  description = "A list of databases to create on the instance. Each object has 'name', and optional 'charset' and 'collation'."
  type = list(object({
    name      = string
    charset   = optional(string)
    collation = optional(string)
  }))
  default = []
}

# The variables.tf file defines the input parameters for the module.
# Each variable includes a description, type, and an optional default value.

variable "project_id" {
  description = "The ID of the project in which to create the Cloud SQL instance."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the Cloud SQL instance. This should be unique within the project."
  type        = string
  default     = "my-cloudsql-instance"
}

variable "database_version" {
  description = "The database version to use. See the official documentation for supported versions. Examples: `POSTGRES_14`, `MYSQL_8_0`, `SQLSERVER_2019_STANDARD`."
  type        = string
  default     = "POSTGRES_14"
}

variable "region" {
  description = "The region where the Cloud SQL instance will be created."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone for the primary instance. Only applicable if availability_type is ZONAL."
  type        = string
  default     = null
}

variable "tier" {
  description = "The machine type for the instance. See the official documentation for available tiers."
  type        = string
  default     = "db-g1-small"
}

variable "availability_type" {
  description = "The availability type of the instance. `ZONAL` for a single-zone instance, `REGIONAL` for a high-availability instance with a failover replica. For production, `REGIONAL` is strongly recommended."
  type        = string
  default     = "REGIONAL"
}

variable "deletion_protection_enabled" {
  description = "If set to true, the instance cannot be accidentally deleted. This is a best practice for production instances."
  type        = bool
  default     = true
}

variable "disk_type" {
  description = "The type of data disk: `PD_SSD` or `PD_HDD`."
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "The size of the data disk in GB."
  type        = number
  default     = 10
}

variable "disk_autoresize" {
  description = "If set to true, the storage will automatically increase when it hits a threshold. This is a best practice to prevent outages."
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "The maximum size to which the disk can be automatically resized. A value of 0 means no limit. It is recommended to set a limit for cost control."
  type        = number
  default     = 0
}

variable "user_labels" {
  description = "A map of key/value labels to apply to the instance."
  type        = map(string)
  default     = {}
}

variable "enable_private_ip" {
  description = "If set to true, the instance will have a private IP address in the specified VPC network. This is a security best practice."
  type        = bool
  default     = false
}

variable "private_network_self_link" {
  description = "The self-link of the VPC network for private IP. Required if `enable_private_ip` is true."
  type        = string
  default     = null
}

variable "allocated_ip_range_name" {
  description = "The name of the allocated IP range for private services access, if required."
  type        = string
  default     = null
}

variable "enable_public_ip" {
  description = "If set to true, the instance will have a public IP address. Access should be restricted via `authorized_networks`."
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "A list of authorized networks for public IP access. Each object can have `value` (CIDR), `name`, and `expiration_time`."
  type = list(object({
    value           = string
    name            = optional(string)
    expiration_time = optional(string)
  }))
  default = []
}

variable "enable_iam_authentication" {
  description = "If set to true, allows IAM users and service accounts to authenticate to the database. This is a security best practice over password-based authentication."
  type        = bool
  default     = true
}

variable "database_flags" {
  description = "A list of database flags to apply to the instance. Each object should have a `name` and `value`."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "enable_backup" {
  description = "If set to true, automated daily backups will be enabled."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "The start time of the daily backup window in HH:MM format (UTC)."
  type        = string
  default     = "02:00"
}

variable "enable_point_in_time_recovery" {
  description = "If set to true, point-in-time recovery will be enabled using write-ahead logs."
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "The maintenance window for the instance. Object with `day` (1-7, Sun-Sat), `hour` (0-23, UTC), and `update_track` ('stable' or 'canary')."
  type = object({
    day          = number
    hour         = number
    update_track = optional(string, "stable")
  })
  default = null
}

variable "root_password" {
  description = "The password for the root user. If not set, a random password will be generated."
  type        = string
  sensitive   = true
  default     = null
}

variable "encryption_key_name" {
  description = "The full resource name of a Cloud KMS key for Customer-Managed Encryption Keys (CMEK)."
  type        = string
  default     = null
}

variable "databases" {
  description = "A list of database objects to create in the instance. Each object can have `name`, `charset`, and `collation`."
  type = list(object({
    name      = string
    charset   = optional(string)
    collation = optional(string)
  }))
  default = []
}

variable "users" {
  description = "A list of user objects to create in the instance. Each object can have `name`, `password`, `host`, and `type`. If `password` is null for a `BUILT_IN` user, a random one will be generated."
  type = list(object({
    name     = string
    password = optional(string)
    host     = optional(string)
    type     = optional(string, "BUILT_IN")
  }))
  default = []
}

variable "read_replicas" {
  description = "A list of read replica configurations to create. Replicas inherit some settings from the primary but can be customized."
  type = list(object({
    name                = string
    tier                = string
    zone                = optional(string)
    disk_type           = optional(string, "PD_SSD")
    disk_size           = optional(number)
    disk_autoresize     = optional(bool, true)
    user_labels         = optional(map(string), {})
    database_flags      = optional(list(object({ name = string, value = string })), [])
    enable_public_ip    = optional(bool, false)
    authorized_networks = optional(list(object({ value = string, name = optional(string) })), [])
  }))
  default = []
}

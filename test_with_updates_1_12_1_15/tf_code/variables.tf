variable "project_id" {
  description = "The ID of the project in which the resource belongs. If it is not provided, the provider project is used."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the Cloud SQL instance. This does not have to be unique, but it's a good practice."
  type        = string
  default     = "default-sql-instance"
}

variable "database_version" {
  description = "The database engine version to use. See https://cloud.google.com/sql/docs/db-versions for supported versions. Examples: `POSTGRES_14`, `MYSQL_8_0`, `SQLSERVER_2019_STANDARD`."
  type        = string
  default     = "MYSQL_8_0"
}

variable "region" {
  description = "The region where the Cloud SQL instance will be created."
  type        = string
  default     = "us-central1"
}

variable "tier" {
  description = "The machine type to use. See https://cloud.google.com/sql/pricing for more details. Example: `db-n1-standard-1`."
  type        = string
  default     = "db-n1-standard-1"
}

variable "availability_type" {
  description = "The availability type of the Cloud SQL instance. A `REGIONAL` instance will have a standby in a different zone. A `ZONAL` instance will be a single-zone instance. `REGIONAL` is the default and recommended for production."
  type        = string
  default     = "REGIONAL"
}

variable "disk_type" {
  description = "The type of disk to use for storage. `PD_SSD` is recommended for most workloads."
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "The initial size of the disk in GB."
  type        = number
  default     = 10
}

variable "disk_autoresize" {
  description = "Whether to allow the instance to automatically increase storage size. Recommended to be `true` to prevent outages due to full disks."
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "The maximum size to which storage can be auto-increased. A value of `0` means no limit. A non-zero value is recommended for cost control."
  type        = number
  default     = 100
}

variable "deletion_protection" {
  description = "Whether or not to allow Terraform to destroy the instance. It is recommended to set this to `true` for production environments."
  type        = bool
  default     = true
}

variable "encryption_key_name" {
  description = "The full resource name of the KMS key to use for encryption. If not provided, a Google-managed key will be used."
  type        = string
  default     = null
}

variable "user_labels" {
  description = "A map of labels to assign to the instance."
  type        = map(string)
  default     = {}
}

variable "ip_configuration" {
  description = "Network configuration for the instance. Best practice is to disable public IP (`ipv4_enabled = false`) and use a `private_network` for internal traffic."
  type = object({
    ipv4_enabled    = optional(bool, false)
    private_network = optional(string)
    authorized_networks = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {}
}

variable "require_ssl" {
  description = "Whether to require SSL/TLS for all client connections."
  type        = bool
  default     = true
}

variable "backup_configuration" {
  description = "Configuration for backups and point-in-time recovery. Set `enabled = true` to activate. `point_in_time_recovery_enabled` requires binary logging to be enabled for MySQL."
  type = object({
    enabled                        = optional(bool, true)
    start_time                     = optional(string, "03:00")
    point_in_time_recovery_enabled = optional(bool, true)
    retained_backups               = optional(number)
    transaction_log_retention_days = optional(number)
  })
  default = {}
}

variable "maintenance_window" {
  description = "The maintenance window for the instance. If not provided, a default window will be assigned."
  type = object({
    day  = number
    hour = number
  })
  default = null
}

variable "cloudsql_iam_authentication" {
  description = "Enables IAM database authentication for the instance. This is a best practice, eliminating the need for static passwords."
  type        = bool
  default     = true
}

variable "database_flags" {
  description = "A list of key-value pairs to set as database flags."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "databases" {
  description = "A list of database objects to create in the Cloud SQL instance."
  type = list(object({
    name      = string
    charset   = optional(string)
    collation = optional(string)
  }))
  default = []
}

variable "users" {
  description = "A list of database users to create. The `password` field is sensitive and will not be displayed in logs."
  type = list(object({
    name     = string
    password = string
    host     = optional(string)
    type     = optional(string)
  }))
  default   = []
  sensitive = true
}

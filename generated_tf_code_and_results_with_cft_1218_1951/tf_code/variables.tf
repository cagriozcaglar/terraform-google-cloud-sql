variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "name" {
  description = "The name of the Cloud SQL instance. This does not include the project ID."
  type        = string
}

variable "database_version" {
  description = "The database engine version to use. See https://cloud.google.com/sql/docs/db-versions for supported versions. E.g., `MYSQL_8_0`, `POSTGRES_14`."
  type        = string
}

variable "region" {
  description = "The region where the instance will be located."
  type        = string
}

variable "tier" {
  description = "The machine type to use. See https://cloud.google.com/sql/docs/instance-settings for details."
  type        = string
}

variable "deletion_protection" {
  description = "Used to block Terraform from deleting a SQL Instance. Recommended to be `true` for production instances."
  type        = bool
  default     = true
}

variable "availability_type" {
  description = "The availability type of the Cloud SQL instance. Can be `ZONAL` or `REGIONAL`. `REGIONAL` instances provide high availability and are recommended for production."
  type        = string
  default     = "REGIONAL"
}

variable "disk_autoresize" {
  description = "This setting enables the automatic increase of storage size when the instance is running out of disk space. Recommended to be `true`."
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "The maximum size in GB to which storage can be auto-increased. A value of 0 means no limit. It is recommended to set a limit for cost control."
  type        = number
  default     = 0
}

variable "disk_size" {
  description = "The size of the storage in gigabytes."
  type        = number
  default     = 10
}

variable "disk_type" {
  description = "The type of storage to use. Can be `PD_SSD` or `PD_HDD`."
  type        = string
  default     = "PD_SSD"
}

variable "edition" {
  description = "The edition of the instance, can be `ENTERPRISE` or `ENTERPRISE_PLUS`. `ENTERPRISE_PLUS` provides the highest availability."
  type        = string
  default     = "ENTERPRISE"
}

variable "root_password" {
  description = "The password for the root user. If not set, a random one will be generated. Required for SQL Server instances. It is recommended to use Secret Manager to manage this value."
  type        = string
  default     = null
  sensitive   = true
}

variable "encryption_key_name" {
  description = "The full name of the Cloud KMS key to be used for encrypting the disk. The key must be in the same region as the instance."
  type        = string
  default     = null
}

variable "require_ssl" {
  description = "Whether SSL connections are required for this instance. This is a security best practice."
  type        = bool
  default     = true
}

variable "ip_configuration" {
  description = "The IP configuration for the instance. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#ip_configuration."
  type = object({
    ipv4_enabled    = optional(bool, false)
    private_network = optional(string)
    authorized_networks = optional(list(object({
      name            = string
      value           = string
      expiration_time = optional(string)
    })), [])
  })
  default = {
    ipv4_enabled = false
  }
}

variable "backup_configuration" {
  description = "The backup configuration for the instance. Backups are enabled by default."
  type = object({
    enabled                        = optional(bool, true)
    start_time                     = optional(string)
    location                       = optional(string)
    point_in_time_recovery_enabled = optional(bool, true)
    backup_retention_settings = optional(object({
      retained_backups = number
      retention_unit   = optional(string, "COUNT")
      }), {
      retained_backups = 7,
      retention_unit   = "COUNT"
    })
  })
  default = {}
}

variable "maintenance_window" {
  description = "The maintenance window for the instance. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#maintenance_window."
  type = object({
    day          = number
    hour         = number
    update_track = optional(string)
  })
  default = null
}

variable "database_flags" {
  description = "List of database flags to apply to the instance. IAM database authentication is enabled by default."
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "cloudsql.iam_authentication"
      value = "On"
    }
  ]
}

variable "databases" {
  description = "A list of databases to be created in the instance."
  type = list(object({
    name      = string
    charset   = optional(string)
    collation = optional(string)
  }))
  default = []
}

variable "users" {
  description = "A list of users to be created in the instance. It is recommended to use Secret Manager to manage passwords."
  type = list(object({
    name     = string
    password = string
    host     = optional(string)
    type     = optional(string)
  }))
  default   = []
  sensitive = true
}

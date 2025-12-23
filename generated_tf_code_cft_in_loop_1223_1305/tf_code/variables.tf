variable "project_id" {
  description = "The ID of the project in which the resource belongs. If not provided, the provider project is used."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the Cloud SQL instance. This does not include the project ID."
  type        = string
  default     = "gcp-sql-instance"
}

variable "database_version" {
  description = "The database version to use, e.g., `MYSQL_8_0`, `POSTGRES_14`, `SQLSERVER_2019_STANDARD`."
  type        = string
  default     = "MYSQL_8_0"
}

variable "region" {
  description = "The region where the Cloud SQL instance will be created."
  type        = string
  default     = "us-central1"
}

variable "tier" {
  description = "The machine type to use for the instance, e.g., `db-n1-standard-1`."
  type        = string
  default     = "db-n1-standard-1"
}

variable "availability_type" {
  description = "The availability type of the SQL instance, `ZONAL` or `REGIONAL`. `REGIONAL` provides high availability by failing over to a standby instance in another zone."
  type        = string
  default     = "ZONAL"
}

variable "disk_type" {
  description = "The type of storage disk. Can be `PD_SSD` or `PD_HDD`."
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "The size of the storage disk in GB."
  type        = number
  default     = 20
}

variable "disk_autoresize" {
  description = "If set to true, the storage disk will be automatically increased if it runs out of space. This is a best practice to prevent outages."
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "The maximum size to which the storage disk can be automatically increased. A value of 0 means no limit. Setting a limit is recommended for cost control."
  type        = number
  default     = 0
}

variable "deletion_protection" {
  description = "Used to block accidental deletion of the instance. This is a best practice for production instances."
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Set to true to enable automated daily backups."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "The start time of the daily backup window in HH:MM format from the instance's timezone. It is recommended to supplement backups with database exports for disaster recovery."
  type        = string
  default     = "03:00"
}

variable "backup_location" {
  description = "The location to store automated backups. If not set, they are stored in the closest multi-region."
  type        = string
  default     = null
}

variable "point_in_time_recovery_enabled" {
  description = "Set to true to enable point-in-time recovery. For MySQL, this enables the `binary_log_enabled` option. For PostgreSQL and SQL Server, this enables the `point_in_time_recovery_enabled` option. Note that for some database versions, this may require other flags to be set."
  type        = bool
  default     = true
}

variable "ip_configuration_ipv4_enabled" {
  description = "If true, the instance will be assigned a public IPv4 address. For security, it is best practice to use a private IP instead."
  type        = bool
  default     = false
}

variable "private_network" {
  description = "The self-link of the VPC network to which the instance is connected for private IP. E.g., `projects/my-project/global/networks/my-vpc`."
  type        = string
  default     = null
}

variable "authorized_networks" {
  description = "A list of authorized networks that can connect to the public IP. Never use `0.0.0.0/0` in production."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "iam_authentication_enabled" {
  description = "If true, enables IAM database authentication, allowing IAM users and service accounts to log in to the database without a password. This is a security best practice."
  type        = bool
  default     = true
}

variable "database_flags" {
  description = "A list of database flags to apply to the instance."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "maintenance_window" {
  description = "Defines the maintenance window for the instance. If not set, maintenance can occur at any time."
  type = object({
    day  = number # 1-7 (Monday-Sunday)
    hour = number # 0-23 in UTC
  })
  default = null
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
  description = "A list of users to be created in the instance. For BUILT_IN users, if password is not set, a random one will be generated and the host defaults to '%' if not provided. For IAM users (CLOUD_IAM_USER or CLOUD_IAM_SERVICE_ACCOUNT), the name must be an email address and password/host are not applicable."
  type = list(object({
    name     = string
    type     = optional(string, "BUILT_IN")
    password = optional(string)
    host     = optional(string)
  }))
  default = []
}

variable "read_replicas" {
  description = "A map of read replica configurations. The key is the replica name suffix. Replicas inherit tier, disk size, and availability type from the primary instance and are used to offload read traffic."
  type = map(object({
    region                        = optional(string)
    zone                          = optional(string)
    database_flags                = optional(list(object({ name = string, value = string })))
    user_labels                   = optional(map(string))
    ip_configuration_ipv4_enabled = optional(bool)
    private_network               = optional(string)
  }))
  default = {}
}

variable "root_password" {
  description = "The initial password for the root user. If not set, a random password will be generated. Note: This is only set on creation."
  type        = string
  sensitive   = true
  default     = null
}

variable "encryption_key_name" {
  description = "The self-link of the Cloud KMS key to be used for disk encryption. If not set, a Google-managed key will be used."
  type        = string
  default     = null
}

variable "user_labels" {
  description = "A map of key/value user labels to assign to the instance."
  type        = map(string)
  default     = {}
}

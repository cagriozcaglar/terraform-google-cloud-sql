# This file contains the core logic for creating the Cloud SQL resources.

# Fetches the provider-configured project ID, to be used as a default.
data "google_client_config" "default" {}

locals {
  # Determines the project ID to use. Falls back to the provider's default project if not specified.
  project_id = coalesce(var.project_id, data.google_client_config.default.project)

  # Generates a random suffix for the instance name to ensure global uniqueness.
  instance_name_suffix = random_id.suffix.hex

  # Constructs the full name for the primary Cloud SQL instance.
  instance_name = "${var.name}-${local.instance_name_suffix}"

  # Determines the user password, generating a random one if not explicitly provided.
  user_password = coalesce(var.user_password, try(random_password.default["user"].result, null))

  # Combines user-provided flags with the conditionally added IAM authentication flag.
  # IAM database authentication is supported for PostgreSQL and MySQL and is configured via the `cloudsql.iam_authentication` flag.
  all_database_flags = concat(
    var.database_flags,
    (
      var.iam_database_authentication_enabled && can(regex("^(POSTGRES|MYSQL)", var.database_version))
      ? [{ name = "cloudsql.iam_authentication", value = "On" }]
      : []
    )
  )

  # Determines if a public IP should be enabled. If the variable is not explicitly set,
  # a public IP is enabled only if a private network is not specified.
  # This ensures the instance is accessible by default.
  effective_enable_public_ip = var.enable_public_ip == null ? (var.vpc_network == null ? true : false) : var.enable_public_ip
}

# A random hexadecimal suffix to ensure the Cloud SQL instance name is unique.
resource "random_id" "suffix" {
  # The length of the random suffix in bytes.
  byte_length = 4
}

# Generates a random password for the database user if one is not provided.
# This resource is only created if a user is being created and no password is specified.
resource "random_password" "default" {
  # Creates this resource only if a user is being created and no password is specified.
  for_each = var.create_user && var.user_name != null && var.user_password == null ? { "user" = true } : {}

  # The length of the generated password.
  length = 16

  # Indicates that the password must include special characters.
  special = true
}

# Enables the Cloud SQL Admin API.
resource "google_project_service" "sqladmin" {
  # The project ID to enable the API on.
  project = local.project_id
  # The name of the API to enable.
  service = "sqladmin.googleapis.com"
  # Do not disable the API on destroy, as other resources may depend on it.
  disable_on_destroy = false
}

# Enables the Service Networking API, required for private IP connections.
resource "google_project_service" "servicenetworking" {
  # The project ID to enable the API on.
  project = local.project_id
  # The name of the API to enable.
  service = "servicenetworking.googleapis.com"
  # Do not disable the API on destroy, as other resources may depend on it.
  disable_on_destroy = false
}

#
# The primary Cloud SQL database instance.
#
resource "google_sql_database_instance" "default" {
  # The project ID where the instance will be created.
  project = local.project_id
  # The globally unique name of the instance.
  name = local.instance_name
  # The region for the instance.
  region = var.region
  # The version of the database engine to use (e.g., POSTGRES_14, MYSQL_8_0).
  database_version = var.database_version
  # If enabled, prevents the instance from being accidentally deleted.
  deletion_protection = var.deletion_protection

  # An explicit dependency on the Service Networking API is needed for private IP.
  depends_on = [
    google_project_service.servicenetworking,
    google_project_service.sqladmin
  ]

  # The main settings block for the instance.
  settings {
    # The machine type for the instance.
    tier = var.tier
    # The availability type (REGIONAL for HA, ZONAL for single-zone).
    availability_type = var.availability_type
    # Configuration for the instance's disk.
    disk_autoresize       = var.disk_autoresize
    disk_autoresize_limit = var.disk_autoresize_limit
    disk_size             = var.disk_size
    disk_type             = var.disk_type

    # Configuration for the instance's IP addressing.
    ip_configuration {
      # Enables or disables the public IP address.
      ipv4_enabled = local.effective_enable_public_ip
      # The VPC network for the private IP address.
      private_network = var.vpc_network

      # A list of authorized networks that can connect to the public IP.
      dynamic "authorized_networks" {
        for_each = local.effective_enable_public_ip ? var.authorized_networks : []
        iterator = network
        content {
          name  = network.value.name
          value = network.value.value
        }
      }
    }

    # Configuration for automated backups and point-in-time recovery.
    backup_configuration {
      # Enables automated backups.
      enabled = var.backup_configuration.enabled
      # The start time for the daily backup window, in "HH:MM" format.
      start_time = var.backup_configuration.start_time
      # The location to store the backups.
      location = var.backup_configuration.location
      # Enables point-in-time recovery, which is required for creating read replicas.
      point_in_time_recovery_enabled = var.backup_configuration.point_in_time_recovery_enabled
    }

    # A list of database flags to apply to the instance.
    dynamic "database_flags" {
      for_each = toset(local.all_database_flags)
      iterator = flag
      content {
        name  = flag.value.name
        value = flag.value.value
      }
    }

    # Defines the maintenance window for the instance.
    dynamic "maintenance_window" {
      for_each = var.maintenance_window != null ? [var.maintenance_window] : []
      iterator = window
      content {
        day  = window.value.day
        hour = window.value.hour
      }
    }
  }

  # Lifecycle rules for the resource.
  lifecycle {
    # A precondition to ensure that at least one IP type (public or private) is configured.
    precondition {
      condition     = var.vpc_network != null || local.effective_enable_public_ip
      error_message = "At least one of `vpc_network` (for private IP) or `enable_public_ip` must be set to true."
    }
    # A precondition to ensure IAM database authentication is only enabled for supported database engines.
    precondition {
      condition     = var.iam_database_authentication_enabled == false || can(regex("^(POSTGRES|MYSQL)", var.database_version))
      error_message = "IAM database authentication is only supported for PostgreSQL and MySQL instances."
    }
    # A precondition to ensure that backups and point-in-time recovery are enabled if read replicas are configured.
    precondition {
      condition     = length(var.read_replicas) == 0 || (var.backup_configuration.enabled == true && var.backup_configuration.point_in_time_recovery_enabled == true)
      error_message = "To create read replicas, `backup_configuration.enabled` and `backup_configuration.point_in_time_recovery_enabled` must both be true."
    }
  }
}

#
# Read Replica Instances.
#
resource "google_sql_database_instance" "replicas" {
  # Creates one replica for each entry in the var.read_replicas map.
  for_each = var.read_replicas

  # The project ID for the replica.
  project = local.project_id
  # The name of the read replica.
  name = "${local.instance_name}-replica-${each.key}"
  # The database version for the replica. Must match the primary instance.
  database_version = var.database_version
  # The primary instance to which this replica is attached.
  master_instance_name = google_sql_database_instance.default.name
  # The region of the replica, which must be the same as the primary.
  region = var.region

  # Settings for the replica instance.
  settings {
    # The machine type for the replica.
    tier = each.value.tier
    # A replica's availability type must match its primary.
    availability_type = var.availability_type
    # Disk configuration for the replica.
    disk_type             = each.value.disk_type
    disk_autoresize       = each.value.disk_autoresize
    disk_autoresize_limit = each.value.disk_autoresize_limit
    disk_size             = each.value.disk_size
  }

  # Lifecycle rules for the resource.
  lifecycle {
    # A precondition to ensure that a replica's disk is not smaller than the primary's.
    precondition {
      condition     = each.value.disk_size == null || each.value.disk_size >= var.disk_size
      error_message = "The disk size for replica \"${each.key}\" (${each.value.disk_size}GB) must be greater than or equal to the primary instance's disk size (${var.disk_size}GB)."
    }
  }
}

# An initial database created within the primary instance.
resource "google_sql_database" "default" {
  # Creates this resource only if database creation is enabled and a name is provided.
  for_each = var.create_database && var.database_name != null ? { "db" = var.database_name } : {}

  # The project ID.
  project = local.project_id
  # The name of the primary instance where the database will be created.
  instance = google_sql_database_instance.default.name
  # The name of the database.
  name = each.value
}

# An initial user for the database.
resource "google_sql_user" "default" {
  # Creates this resource only if user creation is enabled and a name is provided.
  for_each = var.create_user && var.user_name != null ? { "user" = var.user_name } : {}

  # The project ID.
  project = local.project_id
  # The name of the primary instance where the user will be created.
  instance = google_sql_database_instance.default.name
  # The username.
  name = each.value
  # The password for the user.
  password = local.user_password
  # The type of the user, for SQL Server.
  type = var.user_type

  # Lifecycle rules for the resource.
  lifecycle {
    # A precondition to ensure that user_type is only used for SQL Server instances.
    precondition {
      condition     = var.user_type == null || can(regex("SQLSERVER", var.database_version))
      error_message = "The `user_type` variable is only applicable for SQL Server instances."
    }
  }
}
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

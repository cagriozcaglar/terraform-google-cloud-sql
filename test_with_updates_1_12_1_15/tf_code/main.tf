# The main.tf file is the entry point for the Terraform module. It contains the resource definitions that create and manage the infrastructure.
# This file defines the Cloud SQL instance, databases, and users based on the input variables.

# Fetches the project information from the provider configuration. This is used to default the project ID if the `project_id` variable is not set.
data "google_project" "project" {}

locals {
  # Determine the project ID, using the variable if provided, otherwise falling back to the provider's project.
  project_id = var.project_id == null ? data.google_project.project.project_id : var.project_id

  # Determine the database engine type for conditional logic.
  is_postgres = substr(var.database_version, 0, 8) == "POSTGRES"
  is_mysql    = substr(var.database_version, 0, 5) == "MYSQL"

  # Filter out any user-provided iam_authentication flag to prevent conflicts with the dedicated boolean variable.
  filtered_database_flags = [
    for flag in var.database_flags : flag if flag.name != "cloudsql.iam_authentication"
  ]

  # Conditionally add the iam_authentication flag based on the 'cloudsql_iam_authentication' variable.
  # This enforces the best practice of using IAM authentication by default.
  final_database_flags = var.cloudsql_iam_authentication ? concat(
    local.filtered_database_flags,
    [{
      name  = "cloudsql.iam_authentication"
      value = "on"
    }]
  ) : local.filtered_database_flags

  # Translate the require_ssl boolean to the appropriate ssl_mode string for the instance settings.
  ssl_mode = var.require_ssl ? "ENCRYPTED_ONLY" : "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
}

# Resource definition for the primary Cloud SQL instance.
# This resource manages the lifecycle of a single Cloud SQL instance.
resource "google_sql_database_instance" "main" {
  # The GCP project ID where the instance will be created.
  project = local.project_id
  # The name of the Cloud SQL instance.
  name = var.name
  # The database engine and version.
  database_version = var.database_version
  # The region where the instance will reside.
  region = var.region
  # The CMEK key to use for encryption.
  encryption_key_name = var.encryption_key_name
  # Protection against accidental deletion, strongly recommended for production.
  deletion_protection = var.deletion_protection

  # The settings block contains the main configuration for the instance.
  settings {
    # The machine type for the instance.
    tier = var.tier
    # The availability type (e.g., REGIONAL for High Availability).
    availability_type = var.availability_type
    # The type of storage disk.
    disk_type = var.disk_type
    # The initial size of the disk.
    disk_size = var.disk_size
    # Enables automatic storage increases.
    disk_autoresize = var.disk_autoresize
    # Sets a limit for automatic storage increases to control costs.
    disk_autoresize_limit = var.disk_autoresize_limit
    # User-defined labels for resource organization and billing.
    user_labels = var.user_labels

    # Network configuration for the instance.
    ip_configuration {
      # Determines if a public IP address is assigned. Best practice is 'false'.
      ipv4_enabled = var.ip_configuration.ipv4_enabled
      # The VPC network for private IP connectivity.
      private_network = var.ip_configuration.private_network
      # SSL mode for connections. `ENCRYPTED_ONLY` is the default best practice.
      ssl_mode = local.ssl_mode

      # A list of CIDR blocks authorized to connect if public IP is enabled.
      # It is a security anti-pattern to use '0.0.0.0/0'.
      dynamic "authorized_networks" {
        for_each = var.ip_configuration.authorized_networks
        content {
          # A name for the authorized network.
          name = authorized_networks.value.name
          # The CIDR block.
          value = authorized_networks.value.value
        }
      }
    }

    # Backup configuration for the instance.
    backup_configuration {
      # Enables automated daily backups.
      enabled = var.backup_configuration.enabled
      # The start time of the daily backup window in HH:MM format (UTC).
      start_time = var.backup_configuration.start_time
      # Enables point-in-time recovery using write-ahead logs.
      point_in_time_recovery_enabled = var.backup_configuration.point_in_time_recovery_enabled
      # For MySQL, point-in-time recovery requires binary logging.
      binary_log_enabled = local.is_mysql && var.backup_configuration.point_in_time_recovery_enabled ? true : null
      # For PostgreSQL, this sets the number of days of transaction logs to retain.
      transaction_log_retention_days = local.is_postgres ? var.backup_configuration.transaction_log_retention_days : null

      # Settings for backup retention.
      dynamic "backup_retention_settings" {
        for_each = var.backup_configuration.retained_backups != null ? [1] : []
        content {
          # The number of backups to retain.
          retained_backups = var.backup_configuration.retained_backups
          # The unit of retention.
          retention_unit = "COUNT"
        }
      }
    }

    # Maintenance window configuration.
    dynamic "maintenance_window" {
      for_each = var.maintenance_window != null ? [var.maintenance_window] : []
      content {
        # The day of the week (1-7), starting with Monday.
        day = maintenance_window.value.day
        # The hour of the day in UTC (0-23).
        hour = maintenance_window.value.hour
      }
    }

    # A list of database flags to apply to the instance.
    # The final list is constructed in the 'locals' block to handle IAM authentication.
    dynamic "database_flags" {
      for_each = local.final_database_flags
      content {
        # The name of the database flag.
        name = database_flags.value.name
        # The value of the database flag.
        value = database_flags.value.value
      }
    }
  }
}

# Resource definition for creating databases within the Cloud SQL instance.
# This resource uses a for_each loop to create multiple databases as defined in the 'databases' variable.
resource "google_sql_database" "main" {
  # Creates one database resource for each item in the var.databases list.
  for_each = { for db in var.databases : db.name => db }
  # The GCP project ID.
  project = local.project_id
  # The name of the database.
  name = each.value.name
  # The Cloud SQL instance in which to create the database.
  instance = google_sql_database_instance.main.name
  # The character set for the database.
  charset = each.value.charset
  # The collation for the database.
  collation = each.value.collation
}

# Resource definition for creating users for the Cloud SQL instance.
# This resource uses a for_each loop to create multiple users as defined in the 'users' variable.
resource "google_sql_user" "main" {
  # Creates one user resource for each item in the var.users list.
  for_each = { for user in var.users : user.name => user }
  # The GCP project ID.
  project = local.project_id
  # The name of the user.
  name = each.value.name
  # The Cloud SQL instance in which to create the user.
  instance = google_sql_database_instance.main.name
  # The password for the user. This is a sensitive value.
  password = each.value.password
  # The host from which the user can connect.
  host = each.value.host
  # The type of the user, e.g., BUILT_IN, CLOUD_IAM_USER.
  type = each.value.type
}

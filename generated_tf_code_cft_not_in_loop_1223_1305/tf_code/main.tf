# This file contains the main logic for creating the Cloud SQL instance and related resources.
# It defines the primary Cloud SQL instance, read replicas, databases, and users based on the input variables.
# Following enterprise best practices, this module configures instances with private networking,
# IAM database authentication, deletion protection, and automatic storage resizing by default.

# This data source retrieves the provider's configured project details.
# It's used to default the project_id if the user doesn't provide it explicitly.
# Using google_client_config is more reliable than google_project for this purpose.
data "google_client_config" "current" {}

locals {
  # Determine the project ID to use. Prioritize the user-provided variable,
  # otherwise fall back to the project configured in the provider.
  project_id = var.project_id == null ? data.google_client_config.current.project : var.project_id

  # Create maps from the input lists for use with for_each, which provides more stable resource management than count.
  databases_map = { for db in var.databases : db.name => db }
  users_map     = { for user in var.users : user.name => user }
  replicas_map  = { for replica in var.read_replicas : replica.name => replica }

  # Identify built-in users who need a password to be generated automatically.
  users_needing_password = { for k, v in local.users_map : k => v if v.type == "BUILT_IN" && v.password == null }

  # Determine the database family (e.g., MYSQL, POSTGRES, SQLSERVER) from the version string.
  db_family = (
    substr(var.database_version, 0, 8) == "SQLSERVER" ? "SQLSERVER" : (
      substr(var.database_version, 0, 5) == "MYSQL" ? "MYSQL" : (
        substr(var.database_version, 0, 8) == "POSTGRES" ? "POSTGRES" : "UNKNOWN"
      )
    )
  )

  # Determine the correct flag for enabling IAM authentication based on the database family.
  # For MySQL the flag name uses an underscore, for PostgreSQL and SQL Server it uses a period.
  iam_auth_flag = {
    name  = local.db_family == "MYSQL" ? "cloudsql_iam_authentication" : "cloudsql.iam_authentication"
    value = "On"
  }

  # Create the final list of database flags, adding the IAM authentication flag if enabled.
  final_database_flags = (
    var.iam_database_authentication_enabled && contains(["MYSQL", "POSTGRES", "SQLSERVER"], local.db_family) ?
    concat(var.database_flags, [local.iam_auth_flag]) :
    var.database_flags
  )
}

# This resource defines the primary Cloud SQL instance.
# All core settings, including high availability, networking, backups, and flags, are configured here.
resource "google_sql_database_instance" "primary" {
  # The project ID where the Cloud SQL instance will be created.
  project = local.project_id
  # The name of the Cloud SQL instance.
  name = var.name
  # The database engine and version for the instance (e.g., POSTGRES_15, MYSQL_8_0).
  database_version = var.database_version
  # The region where the instance will be located.
  region = var.region
  # The encryption key to use for encrypting the data. If null, Google-managed encryption is used.
  encryption_key_name = var.encryption_key_name
  # Protects the instance from accidental deletion. This is a critical best practice for production environments.
  deletion_protection = var.deletion_protection_enabled

  # Settings block contains the main configuration for the instance's behavior and resources.
  settings {
    # The machine type for the instance.
    tier = var.tier
    # The availability type (ZONAL or REGIONAL). REGIONAL is recommended for production for high availability.
    availability_type = var.availability_type
    # The initial size of the disk in GB.
    disk_size = var.disk_size
    # The type of storage disk (PD_SSD or PD_HDD).
    disk_type = var.disk_type
    # Enables automatic disk resizing to prevent outages due to full disks.
    disk_autoresize = var.disk_autoresize
    # Sets a limit in GB for disk auto-resizing to control costs. 0 means no limit.
    disk_autoresize_limit = var.disk_autoresize_limit
    # Custom labels to apply to the instance for organization and filtering.
    user_labels = var.user_labels

    # Configures the network settings for the instance.
    ip_configuration {
      # When true, assigns a public IPv4 address. Best practice is to keep this false and use private networking.
      ipv4_enabled = var.enable_public_ip
      # The self-link of the VPC network to associate with the instance for private IP access.
      private_network = var.private_network_self_link
      # A list of authorized networks that can connect to the public IP.
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          # An optional name for the authorized network entry.
          name = authorized_networks.value.name
          # The CIDR range of the authorized network.
          value = authorized_networks.value.value
        }
      }
    }

    # Configures the backup and recovery settings.
    backup_configuration {
      # Enables or disables automated daily backups.
      enabled = var.backups_enabled
      # The start time of the daily backup window in UTC (HH:MM format).
      start_time = var.backups_enabled ? var.backup_start_time : null
      # The location to store backups. If null, the instance's region is used.
      location = var.backups_enabled ? var.backup_location : null
      # Enables point-in-time recovery using write-ahead logs. Requires backups to be enabled.
      point_in_time_recovery_enabled = var.backups_enabled && var.pitr_enabled
      # The number of days of transaction logs to retain for PITR.
      transaction_log_retention_days = var.backups_enabled && var.pitr_enabled ? var.transaction_log_retention_days : null
    }

    # Sets custom database flags to tune the database engine's behavior.
    dynamic "database_flags" {
      for_each = local.final_database_flags
      content {
        # The name of the database flag.
        name = database_flags.value.name
        # The value to set for the database flag.
        value = database_flags.value.value
      }
    }
  }

  # Lifecycle block with a precondition to ensure network connectivity is properly configured.
  lifecycle {
    precondition {
      condition     = var.enable_public_ip || var.private_network_self_link != null
      error_message = "The 'private_network_self_link' variable must be set when 'enable_public_ip' is false."
    }
  }
}

# This resource creates one or more databases within the primary Cloud SQL instance.
resource "google_sql_database" "dbs" {
  # Creates a database for each item in the databases_map local variable.
  for_each = local.databases_map
  # The project ID of the instance.
  project = google_sql_database_instance.primary.project
  # The name of the instance where the database will be created.
  instance = google_sql_database_instance.primary.name
  # The name of the database.
  name = each.value.name
  # The character set for the database (e.g., 'UTF8' for PostgreSQL). Not supported for SQL Server.
  charset = local.db_family != "SQLSERVER" ? each.value.charset : null
  # The collation for the database (e.g., 'en_US.UTF8' for PostgreSQL). Not supported for SQL Server.
  collation = local.db_family != "SQLSERVER" ? each.value.collation : null
}

# This resource generates a secure, random password for database users that do not have a password specified.
resource "random_password" "user_passwords" {
  # Creates a password for each user identified in the users_needing_password local variable.
  for_each = local.users_needing_password
  # The length of the generated password.
  length = 16
  # Allows the use of special characters in the password.
  special = true
}

# This resource creates one or more users for the primary Cloud SQL instance.
resource "google_sql_user" "db_users" {
  # Creates a user for each item in the users_map local variable.
  for_each = local.users_map
  # The project ID of the instance.
  project = google_sql_database_instance.primary.project
  # The name of the instance for this user.
  instance = google_sql_database_instance.primary.name
  # The name of the user. For IAM users, this is the email address.
  name = each.value.name
  # The host from which the user can connect. Defaults to all hosts ('%'). Not applicable for IAM users.
  host = each.value.host
  # The type of the user. Can be BUILT_IN, CLOUD_IAM_USER, or CLOUD_IAM_SERVICE_ACCOUNT.
  type = each.value.type
  # The password for the user. It uses the provided password or the one generated by the random_password resource. Only applicable for BUILT_IN users.
  password = each.value.type != "BUILT_IN" ? null : (each.value.password != null ? each.value.password : random_password.user_passwords[each.key].result)
}

# This resource creates one or more read replicas for the primary Cloud SQL instance.
# Read replicas are used to offload read-heavy workloads and improve availability.
resource "google_sql_database_instance" "replicas" {
  # Creates a read replica for each item in the replicas_map local variable.
  for_each = local.replicas_map
  # The project ID for the replica.
  project = google_sql_database_instance.primary.project
  # The name of the read replica instance. Must be unique.
  name = each.value.name
  # The name of the primary instance that this replica follows.
  master_instance_name = google_sql_database_instance.primary.name
  # The region of the replica. Must be the same as the primary.
  region = google_sql_database_instance.primary.region
  # The database version. Inherited from the primary and must match.
  database_version = google_sql_database_instance.primary.database_version
  # Replica instances should also be protected from accidental deletion in production.
  deletion_protection = var.deletion_protection_enabled

  # Settings for the read replica, which can differ from the primary in some aspects (e.g., tier, disk size).
  settings {
    # The machine type for the replica. Can be different from the primary.
    tier = each.value.tier
    # The initial size of the disk for the replica.
    disk_size = each.value.disk_size
    # The type of storage disk for the replica.
    disk_type = each.value.disk_type
    # Enables automatic disk resizing for the replica.
    disk_autoresize = each.value.disk_autoresize
    # Sets a limit for disk auto-resizing on the replica.
    disk_autoresize_limit = each.value.disk_autoresize_limit
    # Custom labels for the replica.
    user_labels = each.value.user_labels

    # IP configuration for the replica.
    ip_configuration {
      # Enables a public IP for the replica if specified.
      ipv4_enabled = try(each.value.ip_configuration.enable_public_ip, false)
      # The private network for the replica.
      private_network = try(each.value.ip_configuration.private_network_self_link, null)
      # A list of authorized networks for the replica's public IP.
      dynamic "authorized_networks" {
        for_each = try(each.value.ip_configuration.authorized_networks, [])
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # Conditionally sets the zone for the replica. The zone is specified in location_preference.
    dynamic "location_preference" {
      for_each = each.value.zone != null ? [each.value.zone] : []
      content {
        # The preferred zone for the instance.
        zone = location_preference.value
      }
    }
  }

  # Lifecycle block with a precondition to ensure replica network connectivity is properly configured.
  lifecycle {
    precondition {
      condition     = try(each.value.ip_configuration.enable_public_ip, false) || try(each.value.ip_configuration.private_network_self_link, null) != null
      error_message = "For replica '${each.key}', the 'private_network_self_link' must be provided in 'ip_configuration' when 'enable_public_ip' is false."
    }
  }
}

# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

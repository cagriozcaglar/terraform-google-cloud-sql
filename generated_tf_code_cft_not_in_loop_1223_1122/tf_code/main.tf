# This file contains the main resources for the Cloud SQL module.
locals {
  # This boolean flag checks if the user has already provided a value for the 'cloudsql.iam_authentication' flag.
  iam_auth_flag_is_set = length([
    for flag in var.database_flags : 1 if flag.name == "cloudsql.iam_authentication"
  ]) > 0

  # Merges user-provided database flags with the default best practice of enabling IAM database authentication.
  # This ensures IAM authentication is enabled unless explicitly disabled by the user (by setting the flag to "Off").
  # If the user hasn't set the flag at all, it will be added with the value "On".
  database_flags = concat(
    var.database_flags,
    local.iam_auth_flag_is_set ? [] : [{ name = "cloudsql.iam_authentication", value = "On" }]
  )

  # Filters the user list to only include users of type 'BUILT_IN' who require a password.
  sql_users = { for user in var.users : user.name => user if user.type == "BUILT_IN" }
}

# This resource defines the primary Cloud SQL instance.
# It is configured based on the provided variables, with defaults aligned to enterprise best practices
# such as high availability, private networking, and deletion protection.
resource "google_sql_database_instance" "main" {
  # The project ID to deploy the Cloud SQL instance into.
  project = var.project_id
  # The user-defined name for the Cloud SQL instance.
  name = var.name
  # The region where the Cloud SQL instance will be created.
  region = var.region
  # The database engine type and version.
  database_version = var.database_version
  # The encryption key used to encrypt the database. If null, a Google-managed key is used.
  encryption_key_name = var.encryption_key_name
  # This setting protects the instance from accidental deletion. It is strongly recommended to keep this enabled for production instances.
  deletion_protection = var.deletion_protection

  # The settings block contains the main configuration for the instance,
  # including machine type, storage, networking, and backup policies.
  settings {
    # The machine type for the instance. Tiers are chosen based on CPU and memory requirements.
    tier = var.tier
    # The availability type of the instance. 'REGIONAL' provides high availability by failing over to a standby in another zone.
    # 'ZONAL' is a single-zone instance.
    availability_type = var.availability_type
    # The edition of the instance, which determines features and pricing.
    edition = var.edition
    # The type of storage. 'PD_SSD' is recommended for most workloads due to its performance.
    disk_type = var.disk_type
    # The initial size of the disk in GB.
    disk_size = var.disk_size
    # Enables automatic storage increases when the disk is nearly full. This is critical to prevent outages due to lack of space.
    disk_autoresize = var.disk_autoresize
    # The maximum size in GB that the disk can automatically grow to. A non-zero value is recommended for cost control.
    disk_autoresize_limit = var.disk_autoresize_limit

    # IP configuration determines how the instance is accessed. Best practice is to use private IP for internal traffic.
    ip_configuration {
      # When true, a public IPv4 address is assigned to the instance. Disabled by default.
      ipv4_enabled = var.enable_public_ip
      # The self-link of the VPC network to connect the instance to for private IP access.
      private_network = var.private_network
      # A list of CIDR blocks that are allowed to connect to the public IP address.
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          # A user-defined name for the authorized network.
          name = authorized_networks.value.name
          # The CIDR value of the allowed network.
          value = authorized_networks.value.value
        }
      }
    }

    # Backup configuration for the instance. Automated backups are a critical component of data protection.
    backup_configuration {
      # If set to true, automated backups are enabled.
      enabled = var.backup_configuration.enabled
      # The start time of the daily backup window in HH:MM format (in UTC).
      start_time = var.backup_configuration.start_time
      # The location where backups are stored.
      location = var.backup_configuration.location
      # Enables point-in-time recovery using write-ahead logs.
      point_in_time_recovery_enabled = var.backup_configuration.point_in_time_recovery_enabled
      # Configuration for transaction log retention.
      transaction_log_retention_days = var.backup_configuration.transaction_log_retention_days
    }

    # Optional maintenance window configuration.
    dynamic "maintenance_window" {
      for_each = var.maintenance_window != null ? [var.maintenance_window] : []
      content {
        # The day of the week (1-7), starting with Sunday.
        day = maintenance_window.value.day
        # The hour of the day (0-23) in UTC.
        hour = maintenance_window.value.hour
        # The update track (e.g., 'canary' or 'stable').
        update_track = maintenance_window.value.update_track
      }
    }

    # A list of database flags to apply to the instance.
    # The module automatically adds 'cloudsql.iam_authentication=On' if not specified by the user.
    dynamic "database_flags" {
      for_each = local.database_flags
      content {
        # The name of the database flag.
        name = database_flags.value.name
        # The value of the database flag.
        value = database_flags.value.value
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.private_network != null || var.enable_public_ip
      error_message = "Invalid network configuration: at least one of `private_network` or `enable_public_ip` must be specified."
    }
  }
}

# This resource manages the creation of read replicas for the primary Cloud SQL instance.
# It iterates over a map of replica configurations provided by the user.
resource "google_sql_database_instance" "replicas" {
  # Creates one replica for each entry in the var.read_replicas map.
  for_each = var.read_replicas

  # The project ID for the replica.
  project = var.project_id
  # The name of the replica instance, constructed from the primary name and the replica key.
  name = "${var.name}-${each.key}"
  # The region for the replica, same as the primary.
  region = var.region
  # The database version, must match the primary.
  database_version = var.database_version
  # Specifies the primary instance that this instance is a replica of.
  master_instance_name = google_sql_database_instance.main.name
  # Replicas also benefit from deletion protection. Defaults to the primary's setting.
  deletion_protection = coalesce(each.value.deletion_protection, var.deletion_protection)

  # Settings for the read replica instance.
  settings {
    # The machine tier for the replica. Can be different from the primary.
    tier = each.value.tier
    # Availability type for replicas is always ZONAL.
    availability_type = "ZONAL"
    # The disk type for the replica. Defaults to the primary's setting.
    disk_type = coalesce(each.value.disk_type, var.disk_type)
    # Enables automatic disk resizing for the replica. Defaults to the primary's setting.
    disk_autoresize = coalesce(each.value.disk_autoresize, var.disk_autoresize)
    # Sets the disk auto-resize limit for the replica. Defaults to the primary's setting.
    disk_autoresize_limit = coalesce(each.value.disk_autoresize_limit, var.disk_autoresize_limit)

    # IP configuration for the replica.
    ip_configuration {
      # Public IP setting for the replica. Defaults to the primary's setting.
      ipv4_enabled = coalesce(each.value.enable_public_ip, var.enable_public_ip)
      # Private network for the replica. Must be the same as the primary's.
      private_network = var.private_network
    }
  }

  lifecycle {
    precondition {
      condition     = var.private_network != null || coalesce(each.value.enable_public_ip, var.enable_public_ip)
      error_message = "Invalid network configuration for replica '${each.key}': at least one of `private_network` or `enable_public_ip` must be specified."
    }
  }
}

# This resource creates databases within the primary Cloud SQL instance.
# It iterates over a list of database configurations.
resource "google_sql_database" "main" {
  # Creates one database for each entry in the var.databases list.
  for_each = { for db in var.databases : db.name => db }

  # The project ID where the instance resides.
  project = var.project_id
  # The name of the primary instance to create the database in.
  instance = google_sql_database_instance.main.name
  # The name of the database.
  name = each.value.name
  # The character set for the database.
  charset = each.value.charset
  # The collation for the database.
  collation = each.value.collation
}

# This resource generates a random password for each database user of type 'BUILT_IN'.
# Using this resource avoids hardcoding passwords in configuration.
resource "random_password" "users" {
  # Creates one password for each 'BUILT_IN' user in the var.users list.
  for_each = local.sql_users

  # The length of the generated password.
  length = 16
  # Specifies that the password must include special characters.
  special = true
  # Ensures that special characters are not ambiguous (e.g. `()[]{}` vs `<>`).
  override_special = "!#$%&*?@^"
}

# This resource creates database users for the primary Cloud SQL instance.
# It supports both standard ('BUILT_IN') and IAM database users.
resource "google_sql_user" "main" {
  # Creates one user for each entry in the var.users list.
  for_each = { for user in var.users : user.name => user }

  # The project ID where the instance resides.
  project = var.project_id
  # The name of the primary instance to create the user in.
  instance = google_sql_database_instance.main.name
  # The name of the database user. For IAM users, this is an email address.
  name = each.value.name
  # The host from which the user can connect. Applicable only to 'BUILT_IN' users.
  host = each.value.host
  # The type of user. Can be 'BUILT_IN', 'CLOUD_IAM_USER', or 'CLOUD_IAM_SERVICE_ACCOUNT'.
  type = each.value.type
  # The password for the user. Only set for 'BUILT_IN' users.
  password = each.value.type == "BUILT_IN" ? random_password.users[each.key].result : null
}

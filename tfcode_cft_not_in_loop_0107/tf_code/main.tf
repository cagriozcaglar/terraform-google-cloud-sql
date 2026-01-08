# The main.tf file contains the core logic for creating the Cloud SQL resources.
# It defines the primary instance, optional read replicas, databases, and users.

locals {
  # Create maps from lists of objects for use in for_each loops.
  # This avoids issues with referencing list elements by index and allows for more flexible configuration.
  database_map = { for db in var.databases : db.name => db }
  user_map     = { for user in var.users : user.name => user }
  replica_map  = { for replica in var.read_replicas : replica.name => replica }

  # Determine if the database engine is MySQL or PostgreSQL.
  is_mysql_or_postgres = can(regex("^(MYSQL|POSTGRES)_", var.database_version))

  # Determine if binary logging needs to be enabled. It's required for Point-in-Time Recovery
  # and for creating read replicas, but only for MySQL and PostgreSQL engines.
  binary_logs_required = local.is_mysql_or_postgres && (var.enable_point_in_time_recovery || length(var.read_replicas) > 0)
}

# This resource generates a secure, random password for the instance's root user
# if one is not explicitly provided in the `root_password` variable.
resource "random_password" "root_password" {
  # The number of random passwords to generate. 1 if no password is provided, 0 otherwise.
  count = var.root_password == null ? 1 : 0

  # The length of the generated password.
  length = 24
  # Whether to include special characters in the generated password.
  special = true
  # A custom set of special characters to use, excluding ones that can cause issues in shell scripts or URIs.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# This resource generates secure, random passwords for database users who are defined
# without an explicit password in the `users` variable and are of type BUILT_IN.
resource "random_password" "user_passwords" {
  # Creates one password resource for each BUILT_IN user that has a null password.
  for_each = { for user in var.users : user.name => user if user.password == null && lookup(user, "type", "BUILT_IN") == "BUILT_IN" }

  # The length of the generated password.
  length = 24
  # Whether to include special characters in the generated password.
  special = true
  # A custom set of special characters to use.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# This is the main resource for the primary Cloud SQL instance.
# All settings, networking, and high-availability configurations are defined here.
resource "google_sql_database_instance" "primary" {
  # The GCP project ID. Defaults to the provider's project configuration.
  project = var.project_id
  # The name of the Cloud SQL instance.
  name = var.name
  # The region where the instance will be located.
  region = var.region
  # The database engine type and version.
  database_version = var.database_version
  # The password for the default administrative user. Generated if not provided.
  root_password = var.root_password != null ? var.root_password : random_password.root_password[0].result
  # Protects a database instance from accidental deletion. Recommended to be true for production.
  deletion_protection = var.deletion_protection_enabled
  # The full resource name of the KMS key to use for encryption.
  encryption_key_name = var.encryption_key_name

  settings {
    # The machine type for the instance.
    tier = var.tier
    # The availability type of the instance. `REGIONAL` provides high availability.
    availability_type = var.availability_type
    # The type of storage: `PD_SSD` or `PD_HDD`.
    disk_type = var.disk_type
    # The size of the storage disk in GB.
    disk_size = var.disk_size
    # Enables automatic storage increases. Recommended to be true to prevent outages due to full disks.
    disk_autoresize = var.disk_autoresize
    # The maximum size to which the disk can be automatically resized. 0 means no limit.
    disk_autoresize_limit = var.disk_autoresize_limit
    # User-defined labels to organize and manage the instance.
    user_labels = var.user_labels

    # Enables or disables IAM database authentication.
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = var.enable_iam_authentication ? "On" : "Off"
    }

    # A dynamic block to configure additional database flags.
    dynamic "database_flags" {
      # Iterates over the list of flags provided in the `database_flags` variable.
      for_each = var.database_flags
      content {
        # The name of the database flag.
        name = database_flags.value.name
        # The value of the database flag.
        value = database_flags.value.value
      }
    }

    # A dynamic block to configure the location preference (zone) for the instance.
    dynamic "location_preference" {
      # Creates the block only if a zone is specified.
      for_each = var.zone != null ? [var.zone] : []
      content {
        # The preferred compute engine zone.
        zone = location_preference.value
      }
    }

    # Configuration for IP-based access control.
    ip_configuration {
      # Whether this instance should have a public IP address. Default is false for security.
      ipv4_enabled = var.enable_public_ip
      # The self-link of the VPC network for private IP connectivity.
      private_network = var.enable_private_ip ? var.private_network_self_link : null
      # The name of the allocated IP range for private services access.
      allocated_ip_range = var.allocated_ip_range_name

      # A dynamic block to configure authorized networks for public IP access.
      dynamic "authorized_networks" {
        # Iterates over the list of authorized networks if public IP is enabled.
        for_each = var.enable_public_ip ? var.authorized_networks : []
        content {
          # The CIDR value of the authorized network.
          value = authorized_networks.value.value
          # An optional name for the authorized network.
          name = lookup(authorized_networks.value, "name", null)
          # An optional expiration time for the authorized network.
          expiration_time = lookup(authorized_networks.value, "expiration_time", null)
        }
      }
    }

    # Configuration for backups and point-in-time recovery.
    backup_configuration {
      # Whether automated backups are enabled.
      enabled = var.enable_backup
      # The start time for the daily backup window in HH:MM format (UTC).
      start_time = var.backup_start_time
      # Enables point-in-time recovery, allowing restores to any second within the retention period.
      point_in_time_recovery_enabled = var.enable_point_in_time_recovery
      # Enables binary logging, which is required for PITR and read replicas for certain database engines.
      binary_log_enabled = local.binary_logs_required
    }

    # A dynamic block to configure the maintenance window.
    dynamic "maintenance_window" {
      # Creates the block only if a maintenance window is defined.
      for_each = var.maintenance_window != null ? [var.maintenance_window] : []
      content {
        # The day of the week (1-7), starting with Sunday.
        day = maintenance_window.value.day
        # The hour of the day in UTC (0-23).
        hour = maintenance_window.value.hour
        # The update track, e.g., 'stable' or 'canary'.
        update_track = lookup(maintenance_window.value, "update_track", "stable")
      }
    }
  }

  # Ensure that required variables are provided based on other settings.
  lifecycle {
    precondition {
      condition     = var.availability_type != "ZONAL" || var.zone != null
      error_message = "The 'zone' variable must be specified when 'availability_type' is 'ZONAL'."
    }
    precondition {
      condition     = !var.enable_private_ip || var.private_network_self_link != null
      error_message = "When 'enable_private_ip' is true, 'private_network_self_link' must be provided."
    }
  }
}

# This resource creates read replica instances.
# Read replicas offload read traffic from the primary instance, improving performance.
resource "google_sql_database_instance" "replicas" {
  # Creates one replica for each entry in the `var.read_replicas` variable.
  for_each = local.replica_map

  # The GCP project ID.
  project = var.project_id
  # The name of the read replica instance.
  name = each.value.name
  # The region for the replica, which must be the same as the primary.
  region = var.region
  # The database version, which must match the primary.
  database_version = var.database_version
  # Specifies the primary instance this instance is replicating from.
  master_instance_name = google_sql_database_instance.primary.name
  # Protects the replica from accidental deletion.
  deletion_protection = var.deletion_protection_enabled

  settings {
    # The machine type for the replica. Can differ from the primary.
    tier = each.value.tier
    # The type of storage for the replica.
    disk_type = lookup(each.value, "disk_type", "PD_SSD")
    # The size of the replica's disk. If not specified, matches the primary.
    disk_size = lookup(each.value, "disk_size", null)
    # Whether to enable automatic storage increases for the replica.
    disk_autoresize = lookup(each.value, "disk_autoresize", true)
    # User-defined labels for the replica.
    user_labels = lookup(each.value, "user_labels", {})

    # A dynamic block to configure database flags for the replica.
    dynamic "database_flags" {
      for_each = lookup(each.value, "database_flags", [])
      content {
        # The name of the database flag.
        name = database_flags.value.name
        # The value of the database flag.
        value = database_flags.value.value
      }
    }

    # A dynamic block to configure the location preference (zone) for the replica.
    dynamic "location_preference" {
      # Creates the block only if a zone is specified for the replica.
      for_each = lookup(each.value, "zone", null) != null ? [each.value.zone] : []
      content {
        # The preferred compute engine zone.
        zone = location_preference.value
      }
    }

    # IP configuration for the replica.
    ip_configuration {
      # Whether the replica should have a public IP address.
      ipv4_enabled = lookup(each.value, "enable_public_ip", false)
      # Replicas use the same private network as the primary.
      private_network = var.enable_private_ip ? var.private_network_self_link : null

      # A dynamic block for authorized networks if the replica has a public IP.
      dynamic "authorized_networks" {
        for_each = lookup(each.value, "enable_public_ip", false) ? lookup(each.value, "authorized_networks", []) : []
        content {
          # The CIDR value of the authorized network.
          value = authorized_networks.value.value
          # An optional name for the authorized network.
          name = lookup(authorized_networks.value, "name", null)
        }
      }
    }
  }
}

# This resource creates databases within the primary Cloud SQL instance.
resource "google_sql_database" "databases" {
  # Creates one database for each entry in the `var.databases` variable.
  for_each = local.database_map

  # The GCP project ID.
  project = var.project_id
  # The name of the instance where the database will be created.
  instance = google_sql_database_instance.primary.name
  # The name of the database.
  name = each.value.name
  # The character set for the database.
  charset = lookup(each.value, "charset", null)
  # The collation for the database.
  collation = lookup(each.value, "collation", null)
}

# This resource creates user accounts for the primary Cloud SQL instance.
# It supports both built-in (password) and IAM-based users.
resource "google_sql_user" "users" {
  # Creates one user for each entry in the `var.users` variable.
  for_each = local.user_map

  # The GCP project ID.
  project = var.project_id
  # The name of the instance where the user will be created.
  instance = google_sql_database_instance.primary.name
  # The username for the database user (or email for IAM user).
  name = each.value.name
  # The hostname from which the user can connect.
  host = lookup(each.value, "host", null)
  # The type of user, e.g., BUILT_IN, IAM_USER, IAM_SERVICE_ACCOUNT.
  type = lookup(each.value, "type", "BUILT_IN")
  # The password for the user. Only set for BUILT_IN users. Uses a generated password if one is not provided.
  password = lookup(each.value, "type", "BUILT_IN") == "BUILT_IN" ? (each.value.password != null ? each.value.password : random_password.user_passwords[each.key].result) : null
}

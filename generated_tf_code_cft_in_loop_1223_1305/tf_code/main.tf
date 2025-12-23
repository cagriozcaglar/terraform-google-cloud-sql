# The main.tf file defines the core resources of the Terraform module.
# This module creates a Google Cloud SQL instance, along with associated databases, users, and optional read replicas,
# following enterprise best practices for security, availability, and data protection.
#
# Best Practices Implemented:
# - Network Isolation: Defaults to private IP, discouraging public IP usage.
# - IAM Database Authentication: Enabled by default, with support for creating IAM database users for password-less, secure access.
# - High Availability: Encourages 'REGIONAL' availability for production workloads.
# - Data Protection: Deletion protection and automated backups are enabled by default.
# - Cost Control: Automatic storage increase is enabled to prevent outages, with an optional limit for cost governance.
# - Workload Isolation: Supports easy configuration of read replicas to offload analytical queries.
#
# For disaster recovery, it is recommended to supplement automated backups with periodic database exports to Cloud Storage.
# Exports are independent of the instance and protect against accidental deletion or regional outages.
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

locals {
  # Applies default values to the user list.
  users_with_defaults = [
    for user in var.users : {
      name     = user.name
      type     = user.type
      password = user.password
      host     = user.type == "BUILT_IN" ? coalesce(user.host, "%") : null
    }
  ]

  # Prepares a map of database users, identifying which ones need a random password.
  # This allows for declaratively managing users where some have predefined passwords and others have generated ones.
  users_to_create = { for i, u in local.users_with_defaults : i => u }

  # Identifies the subset of users who require a password to be generated because one was not provided.
  # Password generation is only applicable for BUILT_IN users.
  users_needing_password = { for i, u in local.users_to_create : i => u if u.type == "BUILT_IN" && u.password == null }

  # Merges user-defined database flags with the IAM authentication flag if it's enabled.
  # This ensures IAM authentication can be toggled without overwriting other custom flags, and prevents duplicate flag errors.
  user_flags_map = { for flag in var.database_flags : flag.name => flag.value }
  iam_flag_map   = var.iam_authentication_enabled ? { "cloudsql.iam_authentication" = "on" } : {}
  merged_flags_map = merge(
    local.user_flags_map,
    local.iam_flag_map
  )

  # Applies default values to the read_replicas map.
  # This is done to simplify the variable type definition and avoid potential issues with tooling that generates metadata.
  replicas_with_defaults = {
    for k, v in var.read_replicas : k => {
      region                        = v.region
      zone                          = v.zone
      database_flags                = v.database_flags == null ? [] : v.database_flags
      user_labels                   = v.user_labels == null ? {} : v.user_labels
      ip_configuration_ipv4_enabled = v.ip_configuration_ipv4_enabled == null ? false : v.ip_configuration_ipv4_enabled
      private_network               = v.private_network == null ? var.private_network : v.private_network
    }
  }
}

# Generate a random password for the root user if one is not provided.
resource "random_password" "root_password" {
  # This resource is only created if the root_password variable is null.
  count = var.root_password == null ? 1 : 0

  # The length of the generated password.
  length = 20
  # Determines if special characters should be included in the password.
  special = true
  # Overrides the default set of special characters to avoid issues with some database clients.
  override_special = "_%@[]"
}

# Generates a random password for each database user that does not have one specified.
# This resource is conditionally created for each BUILT_IN user identified in `local.users_needing_password`.
resource "random_password" "user_password" {
  # Creates one random password resource for each user needing a password.
  for_each = local.users_needing_password

  # The length of the generated password.
  length = 20
  # Determines if special characters should be included in the password.
  special = true
  # Overrides the default set of special characters to avoid issues with some database clients.
  override_special = "_%@[]"
}

# The primary Cloud SQL database instance.
# This is the central resource managed by the module.
resource "google_sql_database_instance" "primary" {
  # The project ID to create the instance in. If not set, the provider's project will be used.
  project = var.project_id
  # The name of the Cloud SQL instance. This does not include the project ID.
  name = var.name
  # The database engine version to use.
  database_version = var.database_version
  # The region where the instance will sit.
  region = var.region
  # The initial root password. If not set, a random one will be generated.
  # Note: This is only set on creation and subsequent changes are ignored.
  root_password = var.root_password == null ? random_password.root_password[0].result : var.root_password
  # The name of the Cloud KMS key to use for encryption.
  encryption_key_name = var.encryption_key_name

  # Settings to configure the instance.
  settings {
    # The machine type to use.
    tier = var.tier
    # The availability type of the instance. Can be `ZONAL` or `REGIONAL`.
    # `REGIONAL` provides high availability.
    availability_type = var.availability_type
    # The type of storage disk. `PD_SSD` or `PD_HDD`.
    disk_type = var.disk_type
    # The size of the storage disk in GB.
    disk_size = var.disk_size
    # Enables automatic storage increases.
    disk_autoresize = var.disk_autoresize
    # The maximum size to which storage can be automatically increased.
    disk_autoresize_limit = var.disk_autoresize_limit
    # A set of key/value user label pairs to assign to the instance.
    user_labels = var.user_labels

    # Configuration for IP addresses, both private and public.
    ip_configuration {
      # Whether this instance should have a public IP address.
      ipv4_enabled = var.ip_configuration_ipv4_enabled
      # The VPC network to which the instance is connected for private IP.
      private_network = var.private_network
      # A list of CIDR blocks authorized to connect to the public IP.
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          # A name for this authorized network.
          name = authorized_networks.value.name
          # The CIDR block to allow.
          value = authorized_networks.value.value
        }
      }
    }

    # Configuration for automated backups.
    # This block is only included if backups are enabled.
    dynamic "backup_configuration" {
      for_each = var.backup_enabled ? [1] : []
      content {
        # If set to true, automated backups are enabled.
        enabled = true
        # The start time for the daily backup window, in HH:MM format in the instance's timezone.
        start_time = var.backup_start_time
        # The location to store the backups.
        location = var.backup_location
        # For PostgreSQL and SQL Server, use point_in_time_recovery_enabled. This is controlled by the point_in_time_recovery_enabled variable.
        point_in_time_recovery_enabled = (startswith(var.database_version, "POSTGRES_") || startswith(var.database_version, "SQLSERVER_")) ? var.point_in_time_recovery_enabled : null
        # For MySQL, point-in-time recovery is enabled by turning on binary logging. This is controlled by the point_in_time_recovery_enabled variable.
        binary_log_enabled = startswith(var.database_version, "MYSQL_") ? var.point_in_time_recovery_enabled : null
      }
    }

    # Custom database flags to apply to the instance.
    dynamic "database_flags" {
      for_each = local.merged_flags_map
      content {
        # The name of the flag.
        name = database_flags.key
        # The value of the flag.
        value = database_flags.value
      }
    }

    # The maintenance window for the instance.
    # This block is only included if a maintenance window is specified.
    dynamic "maintenance_window" {
      for_each = var.maintenance_window != null ? [var.maintenance_window] : []
      content {
        # The day of the week (1-7), starting with Monday.
        day = maintenance_window.value.day
        # The hour of the day (0-23) in UTC time.
        hour = maintenance_window.value.hour
      }
    }
  }

  # Protects the instance from accidental deletion.
  deletion_protection = var.deletion_protection
}

# Represents a database within the primary Cloud SQL instance.
resource "google_sql_database" "default" {
  # Creates one database for each item in the `var.databases` list.
  for_each = { for db in var.databases : db.name => db }

  # The project ID. If not set, the provider's project will be used.
  project = var.project_id
  # The name of the database.
  name = each.value.name
  # The Cloud SQL instance to create the database in.
  instance = google_sql_database_instance.primary.name
  # The character set for the database.
  charset = each.value.charset
  # The collation for the database.
  collation = each.value.collation
}

# Represents a user in the primary Cloud SQL instance.
resource "google_sql_user" "default" {
  # Creates one user for each item in the `var.users` list.
  for_each = local.users_to_create

  # The project ID. If not set, the provider's project will be used.
  project = var.project_id
  # The name of the user. For IAM users, this must be an email address.
  name = each.value.name
  # The Cloud SQL instance to create the user in.
  instance = google_sql_database_instance.primary.name
  # The type of the user, e.g. BUILT_IN or CLOUD_IAM_SERVICE_ACCOUNT.
  type = each.value.type
  # The host from which the user can connect. Applicable only for BUILT_IN users.
  host = each.value.host
  # The password for the user. Applicable only for BUILT_IN users. If not provided, a random one is generated.
  password = each.value.type == "BUILT_IN" ? (each.value.password != null ? each.value.password : random_password.user_password[each.key].result) : null
}

# A read replica of the primary Cloud SQL instance.
# Read replicas are used to offload read traffic and for analytics workloads.
resource "google_sql_database_instance" "replica" {
  # Creates one replica for each item in the `local.replicas_with_defaults` map.
  for_each = local.replicas_with_defaults

  # The project ID. If not set, the provider's project will be used.
  project = var.project_id
  # The name of the replica instance.
  name = "${var.name}-${each.key}"
  # The database engine version, inherited from the primary.
  database_version = google_sql_database_instance.primary.database_version
  # The region for the replica. Defaults to the primary's region if not specified.
  region = each.value.region != null ? each.value.region : google_sql_database_instance.primary.region
  # The name of the instance that this instance is a replica of.
  master_instance_name = google_sql_database_instance.primary.name
  # Replicas cannot have deletion protection enabled.
  deletion_protection = false

  # Settings for the replica instance. Many settings are inherited from the primary instance.
  settings {
    # The machine type, inherited from the primary.
    tier = google_sql_database_instance.primary.settings[0].tier
    # The type of storage disk, inherited from the primary.
    disk_type = google_sql_database_instance.primary.settings[0].disk_type
    # The size of the storage disk, inherited from the primary.
    disk_size = google_sql_database_instance.primary.settings[0].disk_size
    # Whether to enable automatic storage increases, inherited from the primary.
    disk_autoresize = google_sql_database_instance.primary.settings[0].disk_autoresize
    # The maximum size to which storage can be automatically increased, inherited from the primary.
    disk_autoresize_limit = google_sql_database_instance.primary.settings[0].disk_autoresize_limit
    # A set of key/value user label pairs.
    user_labels = each.value.user_labels

    # The preferred location for the replica.
    # This block is only included for ZONAL instances where a specific zone is requested.
    dynamic "location_preference" {
      for_each = google_sql_database_instance.primary.settings[0].availability_type == "ZONAL" && each.value.zone != null ? [each.value.zone] : []
      content {
        # The preferred zone for the instance.
        zone = location_preference.value
      }
    }

    # IP configuration for the replica.
    ip_configuration {
      # Whether the replica should have a public IP.
      ipv4_enabled = each.value.ip_configuration_ipv4_enabled
      # The VPC network for the replica's private IP.
      private_network = each.value.private_network
    }

    # Custom database flags for the replica.
    dynamic "database_flags" {
      for_each = { for flag in each.value.database_flags : flag.name => flag }
      content {
        # The name of the flag.
        name = database_flags.value.name
        # The value of the flag.
        value = database_flags.value.value
      }
    }
  }
}

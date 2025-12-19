# This module provisions a Google Cloud SQL instance, databases, and users,
# adhering to enterprise best practices for security, reliability, and maintainability.
# It supports PostgreSQL, MySQL, and SQL Server database engines.
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

resource "google_sql_database_instance" "main" {
  # The project ID to host the instance in.
  project = var.project_id
  # The name of the Cloud SQL instance. This does not include the project ID.
  name = var.name
  # The database engine version to use. See https://cloud.google.com/sql/docs/db-versions for supported versions.
  database_version = var.database_version
  # The region where the instance will be located.
  region = var.region
  # The password for the root user. If not set, a random one will be generated and available in the state file.
  # Required for SQL Server instances.
  root_password = var.root_password
  # Used to block Terraform from deleting a SQL Instance.
  deletion_protection = var.deletion_protection
  # The name of the Cloud KMS key to be used for encrypting the disk.
  encryption_key_name = var.encryption_key_name

  settings {
    # The machine type to use. See https://cloud.google.com/sql/docs/instance-settings for details.
    tier = var.tier
    # The availability type of the Cloud SQL instance. Can be ZONAL or REGIONAL.
    # Regional instances provide high availability and are recommended for production.
    availability_type = var.availability_type
    # The size of the storage in gigabytes.
    disk_size = var.disk_size
    # The type of storage to use. Can be PD_SSD or PD_HDD.
    disk_type = var.disk_type
    # This setting enables the automatic increase of storage size when the instance is running out of disk space.
    disk_autoresize = var.disk_autoresize
    # The maximum size to which storage can be auto-increased. A value of 0 means no limit.
    disk_autoresize_limit = var.disk_autoresize_limit
    # The edition of the instance, can be ENTERPRISE or ENTERPRISE_PLUS.
    edition = var.edition
    # Whether SSL connections are required for this instance. This is a security best practice.
    require_ssl = var.require_ssl

    # IP configuration settings.
    ip_configuration {
      # Whether this Cloud SQL instance should be assigned a public IPV4 address.
      ipv4_enabled = var.ip_configuration.ipv4_enabled
      # The VPC network from which the Cloud SQL instance is accessible for private IP.
      private_network = var.ip_configuration.private_network

      # Dynamic block for authorized networks.
      dynamic "authorized_networks" {
        for_each = var.ip_configuration.authorized_networks
        content {
          # The name of the authorized network.
          name = authorized_networks.value.name
          # The CIDR range of the authorized network.
          value           = authorized_networks.value.value
          expiration_time = lookup(authorized_networks.value, "expiration_time", null)
        }
      }
    }

    # Backup configuration settings.
    backup_configuration {
      # If set to false, automated backups are disabled.
      enabled = var.backup_configuration.enabled
      # The start time of the daily backup window in HH:MM format.
      start_time = var.backup_configuration.start_time
      # The location of the backup.
      location = var.backup_configuration.location
      # If set to true, point-in-time recovery is enabled.
      point_in_time_recovery_enabled = var.backup_configuration.point_in_time_recovery_enabled

      # Backup retention settings.
      backup_retention_settings {
        # Number of backups to retain.
        retained_backups = var.backup_configuration.backup_retention_settings.retained_backups
        # The unit that 'retained_backups' represents.
        retention_unit = var.backup_configuration.backup_retention_settings.retention_unit
      }
    }

    # Dynamic block for the maintenance window.
    dynamic "maintenance_window" {
      for_each = var.maintenance_window != null ? [var.maintenance_window] : []
      content {
        # The day of week (1-7) for the maintenance window.
        day = maintenance_window.value.day
        # The hour of day (0-23) for the maintenance window.
        hour = maintenance_window.value.hour
        # The update track for this instance.
        update_track = lookup(maintenance_window.value, "update_track", null)
      }
    }

    # List of database flags to apply to the instance.
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        # Name of the flag.
        name = database_flags.value.name
        # Value of the flag.
        value = database_flags.value.value
      }
    }
  }
}

# Resource to create databases within the Cloud SQL instance.
resource "google_sql_database" "main" {
  # Creates a map of databases from the input list, using the database name as the key.
  for_each = { for db in var.databases : db.name => db }

  # The project ID of the instance.
  project = google_sql_database_instance.main.project
  # The name of the Cloud SQL instance.
  instance = google_sql_database_instance.main.name
  # The name of the database.
  name = each.value.name
  # The charset for the database.
  charset = lookup(each.value, "charset", null)
  # The collation for the database.
  collation = lookup(each.value, "collation", null)
}

# Resource to create users for the Cloud SQL instance.
resource "google_sql_user" "main" {
  # Creates a map of users from the input list, using the username as the key.
  for_each = { for user in var.users : user.name => user }

  # The project ID of the instance.
  project = google_sql_database_instance.main.project
  # The name of the Cloud SQL instance.
  instance = google_sql_database_instance.main.name
  # The name of the user.
  name = each.value.name
  # The password for the user.
  password = each.value.password
  # The host for the user.
  host = lookup(each.value, "host", null)
  # The type of the user.
  type = lookup(each.value, "type", null)
}

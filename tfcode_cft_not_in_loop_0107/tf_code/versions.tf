# The versions.tf file specifies the Terraform and provider versions required by the module.
terraform {
  # This module is compatible with Terraform 1.0 and later.
  required_version = ">= 1.0"

  required_providers {
    # The google provider is used to manage Google Cloud resources.
    google = {
      source  = "hashicorp/google"
      version = ">= 4.40.0"
    }
    # The random provider is used to generate random passwords for database users.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

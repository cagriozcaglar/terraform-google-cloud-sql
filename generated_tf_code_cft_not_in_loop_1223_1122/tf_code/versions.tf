# This file is for the terraform block and provider configuration
terraform {
  # This module is meant for use with Terraform 1.3 and higher.
  required_version = ">= 1.3"

  required_providers {
    # The Google provider is used to manage Google Cloud resources.
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
    # The Random provider is used to generate random passwords for database users.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

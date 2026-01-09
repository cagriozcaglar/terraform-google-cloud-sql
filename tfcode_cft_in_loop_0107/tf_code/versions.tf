# This file provides provider requirements for the Terraform module.
terraform {
  # Specifies the minimum required version of Terraform.
  required_version = ">= 1.3"

  # Specifies the required providers and their versions.
  required_providers {
    # The Google Cloud provider is used to manage Google Cloud resources.
    google = {
      source  = "hashicorp/google"
      version = ">= 4.40.0"
    }
    # The Random provider is used to generate unique names and passwords.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

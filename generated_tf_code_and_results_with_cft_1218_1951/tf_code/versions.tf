terraform {
  # This module is tested with Terraform 1.3 and forward.
  required_version = ">= 1.3"
  required_providers {
    # Google Cloud SQL provider version.
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

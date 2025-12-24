# The versions.tf file is used to specify the required Terraform version and the versions of the providers used in the module.
terraform {
  # This module is designed to be compatible with Terraform 1.3 and newer.
  required_version = ">= 1.3"

  # This block specifies the required providers and their version constraints.
  # Using version constraints ensures that future provider updates with breaking changes
  # do not unexpectedly break the module.
  required_providers {
    # The Google Provider is used to manage Google Cloud Platform resources.
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # The Random Provider is used to generate random values, such as secure passwords for database users.
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

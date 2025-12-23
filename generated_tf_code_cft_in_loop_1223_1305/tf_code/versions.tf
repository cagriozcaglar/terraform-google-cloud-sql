terraform {
  # Specifies the required version of Terraform.
  # This ensures that the module is used with a compatible version of the Terraform CLI.
  required_version = ">= 1.3"

  # Specifies the required providers and their versions.
  # This ensures that the module uses compatible versions of the provider plugins.
  required_providers {
    # The Google Cloud provider is used to manage resources on Google Cloud Platform.
    google = {
      source  = "hashicorp/google"
      version = ">= 5.15.0"
    }
    # The Random provider is used to generate random values, such as passwords.
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

# The versions.tf file is used to specify the version of Terraform and the providers that are required by the configuration.
# This ensures that the code is run with compatible versions of the tools, which helps to prevent errors and ensure that the code behaves as expected.
terraform {
  # Specifies the required version of Terraform.
  # The ~> operator allows for patch releases within a specific minor release.
  required_version = ">= 1.3"

  # Specifies the required versions of the providers.
  # Providers are plugins that Terraform uses to interact with APIs of cloud providers, SaaS providers, and other APIs.
  required_providers {
    # The Google Provider is used to interact with the many resources supported by Google Cloud Platform.
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

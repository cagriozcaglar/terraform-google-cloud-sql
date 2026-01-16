variable "project_id" {
  description = "The GCP Project ID to deploy the Cloud SQL instance and supporting resources."
  type        = string
}

variable "region" {
  description = "The GCP region to deploy the Cloud SQL instance and supporting resources."
  type        = string
  default     = "us-central1"
}

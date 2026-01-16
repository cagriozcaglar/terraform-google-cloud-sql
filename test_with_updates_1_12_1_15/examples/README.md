# Basic PostgreSQL Example

This example demonstrates how to use the Cloud SQL module to provision a private PostgreSQL instance.

The example creates all the necessary prerequisite infrastructure for a secure, private-only deployment, including:
- A new VPC Network.
- A Private Service Access (PSA) connection required for Cloud SQL to connect to the VPC.
- The Cloud SQL instance itself, configured with no public IP address.
- A database named `app_database` inside the instance.
- A user named `app_user` with a randomly generated password.

## How to use this example

1.  Configure your GCP credentials:

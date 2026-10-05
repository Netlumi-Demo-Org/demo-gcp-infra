terraform {
  required_version = ">= 1.10.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.40"
    }
  }

  # Remote state in a GCS bucket in the demo project (created once, see
  # README "Apply"). Netlumi reads it to map findings to this code.
  # Credentials come from the environment (application-default credentials
  # or GOOGLE_OAUTH_ACCESS_TOKEN).
  backend "gcs" {
    bucket = "acme-ledger-tfstate-291502462067"
    prefix = "demo-gcp-infra"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region

  # Bill API quota to the demo project, so user credentials work without a
  # separate quota project.
  user_project_override = true
  billing_project       = var.project_id

  default_labels = local.common_labels
}

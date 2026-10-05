terraform {
  required_version = ">= 1.10.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.40"
    }
  }

  # State is kept outside this repository. Point it at a local file when you
  # initialise, for example:
  #   terraform init -backend-config="path=$HOME/acme-ledger-gcp-state/terraform.tfstate"
  # Swap this block for `backend "gcs" {}` to keep the state in a bucket.
  backend "local" {}
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

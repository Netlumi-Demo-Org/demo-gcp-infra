# Acme Ledger: a small invoicing SaaS. This root holds the app's GCP
# footprint (storage, a VPC, service accounts, a KMS key, an analytics
# dataset, a container registry). There is no compute. Several resources
# carry deliberate misconfigurations for the Netlumi demo; each is marked
# "PLANTED FINDING" and listed in README.md.

locals {
  name   = "acme-ledger"
  suffix = data.google_project.this.number

  # Applied to every resource that supports labels (provider default_labels).
  # Resources without labels (network, subnetwork, firewall rules, service
  # accounts) say the same in their description.
  common_labels = {
    purpose = "netlumi-demo"
    owner   = "netlumi"
  }
  label_note = "purpose=netlumi-demo owner=netlumi"
}

data "google_project" "this" {
  project_id = var.project_id
}

# Only the APIs this stack uses. Cloud Asset Inventory is what Netlumi reads
# the project through. Disabling on destroy is off: other things may use them.
resource "google_project_service" "this" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
  ])

  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

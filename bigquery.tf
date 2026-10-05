# PLANTED FINDING: the analytics dataset grants READER to
# allAuthenticatedUsers, that is any Google account. The dataset is empty
# (no tables).
# Expected: netlumi_gcp_bigquery_dataset_public_access.
# Fix PR: remove the allAuthenticatedUsers access block.
resource "google_bigquery_dataset" "analytics" {
  dataset_id    = "acme_ledger_analytics"
  friendly_name = "Acme Ledger analytics"
  description   = "Invoice analytics for Acme Ledger (fictional, empty)"
  location      = "US"

  delete_contents_on_destroy = true

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "READER"
    special_group = "allAuthenticatedUsers"
  }

  depends_on = [google_project_service.this]
}

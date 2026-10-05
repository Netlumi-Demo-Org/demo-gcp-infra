# PLANTED FINDING: a "public assets" bucket readable by anyone on the internet
# (allUsers -> roles/storage.objectViewer), with public access prevention left
# at "inherited". It holds one harmless placeholder text file and nothing else.
# Expected: netlumi_gcp_storage_bucket_public_access.
# Fix PR: remove the allUsers binding and set public_access_prevention = "enforced".
resource "google_storage_bucket" "public_assets" {
  name          = "${local.name}-public-assets-${local.suffix}"
  location      = "US-CENTRAL1"
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.this]
}

resource "google_storage_bucket_iam_member" "public_assets_all_users" {
  bucket = google_storage_bucket.public_assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "public_assets_placeholder" {
  bucket       = google_storage_bucket.public_assets.name
  name         = "placeholder.txt"
  content_type = "text/plain"
  content      = <<-EOT
    Placeholder file for the Netlumi public demo.
    Acme Ledger is a fictional company. This bucket holds no real data.
  EOT
}

# PLANTED FINDINGS: the invoice-exports bucket uses legacy fine-grained ACLs
# (uniform bucket-level access off), keeps no object versions and has soft
# delete switched off, so an overwritten or deleted export is gone for good.
# It is private (public access prevention enforced) and empty.
# Expected:
#   netlumi_gcp_storage_bucket_uniform_access_disabled
#   netlumi_gcp_storage_bucket_versioning_disabled
#   netlumi_gcp_storage_bucket_soft_delete_disabled
# Fix PR: uniform_bucket_level_access = true, versioning { enabled = true },
# and drop the soft_delete_policy override (the default keeps 7 days).
resource "google_storage_bucket" "invoice_exports" {
  name          = "${local.name}-invoice-exports-${local.suffix}"
  location      = "US-CENTRAL1"
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = false
  public_access_prevention    = "enforced"

  versioning {
    enabled = false
  }

  soft_delete_policy {
    retention_duration_seconds = 0
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.this]
}

# Reference bucket for contrast: uniform access, public access prevention
# enforced, versioning, default soft delete, lifecycle rule.
resource "google_storage_bucket" "audit_archive" {
  name          = "${local.name}-audit-archive-${local.suffix}"
  location      = "US-CENTRAL1"
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.this]
}

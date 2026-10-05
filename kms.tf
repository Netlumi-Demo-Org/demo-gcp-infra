# KMS key rings and keys cannot be deleted in GCP. A destroy removes them from
# state and schedules the key versions for destruction; the names stay taken.
resource "google_kms_key_ring" "main" {
  name     = local.name
  location = var.region

  depends_on = [google_project_service.this]
}

# PLANTED FINDING: the invoice encryption key has no rotation period.
# Expected: netlumi_gcp_kms_key_rotation_over_90_days.
# Fix PR: rotation_period = "7776000s" (90 days).
resource "google_kms_crypto_key" "invoices" {
  name     = "${local.name}-invoices"
  key_ring = google_kms_key_ring.main.id
  purpose  = "ENCRYPT_DECRYPT"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
}

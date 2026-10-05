output "public_assets_bucket" {
  description = "Public assets bucket name."
  value       = google_storage_bucket.public_assets.name
}

output "invoice_exports_bucket" {
  description = "Invoice exports bucket name."
  value       = google_storage_bucket.invoice_exports.name
}

output "audit_archive_bucket" {
  description = "Audit archive bucket name."
  value       = google_storage_bucket.audit_archive.name
}

output "network" {
  description = "VPC network self link."
  value       = google_compute_network.main.self_link
}

output "ci_deployer_email" {
  description = "CI deployer service account."
  value       = google_service_account.ci_deployer.email
}

output "app_runtime_email" {
  description = "App runtime service account."
  value       = google_service_account.app_runtime.email
}

output "invoices_kms_key" {
  description = "Invoice encryption key id."
  value       = google_kms_crypto_key.invoices.id
}

output "analytics_dataset" {
  description = "Analytics dataset id."
  value       = google_bigquery_dataset.analytics.id
}

output "containers_repository" {
  description = "Container repository id."
  value       = google_artifact_registry_repository.containers.id
}

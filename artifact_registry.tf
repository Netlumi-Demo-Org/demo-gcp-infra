# PLANTED FINDINGS: the container repository is readable by anyone
# (allUsers -> roles/artifactregistry.reader) and has automatic vulnerability
# scanning switched off. It is empty.
# Expected:
#   netlumi_gcp_artifactregistry_repository_public
#   netlumi_gcp_artifactregistry_vulnerability_scanning_disabled
# Fix PR: remove the allUsers binding; enablement_config = "INHERITED".
resource "google_artifact_registry_repository" "containers" {
  repository_id = "${local.name}-containers"
  description   = "Acme Ledger container images"
  location      = var.region
  format        = "DOCKER"

  vulnerability_scanning_config {
    enablement_config = "DISABLED"
  }

  depends_on = [google_project_service.this]
}

resource "google_artifact_registry_repository_iam_member" "containers_all_users" {
  repository = google_artifact_registry_repository.containers.name
  location   = google_artifact_registry_repository.containers.location
  role       = "roles/artifactregistry.reader"
  member     = "allUsers"
}

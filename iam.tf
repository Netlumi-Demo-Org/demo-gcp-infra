# Service accounts have no user-managed keys; nothing here can be used from
# outside the project.

resource "google_service_account" "ci_deployer" {
  account_id   = "${local.name}-ci-deployer"
  display_name = "Acme Ledger CI deployer"
  description  = "Deploys Acme Ledger from CI (${local.label_note})"

  depends_on = [google_project_service.this]
}

# PLANTED FINDING: the CI deployer holds the basic Editor role on the whole
# project.
# Expected: netlumi_gcp_iam_sa_no_administrative_privileges.
# Fix PR: replace roles/editor with the specific roles the pipeline needs
# (for example roles/storage.objectAdmin on the buckets it deploys to).
resource "google_project_iam_member" "ci_deployer_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.ci_deployer.email}"
}

resource "google_service_account" "app_runtime" {
  account_id   = "${local.name}-app-runtime"
  display_name = "Acme Ledger app runtime"
  description  = "Runtime identity of the Acme Ledger app (${local.label_note})"

  depends_on = [google_project_service.this]
}

# PLANTED FINDING: Service Account User granted at project level, so the app
# runtime can act as every service account in the project (including the CI
# deployer above).
# Expected: netlumi_gcp_iam_no_service_account_roles_at_project_level.
# Fix PR: grant roles/iam.serviceAccountUser on the one service account that
# needs it (google_service_account_iam_member), not on the project.
resource "google_project_iam_member" "app_runtime_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.app_runtime.email}"
}

# Acme Ledger VPC. There are no instances in it; the firewall rules apply to
# nothing today, which is what makes them easy to miss.

resource "google_compute_network" "main" {
  name                    = "${local.name}-vpc"
  description             = "Acme Ledger VPC (${local.label_note})"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.this]
}

# PLANTED FINDINGS: no VPC flow logs (no log_config block) and Private Google
# Access off.
# Expected:
#   netlumi_gcp_compute_subnet_flow_logs_disabled
#   netlumi_gcp_compute_subnet_private_google_access_disabled
# Fix PR: add a log_config block and private_ip_google_access = true.
resource "google_compute_subnetwork" "app" {
  name          = "${local.name}-app-${var.region}"
  description   = "Acme Ledger app subnet (${local.label_note})"
  network       = google_compute_network.main.id
  region        = var.region
  ip_cidr_range = "10.20.0.0/24"

  private_ip_google_access = false
}

# PLANTED FINDING: SSH open to the internet.
# Expected: netlumi_gcp_compute_firewall_ssh_open_to_internet.
# Fix PR: narrow source_ranges (for example to the IAP range 35.235.240.0/20).
resource "google_compute_firewall" "allow_ssh" {
  name        = "${local.name}-allow-ssh"
  description = "Bastion SSH (${local.label_note})"
  network     = google_compute_network.main.id
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# PLANTED FINDING: RDP open to the internet.
# Expected: netlumi_gcp_compute_firewall_rdp_open_to_internet.
# Fix PR: narrow source_ranges or remove the rule.
resource "google_compute_firewall" "allow_rdp" {
  name        = "${local.name}-allow-rdp"
  description = "Windows reporting host RDP (${local.label_note})"
  network     = google_compute_network.main.id
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reporting"]

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
}

# PLANTED FINDING: PostgreSQL open to the internet ("temporary" debug rule).
# Expected: netlumi_gcp_compute_firewall_database_ports_open_to_internet.
# Fix PR: remove the rule, or restrict source_ranges to the app subnet.
resource "google_compute_firewall" "allow_postgres_debug" {
  name        = "${local.name}-allow-postgres-debug"
  description = "Temporary Postgres access for debugging (${local.label_note})"
  network     = google_compute_network.main.id
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["db"]

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }
}

# Reference rule for contrast: internal traffic only.
resource "google_compute_firewall" "allow_internal" {
  name        = "${local.name}-allow-internal"
  description = "Internal traffic within the app subnet (${local.label_note})"
  network     = google_compute_network.main.id
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = [google_compute_subnetwork.app.ip_cidr_range]

  allow {
    protocol = "tcp"
    ports    = ["443", "8080"]
  }
}

# PLANTED FINDING: OS Login explicitly turned off in project metadata, so any
# future VM falls back to metadata SSH keys.
# Expected: netlumi_gcp_compute_project_os_login_disabled.
# Fix PR: value = "TRUE".
resource "google_compute_project_metadata_item" "enable_oslogin" {
  key   = "enable-oslogin"
  value = "FALSE"

  depends_on = [google_project_service.this]
}

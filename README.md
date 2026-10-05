# demo-gcp-infra

GCP infrastructure for **Acme Ledger**, a fictional invoicing SaaS used in the
Netlumi public demo. It is real, applyable Terraform with a handful of
**deliberate misconfigurations**. Netlumi scans the GCP project (through Cloud
Asset Inventory), maps each finding back to this code, and opens a fix pull
request here.

**Demo content. Nothing here belongs to a real company, and no real data is
stored anywhere in it.** The only object in the stack is a two-line
placeholder text file.

## Architecture

```
                     Acme Ledger (project netlumi-demo, us-central1)
  ┌──────────────────────────────────────────────────────────────────────┐
  │  Cloud Storage                                                       │
  │    acme-ledger-public-assets-<projnum>   (allUsers read, 1 txt file) │
  │    acme-ledger-invoice-exports-<projnum> (fine-grained ACLs, empty)  │
  │    acme-ledger-audit-archive-<projnum>   (reference "good" bucket)   │
  │                                                                      │
  │  VPC  acme-ledger-vpc (custom mode)                                  │
  │    subnet acme-ledger-app-us-central1  10.20.0.0/24                  │
  │    firewall acme-ledger-allow-ssh / -rdp / -postgres-debug / -internal│
  │    (no instances: the rules apply to nothing today)                  │
  │  Project metadata  enable-oslogin = FALSE                            │
  │                                                                      │
  │  IAM  acme-ledger-ci-deployer   roles/editor on the project          │
  │       acme-ledger-app-runtime   roles/iam.serviceAccountUser (proj.) │
  │       (no user-managed keys on either)                               │
  │                                                                      │
  │  Cloud KMS        key ring acme-ledger / key acme-ledger-invoices    │
  │  BigQuery         dataset acme_ledger_analytics (US, empty)          │
  │  Artifact Registry acme-ledger-containers (Docker, empty)            │
  └──────────────────────────────────────────────────────────────────────┘
  State: local file outside this repository (see Apply).
```

There is no compute: no VMs, GKE, Cloud SQL, Cloud Run, load balancers or
NAT. Expected cost is about **US$0.06 a month** (one active KMS key version);
empty buckets, an empty dataset, an empty registry, a VPC, a subnet and
firewall rules cost nothing, and the placeholder file is a few bytes.

Every resource that supports labels carries `purpose = netlumi-demo` and
`owner = netlumi` (provider `default_labels`). Networks, subnetworks,
firewall rules and service accounts have no labels in GCP; their
descriptions say `purpose=netlumi-demo owner=netlumi` instead.

## Planted findings

Rule files live in the Netlumi repository under
`core-services/dumb-detector/rules/final-dsl-rules/`; the line is the rule's
`match` condition.

| # | Terraform address | File | Expected rule id | Rule file:line | Fix the PR should make |
|---|---|---|---|---|---|
| 1 | `google_storage_bucket.public_assets` + `google_storage_bucket_iam_member.public_assets_all_users` (allUsers objectViewer, PAP `inherited`) | `storage.tf` | `netlumi_gcp_storage_bucket_public_access` | `gcp-storage/netlumi_gcp_storage_bucket_public_access.yaml:14-17` (`iamPublic == true` and PAP not `enforced`) | Remove the allUsers binding; `public_access_prevention = "enforced"` |
| 2 | `google_storage_bucket.invoice_exports` (`uniform_bucket_level_access = false`) | `storage.tf` | `netlumi_gcp_storage_bucket_uniform_access_disabled` | `gcp-storage/netlumi_gcp_storage_bucket_uniform_access_disabled.yaml:15-16` | `uniform_bucket_level_access = true` |
| 3 | `google_storage_bucket.invoice_exports` (`versioning { enabled = false }`) | `storage.tf` | `netlumi_gcp_storage_bucket_versioning_disabled` | `gcp-storage/netlumi_gcp_storage_bucket_versioning_disabled.yaml:15-16` | `versioning { enabled = true }` |
| 4 | `google_storage_bucket.invoice_exports` (`soft_delete_policy { retention_duration_seconds = 0 }`) | `storage.tf` | `netlumi_gcp_storage_bucket_soft_delete_disabled` | `gcp-storage/netlumi_gcp_storage_bucket_soft_delete_disabled.yaml:15-16` | Drop the override (default keeps 7 days) |
| 5 | `google_compute_subnetwork.app` (no `log_config`) | `network.tf` | `netlumi_gcp_compute_subnet_flow_logs_disabled` | `gcp-compute/netlumi_gcp_compute_subnet_flow_logs_disabled.yaml:18-19` | Add a `log_config` block |
| 6 | `google_compute_subnetwork.app` (`private_ip_google_access = false`) | `network.tf` | `netlumi_gcp_compute_subnet_private_google_access_disabled` | `gcp-compute/netlumi_gcp_compute_subnet_private_google_access_disabled.yaml:18-19` | `private_ip_google_access = true` |
| 7 | `google_compute_firewall.allow_ssh` (tcp/22 from `0.0.0.0/0`) | `network.tf` | `netlumi_gcp_compute_firewall_ssh_open_to_internet` | `gcp-compute/netlumi_gcp_compute_firewall_ssh_open_to_internet.yaml:14-24` | Narrow `source_ranges` (e.g. IAP `35.235.240.0/20`) or remove |
| 8 | `google_compute_firewall.allow_rdp` (tcp/3389 from `0.0.0.0/0`) | `network.tf` | `netlumi_gcp_compute_firewall_rdp_open_to_internet` | `gcp-compute/netlumi_gcp_compute_firewall_rdp_open_to_internet.yaml:14-24` | Narrow `source_ranges` or remove |
| 9 | `google_compute_firewall.allow_postgres_debug` (tcp/5432 from `0.0.0.0/0`) | `network.tf` | `netlumi_gcp_compute_firewall_database_ports_open_to_internet` | `gcp-compute/netlumi_gcp_compute_firewall_database_ports_open_to_internet.yaml:17-26` | Remove, or restrict to the app subnet |
| 10 | `google_compute_project_metadata_item.enable_oslogin` (`FALSE`) | `network.tf` | `netlumi_gcp_compute_project_os_login_disabled` | `gcp-compute/netlumi_gcp_compute_project_os_login_disabled.yaml:15-16` | `value = "TRUE"` |
| 11 | `google_project_iam_member.ci_deployer_editor` (SA holds `roles/editor`) | `iam.tf` | `netlumi_gcp_iam_sa_no_administrative_privileges` (on the project) | `gcp-iam/netlumi_gcp_iam_sa_no_administrative_privileges.yaml:14` | Replace `roles/editor` with narrow roles |
| 12 | `google_project_iam_member.app_runtime_sa_user` (`roles/iam.serviceAccountUser` at project level) | `iam.tf` | `netlumi_gcp_iam_no_service_account_roles_at_project_level` (on the project) | `gcp-iam/netlumi_gcp_iam_no_service_account_roles_at_project_level.yaml:15-16` | Grant on the one service account instead (`google_service_account_iam_member`) |
| 13 | `google_kms_crypto_key.invoices` (no `rotation_period`) | `kms.tf` | `netlumi_gcp_kms_key_rotation_over_90_days` | `gcp-kms/netlumi_gcp_kms_key_rotation_over_90_days.yaml:14-17` | `rotation_period = "7776000s"` |
| 14 | `google_bigquery_dataset.analytics` (READER for `allAuthenticatedUsers`) | `bigquery.tf` | `netlumi_gcp_bigquery_dataset_public_access` | `gcp-bigquery/netlumi_gcp_bigquery_dataset_public_access.yaml:16` | Remove that `access` block |
| 15 | `google_artifact_registry_repository_iam_member.containers_all_users` (allUsers reader) | `artifact_registry.tf` | `netlumi_gcp_artifactregistry_repository_public` | `gcp-artifactregistry/netlumi_gcp_artifactregistry_repository_public.yaml:14` | Remove the allUsers binding |
| 16 | `google_artifact_registry_repository.containers` (`enablement_config = "DISABLED"`) | `artifact_registry.tf` | `netlumi_gcp_artifactregistry_vulnerability_scanning_disabled` | `gcp-artifactregistry/netlumi_gcp_artifactregistry_vulnerability_scanning_disabled.yaml:14-19` | `enablement_config = "INHERITED"` |

What is deliberately clean, for contrast: the audit-archive bucket (uniform
access, public access prevention enforced, versioning, default soft delete,
lifecycle rule), the invoice-exports bucket's public access prevention, the
`acme-ledger-allow-internal` firewall rule (app subnet only) and the absence
of service account keys.

Notes:

- **(1)** the bucket is publicly readable on purpose, but it holds only
  `placeholder.txt`, a two-line text file saying the company is fictional.
  Never put anything else in it.
- **(11)** and **(12)** are project-level rules: the finding is on the
  `cloudresourcemanager.project` asset and names the binding.
- **(16)** with the Container Scanning API off, GCP also reports
  `enablementState = SCANNING_DISABLED`.
- Pub/Sub is not part of the stack: Netlumi does not collect Pub/Sub topics
  yet, so nothing there would be found.
- Enabling the Compute Engine API makes GCP create, outside Terraform, a
  `default` auto-mode network with the `default-allow-ssh`, `-rdp`, `-icmp`
  and `-internal` firewall rules, and a Compute Engine default service account
  holding `roles/editor`. They are not in this code, so their findings
  (`netlumi_gcp_compute_network_default_in_use`, SSH/RDP open on
  `default-allow-*`, a second editor service account) have no file to map to.
  Delete the default network in the project if you want only code-mapped
  findings.
- Broader rules will also fire and are not the point of the demo, for example:
  bucket access logging and retention policy (every bucket), BigQuery default
  CMEK, Data Access audit logs, log-metric alerts, a personal Google account
  holding `roles/owner`.

## Apply

Requires Terraform >= 1.10 and gcloud. Run with credentials for the target
project (`gcloud auth application-default login`, or export
`GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"` for the
session). `project_id` has no default, so nothing runs until you name the
project.

```bash
PROJECT_ID=<gcp-project-id>
STATE_DIR=$HOME/acme-ledger-gcp-state   # anywhere outside this repository

# 1. Terraform reads the project through the Resource Manager API (once).
gcloud services enable cloudresourcemanager.googleapis.com --project "$PROJECT_ID"

# 2. Stack
terraform init -backend-config="path=$STATE_DIR/terraform.tfstate"
terraform plan -var project_id=$PROJECT_ID -out="$STATE_DIR/demo.tfplan"
# review the plan, then:
terraform apply "$STATE_DIR/demo.tfplan"
```

Then connect the project and this repository to Netlumi and let the scheduled
scan run.

## Destroy

**Never run a destroy without Prem's explicit go-ahead.** The demo project and
this stack are shared by every demo visitor.

```bash
terraform plan -destroy -var project_id=$PROJECT_ID -out="$STATE_DIR/destroy.tfplan"
terraform apply "$STATE_DIR/destroy.tfplan"
```

Buckets use `force_destroy = true`, so a destroy also deletes their objects.
Cloud KMS key rings and keys cannot be deleted: a destroy schedules the key
versions for destruction and the names stay taken. APIs stay enabled
(`disable_on_destroy = false`).

## Checks

```bash
terraform fmt -recursive -check
terraform init -backend=false && terraform validate
```

## Licence

MIT. See [LICENSE](LICENSE).

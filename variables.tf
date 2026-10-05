variable "project_id" {
  description = "GCP project this stack is applied to. Required; no default on purpose."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project id."
  }
}

variable "region" {
  description = "GCP region for regional resources."
  type        = string
  default     = "us-central1"
}

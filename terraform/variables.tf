variable "project" {
  description = "GCP project name"
  default     = "<your-project-id>"
}

variable "region" {
  description = "Project region"
  default     = "us-west1"
}

variable "zone" {
  description = "Project zone"
  default     = "us-west1-b"
}

variable "min_master_version" {
  description = "GKE cluster version"
  default     = "1.24.5-gke.600"
}

variable "gke_service_account" {
  description = "GKE service account"
  default     = "<your-gke-service-account>"
}

variable "machine_type" {
  description = "GKE node machine type"
  default     = "n1-standard-1"
}

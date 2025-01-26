provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_storage_bucket" "function_code" {
  name     = "elasticstack-function-code"
  location = var.gcp_region
}

resource "google_storage_bucket_object" "function_code_archive" {
  name   = "function-code.zip"
  bucket = google_storage_bucket.function_code.bucket
  source = "function-code.zip"  # Path to your zipped function code
}

resource "google_cloudfunctions_function" "elasticstack_function" {
  name        = "elasticstack-function"
  description = "Cloud Function for scaling GCP Compute instances"
  runtime     = "python38"
  entry_point = "cloud_function"
  source_archive_bucket = google_storage_bucket.function_code.bucket
  source_archive_object = google_storage_bucket_object.function_code_archive.name

  environment_variables = {
    GCP_PROJECT_ID   = var.gcp_project_id
    GCP_ZONE         = var.gcp_zone
    GCP_INSTANCE_NAME = var.gcp_instance_name
  }
}

resource "google_project_iam_binding" "function_invocation_role" {
  project = var.gcp_project_id
  role    = "roles/cloudfunctions.invoker"
  members = ["allUsers"]
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  default     = "us-central1-a"
}

variable "gcp_instance_name" {
  description = "GCP instance name to scale"
  type        = string
}
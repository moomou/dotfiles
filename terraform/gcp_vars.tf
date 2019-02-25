variable "region" {
  type    = "string"
  default = "us-west1"

  description = <<EOF
Region in which to create the cluster and run Atlantis.
EOF
}

variable "project" {
  type    = "string"

  description = <<EOF
Project ID where Terraform is authenticated to run to create additional
projects.
EOF
}

variable "billing_account" {
  type = "string"

  description = <<EOF
Billing account ID.
EOF
}

variable "project_services" {
  type = "list"

  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "storage_bucket_roles" {
  type = "list"

  default = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]
}

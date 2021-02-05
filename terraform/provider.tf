# Google Cloud providers
provider "google" {
  project     = "${var.gcp_project}" 
  region      = "${var.region}"
  zone        = "${var.zone}"
}
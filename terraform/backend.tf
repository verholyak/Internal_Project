# Cloud Storage bucket for storing the Terraform state
terraform {
    backend "gcs" {
      bucket      = "bookshelf-tfstate"
      prefix      = "state/terraform.tfstate"
  }
}

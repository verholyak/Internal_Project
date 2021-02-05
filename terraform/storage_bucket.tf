# Create Bucket for DataBase
resource "google_storage_bucket" "bucket_db" {
  name          = "${var.name}-bucket-db"
  force_destroy = true
}
resource "random_string" "db_password" {
  length = 16
  special = true
}

resource "google_secret_manager_secret" "db_secret" {
  secret_id = "db_password"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_secret" {
  secret = google_secret_manager_secret.db_secret.id
  secret_data = "${random_string.db_password.result}"
}
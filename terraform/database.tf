resource "random_id" "db_suffix" {
  byte_length = 4
}

# Create MySQL
resource "google_sql_database_instance" "mysql_db" {
    name = "${var.name}-${random_id.db_suffix.hex}"  
    database_version = "MYSQL_5_7"
    deletion_protection = false

  settings {
    tier = "db-n1-standard-1"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }

  depends_on = [google_compute_network.vpc, google_service_networking_connection.private_connection]
}

# Create DataBase
resource "google_sql_database" "database" {
  name                = "${var.name}"
  instance            = "${google_sql_database_instance.mysql_db.name}"
  
  depends_on          = [google_sql_database_instance.mysql_db]
}

# Create User for DataBase 
resource "google_sql_user" "users" {
  name     = "${var.user_db}"
  instance = "${google_sql_database_instance.mysql_db.name}"
  host     = "%"
  password = "${google_secret_manager_secret_version.db_secret.secret_data}"
}
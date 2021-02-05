output "CLOUDSQL_NAME" { 
    value = "${google_sql_database_instance.mysql_db.name}"
}
output "CLOUDSQL_USER" { 
    value = "${var.user_db}"
}
output "CLOUDSQL_PASSWORD" { 
    value = "${google_secret_manager_secret_version.db_secret.secret_data}"
}
output "CLOUDSQL_DATABASE" { 
    value = "${var.name}"
}
output "CLOUDSQL_CONNECTION_NAME" { 
    value = "${google_sql_database_instance.mysql_db.connection_name}"
}
output "CLOUD_STORAGE_BUCKET" { 
    value = "${var.name}-bucket-db"
}
output "GOOGLE_SERVICE_ACCOUNT" { 
    value = "${google_service_account.bookshelf_service_account.email}"
}
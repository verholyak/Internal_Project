resource "google_service_account" "bookshelf_service_account" {
  project = "project-bookshelf-301816"
  account_id = "bookshelf-service-account"
  display_name = "Bookshelf Service Account"
}

resource "google_project_iam_member" "bookshelf_iam" {
  project = "project-bookshelf-301816"
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.bookshelf_service_account.email}"
  depends_on = [google_service_account.bookshelf_service_account]
}
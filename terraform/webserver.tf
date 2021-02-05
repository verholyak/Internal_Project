resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "${var.name}-autoscaler"
  region = "${var.region}"
  target = google_compute_region_instance_group_manager.group_manager.id

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 2
    cooldown_period = 300

    cpu_utilization {
      target = 0.8
    }
  }
}

# Create templane
resource "google_compute_instance_template" "bookshelf_template" {
  name                    = "${var.name}-template"
  machine_type            = "${var.machine_type}"
  region                  = "${var.region}"
  metadata_startup_script = file("../scripts/startup-1.sh")
  metadata = {
    CLOUDSQL_USER            = "${var.user_db}"
    CLOUDSQL_PASSWORD        = "${google_secret_manager_secret_version.db_secret.secret_data}"
    CLOUDSQL_DATABASE        = "${var.name}"
    CLOUDSQL_CONNECTION_NAME = "${google_sql_database_instance.mysql_db.connection_name}"
    CLOUD_STORAGE_BUCKET     = "${var.name}-bucket-db"
  }
 
  disk {
    source_image = "${var.disk_source_image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = google_compute_network.vpc.id
  }

  tags = ["${var.firewall_name}"]

  service_account {
    email  = "${google_service_account.bookshelf_service_account.email}"
    scopes = ["cloud-platform"]  
  }
  
}

# Create health check for backend instances
resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/books/"
    port         = "5100"
  }
}

# Create instance region group manager
resource "google_compute_region_instance_group_manager" "group_manager" {
  name                      = "${var.name}-appserver"
  region                    = "${var.region}"
  base_instance_name        = "appserver"
  distribution_policy_zones = ["us-central1-a", "us-central1-f"]

  version {
   instance_template  = google_compute_instance_template.bookshelf_template.id
  }

  target_size  = 2

  named_port {
    name = "http"
    port = 5100
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }

  depends_on = [google_sql_database_instance.mysql_db, google_compute_network.vpc]
}

# Create backend service (BackEnd)
resource "google_compute_backend_service" "backend" {
  project     = "${var.gcp_project}"
  name        = "${var.name}-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  enable_cdn  = false

  backend {
    group = "${google_compute_region_instance_group_manager.group_manager.instance_group}"
  }

  health_checks = ["${google_compute_health_check.autohealing.self_link}"]
}

# Create FrontEnd forwarding
resource "google_compute_global_forwarding_rule" "forwarding" {
  name       = "${var.name}-frontend"
  target     = google_compute_target_http_proxy.forwarding.id
  port_range = "80"
  ip_address = null
}

# Create proxy
resource "google_compute_target_http_proxy" "forwarding" {
  name    = "${var.name}-target-proxy"
  url_map = google_compute_url_map.forwarding.id
}

# Create map
resource "google_compute_url_map" "forwarding" {
  name            = "${var.name}-url"
  default_service = google_compute_backend_service.backend.id
}

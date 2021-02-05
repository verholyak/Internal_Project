# Create VPC
resource "google_compute_network" "vpc" {
  name     = "${var.name}-vpc"
}

# Create Firewall
resource "google_compute_firewall" "firewall" {
  name    = "${var.name}-firewall"
  network = "${google_compute_network.vpc.name}"
   
  allow {
    protocol = "tcp"
    ports    = "${var.server_port}"
  }

  target_tags   = ["${var.firewall_name}"]
}

# Create Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}-subnet"
  region        = "${var.region}"
  ip_cidr_range = "${var.subnet_cidr}"
  network       = google_compute_network.vpc.id
  depends_on    = ["google_compute_network.vpc"]
}

# Create router
resource "google_compute_router" "router" {
  name    = "${var.name}-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.id
  
  bgp {
    asn = 64514
  }
}

# Create nat
resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Create private ip for MySQL server
resource "google_compute_global_address" "private_ip" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Create peering for MySQL server
resource "google_service_networking_connection" "private_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}
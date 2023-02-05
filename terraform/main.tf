resource "google_container_cluster" "primary" {
  name                     = "general-cluster"
  location                 = var.zone
  remove_default_node_pool = true
  initial_node_count       = 1
  min_master_version       = var.min_master_version
  network                  = google_compute_network.net.id
  subnetwork               = google_compute_subnetwork.subnet.id
  vertical_pod_autoscaling {
    enabled = true
  }
  node_config {
    service_account = var.gke_service_account
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }
  private_cluster_config {
    master_ipv4_cidr_block  = "<your-ip>"
    enable_private_endpoint = false
    enable_private_nodes    = true
  }
  ip_allocation_policy {
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "IP"
      display_name = "xxx"
    }
  }
}

resource "google_compute_network" "net" {
  project                 = var.project
  name                    = "gke-network"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "default" {
  name    = "gke-firewall"
  network = google_compute_network.net.name

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  target_tags = ["gke-general-cluster-f2712353-node"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnetwork"
  network       = google_compute_network.net.id
  ip_cidr_range = "<your-ip>"
  region        = var.region
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 6

  node_config {
    preemptible     = false
    machine_type    = var.machine_type
    disk_size_gb    = "30"
    disk_type       = "pd-standard"
    image_type      = "COS_CONTAINERD"
    local_ssd_count = "0"
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.gke_service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    shielded_instance_config {
      enable_integrity_monitoring = "true"
      enable_secure_boot          = "false"
    }
  }
  autoscaling {
    max_node_count = 5
    min_node_count = 0
  }
  upgrade_settings {
    max_surge       = "1"
    max_unavailable = "0"
  }
  version = var.min_master_version
  depends_on = [
    google_container_cluster.primary
  ]
}

resource "google_compute_router" "router" {
  name    = "gke-router"
  region  = var.region
  network = google_compute_network.net.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "gke-router-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

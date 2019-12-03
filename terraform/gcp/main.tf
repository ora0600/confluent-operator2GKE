provider "google" {
  credentials = file("account.json")
  project = var.project
  region = var.region
}

resource "google_container_cluster" "cluster" {
  timeouts {
    delete = "120m"
  }

  name = "cp53-cluster"
  location = var.region

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.daily_maintenance_window_start_time
    }
  }
  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name = "cp53-node-pool"
  location = var.region
  cluster = google_container_cluster.cluster.name
  node_count = var.node_count
  node_config {
    // We use preemptible nodes because they're cheap (for testing purposes). Set this to false if you want consistent performance.
    preemptible = var.preemptible_nodes
    machine_type = "n1-standard-4"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  management {
    auto_upgrade = false
  }

  provisioner "local-exec" {
    command = "./destroy.sh"
    when = "destroy"
  }
}

resource "null_resource" "setup-cluster" {
  depends_on = [
    google_container_cluster.cluster
  ]
  triggers = {
    id = google_container_cluster.cluster.id
    reg = var.region
    prj = var.project
    // Re-run script on deployment script changes
    script = sha1(file("00_setup_GKE.sh"))
  }

  provisioner "local-exec" {
    command = "./00_setup_GKE.sh ${google_container_cluster.cluster.name} ${var.region} ${var.project}"
  }
}

resource "null_resource" "setup-messaging" {
  depends_on = [
    null_resource.setup-cluster
  ]

  provisioner "local-exec" {
    command = "../../01_installConfluentPlatform.sh ${var.region} ${var.cprovider}"
  }
}

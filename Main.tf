provider "google" {
    credentials = file("jae-fleming-adfc3e3b9a68.json")
    project     = "jae-fleming"
    region      = "europe-west1"
}

resource "google_compute_instance" "europe_instance" {
    name         = "europe-instance"
    machine_type = "e2-micro"
    zone         = "europe-west1-b"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-10"
        }
    }

    network_interface {
        network = google_compute_network.europe_network.self_link
        subnetwork = google_compute_subnetwork.europe_subnet.self_link
    }
}

# Define the VPC and subnets for each region

# Europe region
resource "google_compute_network" "europe_network" {
    name                    = "europe-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "europe_subnet" {
    name          = "europe-subnet"
    ip_cidr_range = "10.0.0.0/24"
    network       = google_compute_network.europe_network.self_link
}

# Americas regions
resource "google_compute_network" "americas_network" {
    name                    = "americas-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "americas_subnet_1" {
    name          = "americas-subnet-1"
    ip_cidr_range = "172.16.0.0/24"
    network       = google_compute_network.americas_network.self_link
}

resource "google_compute_subnetwork" "americas_subnet_2" {
    name          = "americas-subnet-2"
    ip_cidr_range = "172.16.1.0/24"
    network       = google_compute_network.americas_network.self_link
}

# Asia Pacific region
resource "google_compute_network" "asia_network" {
    name                    = "asia-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "asia_subnet" {
    name          = "asia-subnet"
    ip_cidr_range = "192.168.0.0/24"
    network       = google_compute_network.asia_network.self_link
}

# Define firewall rules for each region

# Europe firewall rule
resource "google_compute_firewall" "europe_firewall" {
    name    = "europe-firewall"
    network = google_compute_network.europe_network.self_link

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports    = ["80"]
    }

    source_ranges = ["0.0.0.0/0"]
}

# Americas firewall rule
resource "google_compute_firewall" "americas_firewall" {
    name    = "americas-firewall"
    network = google_compute_network.americas_network.self_link

    allow {
        protocol = "tcp"
        ports    = ["80"]
    }

    source_ranges = ["172.16.1.0/24" , "172.16.2.0/24"]
}

# Asia Pacific firewall rule
resource "google_compute_firewall" "asia_firewall" {
    name    = "asia-firewall"
    network = google_compute_network.asia_network.self_link

    allow {
        protocol = "tcp"
        ports    = ["3389"]
    }

    source_ranges = ["192.168.0.0/24"]
}

resource "google_compute_network_peering" "my_peering" {
    name          = "my-peering"
    network       = google_compute_network.europe_network.self_link
    peer_network  = google_compute_network.peer_network.self_link
}

resource "google_compute_vpn_tunnel" "my_tunnel" {
    name            = "my-tunnel"
    peer_ip         = google_compute_vpn_gateway.peer_gateway.ip_address
    shared_secret   = var.shared_secret
    target_vpn_gateway = google_compute_vpn_gateway.my_gateway.self_link
    vpn_gateway_interface = "vpn_gateway_interface"
    local_traffic_selector = ["0.0.0.0/0"]
}

resource "google_compute_vpn_gateway" "my_gateway" {
    name = "my-gateway"
    network = google_compute_network.europe_network.self_link
}

resource "google_compute_vpn_gateway" "peer_gateway" {
    name = "peer-gateway"
    network = google_compute_network.peer_network.self_link
}

resource "google_compute_forwarding_rule" "my_forwarding_rule" {
    name = "my-forwarding-rule"
    target = google_compute_target_vpn_gateway.my_gateway.self_link
    ip_protocol = "rdp"
    port_range = "3389"
}

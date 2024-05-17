# Define the provider block
provider "google" {
    credentials = var.credentials_file
    project     = var.project
    region      = var.region
}

# Define the network and subnets for each region

# Europe region
resource "google_compute_network" "europenetwork" {
    name                    = "europenetwork"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "europe_subnet" {
    name          = "europe-subnet"
    ip_cidr_range = var.europe_subnet_cidr
    network       = google_compute_network.europenetwork.self_link
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
resource "google_compute_network" "asianetwork" {
    name                    = "asianetwork"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "asia_subnet" {
    name          = "asia-subnet"
    ip_cidr_range = "192.168.0.0/24"
    network       = google_compute_network.asianetwork.self_link
}

# Define firewall rules for each region

# Europe firewall rule
resource "google_compute_firewall" "europe_firewall" {
    name    = "europe-firewall"
    network = google_compute_network.europenetwork.self_link

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

    source_ranges = var.americas_firewall_source_ranges
}

# Asia Pacific firewall rule
resource "google_compute_firewall" "asia_firewall" {
    name    = "asia-firewall"
    network = google_compute_network.asianetwork.self_link

    allow {
        protocol = "tcp"
        ports    = ["3389"]
    }

    source_ranges = ["0.0.0.0/0"]
}

# Define network peering between Europe and Asia

resource "google_compute_network_peering" "europe_to_asia" {
    name          = "europe-to-asia"
    network       = google_compute_network.europenetwork.self_link
    peer_network  = google_compute_network.asianetwork.self_link
}

# Define VPN tunnels and gateways

resource "google_compute_vpn_gateway" "mygateway1" {
    name = "mygateway1"
    network = google_compute_network.asianetwork.self_link
}

resource "google_compute_vpn_gateway" "mygateway2" {
    name = "mygateway2"
    network = google_compute_network.europenetwork.self_link
}


resource "google_compute_vpn_tunnel" "mytunnel1" {
    name            = "my-tunnel1"
    target_vpn_gateway = google_compute_vpn_gateway.mygateway1.self_link
    peer_ip         = google_compute_address.asia_vpn_address.address
    shared_secret   = var.shared_secret
    ike_version    = 2
    local_traffic_selector = ["10.105.10.0/24"]
    remote_traffic_selector = ["192.168.2.0/24"]
    depends_on = [
        google_compute_forwarding_rule.udp_500_rule,
        google_compute_forwarding_rule.esp_rule,
        google_compute_forwarding_rule.udp_4500
        ]
}

resource "google_compute_vpn_gateway" "peergateway2" {
    name = "peergateway2"
    network = google_compute_network.asianetwork.self_link
}

resource "google_compute_vpn_tunnel" "mytunnel2" {
    name            = "my-tunnel2"
    target_vpn_gateway = google_compute_vpn_gateway.mygateway2.self_link
    peer_ip         = google_compute_address.asia_vpn_address.address
    shared_secret   = var.shared_secret
    ike_version    = 2
    local_traffic_selector = ["10.105.10.0/24"]
    remote_traffic_selector = ["192.168.2.0/24"]
    depends_on = [
        google_compute_forwarding_rule.udp_500_rule,
        google_compute_forwarding_rule.esp_rule,
        google_compute_forwarding_rule.udp_4500,
        ]
}

resource "google_compute_forwarding_rule" "udp_4500" {
    name        = "udp-4500-rule"
    target      = google_compute_vpn_gateway.mygateway2.self_link
    ip_protocol = "UDP"
    port_range  = "4500-4500"
    ip_address  = google_compute_address.europe_vpn_address.address
}
resource "google_compute_forwarding_rule" "udp_500_rule" {
    name        = "udp-500-rule"
    target      = google_compute_vpn_gateway.mygateway1.self_link
    ip_protocol = "UDP"
    port_range  = "500-500"
    ip_address  = google_compute_address.europe_vpn_address.address
}

resource "google_compute_forwarding_rule" "esp_rule" {
    name        = "esp-rule"
    target      = google_compute_vpn_gateway.mygateway2.self_link
    ip_protocol = "ESP"
    ip_address  = google_compute_address.europe_vpn_address.address
}
resource "google_compute_address" "europe_vpn_address" {
  name = "europe-vpn-address"
    region = "europe-west1"
}

resource "google_compute_address" "asia_vpn_address" {
  name = "asia-vpn-addres"
    region = "asia-east1"
}

output "europe_network" {
    value = google_compute_network.europenetwork.self_link

}

output "europe_subnet" {
    value = google_compute_subnetwork.europe_subnet.self_link
}

output "public_ip" {
    value = google_compute_address.europe_vpn_address.address
}

output "vpc" {
    value = google_compute_network.europenetwork.self_link
}

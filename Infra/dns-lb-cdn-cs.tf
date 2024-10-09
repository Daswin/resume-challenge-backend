#Create an Ip address and attach it to a managed dns zone

# Reserve an external IP
resource "google_compute_global_address" "ip" {
  name     = var.load-balance_external-ip
}

# Create a managed DNS zone
resource "google_dns_managed_zone" "terraformtestdns" {
  name     = "resumechallengesinclair"
  # dns_name = "resume.terraform.challenge.sinclair."
  dns_name = var.dns_name
  description = "DNS zone for domain: resume-challenge-sinclair.com"

  dnssec_config {
    state = "on"
  }
  
}

# Add the IP to the DNS
resource "google_dns_record_set" "ip" {
  name         = var.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.terraformtestdns.name
  rrdatas      = [google_compute_global_address.ip.address]
}

# # Add the IP to the DNS
# resource "google_dns_record_set" "www_ip" {
#   name         = "www.resume-challenge-sinclair.com."
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.terraformtestdns.name
#   rrdatas      = [google_compute_global_address.ip.address]
# }

# # Add the IP to the DNS
# resource "google_dns_record_set" "at_ip" {
#   name         = "@.resume-challenge-sinclair.com."
#   type         = "A"
#   ttl          = 300
#   managed_zone = google_dns_managed_zone.terraformtestdns.name
#   rrdatas      = [google_compute_global_address.ip.address]
# }


#Create a load balancer and enable CDN
# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "lb-backend" {
  name        = "resumechallengebackend-bucket"
  bucket_name = google_storage_bucket.terraformars_1958.name
  enable_cdn  = true
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "https-cert" {
  name     = "resumechallence-ssl"
  managed {
      # domains = ["resume-challenge-sinclair.com"]
      domains = [google_dns_record_set.ip.name]
  }
}

# URL MAP
resource "google_compute_url_map" "url-map" {
  name            = "url-map"
  default_service = google_compute_backend_bucket.lb-backend.self_link
}

#target proxy
resource "google_compute_target_https_proxy" "target-proxy" {
  name             = "target-proxy"
  url_map          = google_compute_url_map.url-map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.https-cert.self_link]
}

#forwarding rule
resource "google_compute_global_forwarding_rule" "rule" {
  name                  = "rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.ip.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.target-proxy.self_link
}
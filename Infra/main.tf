terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.18.0"
    }
  }
}

provider "google" {
  project = var.project
  region = var.region
  zone = var.zone
}

# create bucket in us with unique name
resource "google_storage_bucket" "terraformars_1958" {
  name  = var.bucket_name
  location = var.region
  force_destroy = true
  storage_class = "STANDARD" # Optional: Use STANDARD class for regional storage
  # Optional settings for the bucket
  uniform_bucket_level_access = true   # Enforce uniform access to the bucket (recommended for public access)

}

# test terraform git cloud build with bucket creation
resource "google_storage_bucket" "terraformars_1958_trial" {
  name  = "project-dev-cloudresumechallenge2024-trial"
  location = var.region
  force_destroy = true
  storage_class = "STANDARD" # Optional: Use STANDARD class for regional storage
  # Optional settings for the bucket
  uniform_bucket_level_access = true   # Enforce uniform access to the bucket (recommended for public access)

}

# Set the IAM policy to make the bucket publicly accessible
resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.terraformars_1958.id
  role   = "roles/storage.objectViewer"  # Grant read access to bucket objects
  member = "allUsers"                    # This makes the bucket publicly accessible
}

resource "google_storage_bucket_object" "htmlUpload" {
  bucket = google_storage_bucket.terraformars_1958.id
  name = "Resume.html"
  source = "C:/Users/daswi/Documents/Certifications/Professional Data Engineer/Projects/Resume Challenge GCP/Resume.html"
}

resource "google_storage_bucket_object" "cssUpload" {
  bucket = google_storage_bucket.terraformars_1958.id
  name = "style.css"
  source = "C:/Users/daswi/Documents/Certifications/Professional Data Engineer/Projects/Resume Challenge GCP/style.css"
}

resource "google_storage_bucket_object" "jsUpload" {
  bucket = google_storage_bucket.terraformars_1958.id
  name = "counter.js"
  source = "C:/Users/daswi/Documents/Certifications/Professional Data Engineer/Projects/Resume Challenge GCP/counter.js"
}

# -------------------PREPARING THE FILE TO BE ZIPPED AND UPLOADED--------------
data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/cloud-function-code.zip"
  source_dir  = "C:/Users/daswi/Documents/Certifications/Professional Data Engineer/Projects/Resume Challenge GCP/Cloud_function_code/"
}
# Add to bucket
resource "google_storage_bucket_object" "object" {
  name   = "cloud-function-code.zip"
  bucket = google_storage_bucket.terraformars_1958.name
  source = data.archive_file.default.output_path # Add path to the zipped function source code
}

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

# Add the IP to the DNS
resource "google_dns_record_set" "www_ip" {
  name         = "www.resume-challenge-sinclair.com."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.terraformtestdns.name
  rrdatas      = [google_compute_global_address.ip.address]
}

# Add the IP to the DNS
resource "google_dns_record_set" "at_ip" {
  name         = "@.resume-challenge-sinclair.com."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.terraformtestdns.name
  rrdatas      = [google_compute_global_address.ip.address]
}


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
      domains = ["resume-challenge-sinclair.com"]
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

#datebase creation
resource "google_firestore_database" "database" {
  name = "(default)"
  # nam5 = multi-region united states, eur3 = multi-region europe otherwise use the location you want if regional
  location_id = "nam5"
  type = "FIRESTORE_NATIVE"
}

resource "google_firestore_document" "table" {
  collection = "Visitors"
  fields = "{\"something\":{\"mapValue\":{\"fields\":{\"visitors\":{\"stringValue\":\"0\"}}}}}"
  document_id = "my-doc-id"
}

# -----------------------CLOUD FUNCTION CREATION----------------

# functionv2 type creation
resource "google_cloudfunctions2_function" "default" {
  name        = "cloud-visitor-counter-v2"
  location    = "us-central1"
  description = "a new function"

  build_config {
    runtime     = "python39"
    entry_point = "current_number_visitors" # Set the entry point
    
    source {
      storage_source {
        bucket = google_storage_bucket.terraformars_1958.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.default.location
  service  = google_cloudfunctions2_function.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

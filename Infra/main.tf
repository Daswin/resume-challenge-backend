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

# resource "google_storage_bucket_object" "htmlUpload" {
#   bucket = google_storage_bucket.terraformars_1958.id
#   name = "Resume.html"
#   source = "C:/Users/daswi/Documents/Certifications/Professional Data Engineer/Projects/Resume Challenge GCP/Resume.html"
# }

# resource "google_storage_bucket_object" "cssUpload" {
#   bucket = google_storage_bucket.terraformars_1958.id
#   name = "style.css"
#   source = "C:/Users/daswi/Documents/Certifications/Professional Data Engineer/Projects/Resume Challenge GCP/style.css"
# }

# resource "google_storage_bucket_object" "jsUpload" {
#   bucket = google_storage_bucket.terraformars_1958.id
#   name = "counter.js"
#   source = "C:/Users/daswi/Documents/Certifications/Professional Data Engineer/Projects/Resume Challenge GCP/counter.js"
# }



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



# -------------------PREPARING THE FILE TO BE ZIPPED AND UPLOADED--------------
data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/cloud-function-code.zip"
  source_dir  = "../Cloud_function_code/"
}

# Add to bucket
resource "google_storage_bucket_object" "object" {
  name   = "cloud-function-code.zip"
  bucket = google_storage_bucket.terraformars_1958.name
  source = data.archive_file.default.output_path # Add path to the zipped function source code
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
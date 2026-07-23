# 1. Enable Required GCP APIs
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore_api" {
  service = "firestore.googleapis.com"
  disable_on_destroy = false
}

# 2. Provision Firestore Database (Native Mode)
resource "google_firestore_database" "database" {
  project     = var.gcp_project_id
  name        = "(default)"
  location_id = "nam5" # US multi-region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.firestore_api]
}

# 3. Provision Cloud Run Service (Initial Placeholder)
resource "google_cloud_run_v2_service" "kivo_backend" {
  name     = "kivo-backend"
  location = var.gcp_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "gcr.io/${var.gcp_project_id}/kivo-backend:latest"
      
      env {
        name  = "NODE_ENV"
        value = "production"
      }
    }
  }

  depends_on = [google_project_service.cloud_run_api]
}

# 4. Make Cloud Run publicly accessible (Auth is handled internally via JWT)
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.kivo_backend.location
  project  = google_cloud_run_v2_service.kivo_backend.project
  service  = google_cloud_run_v2_service.kivo_backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# 5. Cloudflare DNS & Proxy Configuration
# Map the Cloud Run URL to the custom domain through Cloudflare's proxy for DDoS/Caching
resource "cloudflare_record" "api_cname" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  value   = trimprefix(google_cloud_run_v2_service.kivo_backend.uri, "https://")
  type    = "CNAME"
  proxied = true # Enables Cloudflare CDN, SSL, and DDoS Protection
}

# 6. Cloudflare Page Rule for API Caching (Bypass Cache for dynamic routes)
resource "cloudflare_page_rule" "bypass_api_cache" {
  zone_id = var.cloudflare_zone_id
  target  = "api.${var.domain_name}/*"
  status  = "active"
  priority = 1

  actions {
    cache_level = "bypass"
  }
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-east4" # Northern Virginia as requested
}

variable "cloudflare_api_token" {
  type = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
}

variable "domain_name" {
  type    = string
  default = "kivoapp.com"
}

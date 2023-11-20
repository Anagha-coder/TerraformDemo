# Bucket to store Website

resource "google_storage_bucket" "Website" {
    name     = "terraformdemo-website-by-anagha"
    location = "US"
  
}

# Make new Object Public
resource "google_storage_object_access_control" "public_rule" {
    object = google_storage_bucket_object.static_site_src.name
    bucket = google_storage_bucket.Website.name
    role = "READER"
    entity ="allusers"
}




# upload the html file to bucket
resource "google_storage_bucket_object" "static_site_src"{
    name = "index.html"
    source= "../website/index.html"
    bucket = google_storage_bucket.Website.name
}


# Reserve a static external IP address
resource "google_compute_global_address" "website_ip" {
    name = "wbsite-loadbalancer-ip"
  
}

#Get the managed DNS Zone
data "google_dns_managed_zone" "dns_zone"{
    name= "terraformdemo-gcp"
}

#Add the IP to the DNS
resource "google_dns_record_set" "Website"{
    name = "website.${data.google_dns_managed_zone.dns_zone.dns_name}"
    type = "A"
    ttl = 300
    managed_zone = data.google_dns_managed_zone.dns_zone.name
    rrdatas = [google_compute_global_address.website_ip.address]
}

#Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "website-backend" {
    name = "website-backend"
    bucket_name = google_storage_bucket.Website.name
    description = "Contains files needed for the website"
    enable_cdn = true
  
}

# GCP URL MAP
resource "google_compute_url_map" "Website" {
  provider        = google
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website-backend.self_link
    host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website-backend.self_link
  }
}
    



# GCP HTTP Proxy

resource "google_compute_target_http_proxy" "Website" {
    name ="website-target-proxy"
    url_map = google_compute_url_map.Website.self_link
  
}

# GCp forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
    name = "website-forwarding-rule"
    load_balancing_scheme = "EXTERNAL"
    ip_address = google_compute_global_address.website_ip.address
    ip_protocol = "TCP"
    port_range ="80"
    target = google_compute_target_http_proxy.Website.self_link
  
}
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


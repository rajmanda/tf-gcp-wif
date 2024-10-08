resource "google_storage_bucket" "my-tf-gcp-wif-bucket-01" {
  name          = "tf-gcp-wif-001"
  location      = "us-east1"
  force_destroy = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket" "my-tf-gcp-wif-bucket-02" {
  name          = "tf-gcp-wif-002"
  location      = "us-east1"
  force_destroy = true
  public_access_prevention = "enforced"
}

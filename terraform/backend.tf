# Remote state in S3 with native lockfile (Terraform >= 1.10).
# Create the bucket ONCE manually (versioning on) before running `terraform init`.
terraform {
  backend "s3" {
    bucket       = "REPLACE-WITH-YOUR-TFSTATE-BUCKET"
    key          = "devops-iac-project/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

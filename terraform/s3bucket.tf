# The storage bucket where all autoremediation configs will be stored

module "alarm-config-bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.bucket_name
  acl    = "private"

  versioning = {
    enabled = true
  }

  tags = {
    environment = "dev"
    app = "autoremediation"
  }

}

resource "aws_s3_object" "webapp-autoremediation-config-linux" {
  bucket = module.alarm-config-bucket.s3_bucket_id
  key    = "autoremediation-config/webapp-uptime#CustomNamespace.sh"
  source = "../auto-remediation-config/webapp-uptime#CustomNamespace.sh"

  depends_on = [
    module.alarm-config-bucket
  ]
}

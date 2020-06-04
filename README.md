# terraform-aws-s3-bucket-crr
## AWS S3 Bucket Cross-Region Replication
Terraform module for creating S3 Buckets with Cross-Region Replication enabled.

## Basic Usage
Include the following in your configuration (customized as needed):

```hcl
module "aws-crr-bucket" {
  source              = "git::https://github.com/travisz/terraform-aws-s3-bucket-crr?ref=master"
  primary_bucket_name = "example-bucket"
  replica_bucket_name = "example-bucket-replica"
  region_one          = "us-east-1"
  region_two          = "us-east-2"
}
```

If you need to enable deletes on the replica, set `replicate_delete` to `1`:
```hcl
module "aws-crr-bucket" {
  source                = "git::https://github.com/travisz/terraform-aws-s3-bucket-crr?ref=master"
  primary_bucket_name   = "example-bucket"
  replica_bucket_name   = "example-bucket-replica"
  region_one            = "us-east-1"
  region_two            = "us-east-2"
  replica_storage_class = "GLACIER"
  replicate_delete      = "1"
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-------:|:--------:|
| primary_bucket_name | Name of primary S3 Bucket | string | `` | yes |
| replica_bucket_name | Name of replica S3 Bucket | string | `` | yes |
| region_one | Name of the source region | string | `` | yes |
| region_two | Name of the destination region | string | `` | yes |
| replica_storage_class | Default storage class of the replica region | string | `GLACIER` | no |
| replicate_delete | Enable deletes on the replica bucket | string | `` | no |

## Notes
* The default storage class on the replica bucket is `GLACIER`.  This can be customized with the `replica_storage_class` variable.
* Replication of **deletes** is not enabled. If you need to enable this, set the variable `replicate_delete` to `1`.
* Make sure you set **unique** bucket names as the S3 namespace is a **global** namespace on AWS.

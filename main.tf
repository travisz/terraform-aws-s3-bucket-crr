# Providers (one for each region)
provider "aws" {
  region = var.region_one
}

provider "aws" {
  region = var.region_two
  alias  = "region2"
}

# Get the Acct ID
data "aws_caller_identity" "current" {}

# Random UUID
resource "random_uuid" "id" {}

# New KMS Key
resource "aws_kms_key" "s3key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}

# KMS Key for Second Region
resource "aws_kms_key" "s3replicakey" {
  provider                = aws.region2
  description             = "Replication Key"
  deletion_window_in_days = 7
}

# KMS Key Grant
resource "aws_kms_grant" "key" {
  name              = "replica-grant"
  key_id            = aws_kms_key.s3key.key_id
  grantee_principal = aws_iam_role.replication.arn
  operations        = ["Decrypt", "Encrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "DescribeKey"]
}

# IAM Replication Role
resource "aws_iam_role" "replication" {
  name               = "tf-iam-role-s3-replication-${substr(random_uuid.id.result, 0, 7)}"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  name = "tf-iam-role-policy-${aws_s3_bucket.primary-bucket.id}-replication"

  policy = templatefile("${path.module}/templates/s3-replication-policy.json", {
    s3_replicate_delete = var.replicate_delete == "1" ? ",\n        \"s3:ReplicateDelete\"" : ""
    region_1            = var.region_one
    region_2            = var.region_two
    pri_bucket          = aws_s3_bucket.primary-bucket.arn
    replica_bucket      = aws_s3_bucket.replica.arn
    acct_id             = data.aws_caller_identity.current.account_id
    replica_key         = aws_kms_key.s3replicakey.id
  })
}

# Policy Attachment
resource "aws_iam_policy_attachment" "replication" {
  name       = "tf-iam-role-attachment-s3-replication-${substr(random_uuid.id.result, 0, 7)}"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}

# Replica Bucket
resource "aws_s3_bucket" "replica" {
  provider = aws.region2
  bucket   = var.replica_bucket_name
  region   = var.region_two
  acl      = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3replicakey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

# Replica Bucket - Public Access Policy
resource "aws_s3_bucket_public_access_block" "replica" {
  bucket   = aws_s3_bucket.replica.id
  provider = aws.region2

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Main Bucket
resource "aws_s3_bucket" "primary-bucket" {
  bucket = var.primary_bucket_name

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id     = "replica"
      prefix = ""
      status = "Enabled"

      destination {
        bucket             = aws_s3_bucket.replica.arn
        storage_class      = var.replica_storage_class
        replica_kms_key_id = aws_kms_key.s3replicakey.arn
      }

      source_selection_criteria {
        sse_kms_encrypted_objects {
          enabled = true
        }
      }
    }
  }
}

# Primary Bucket - Public Access Policy
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

variable "primary_bucket_name" {
  description = "Name of the Primary S3 Bucket"
  type        = string
}

variable "region_one" {
  description = "AWS Region for the Primary S3 Bucket"
  type        = string
}

variable "region_two" {
  description = "AWS Region for the Replication S3 Bucket"
  type        = string
}

variable "replica_bucket_name" {
  description = "Name of the Replica S3 Bucket"
  type        = string
}

variable "replica_storage_class" {
  default     = "GLACIER"
  description = "Storage class of the replica bucket (default: GLACIER)"
  type        = string
}

variable "replicate_delete" {
  default     = ""
  description = "Whether or not to enable replication of Delete commands between buckets. (default: disabled)"
  type        = string
}

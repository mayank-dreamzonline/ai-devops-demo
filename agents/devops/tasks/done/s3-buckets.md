# s3-buckets

**Request:** requirements.md Section 3 — S3 Bucket(s). 1-2 buckets, simple
case, versioning and default encryption as sensible defaults, no public
access.

**Outcome:** Added one S3 bucket in `terraform/s3/s3.tf` (bucket ID
`ai-devops-demo-data-713415772392`, name = prefix + AWS account ID for
global uniqueness), with versioning enabled, default SSE-S3 encryption, and
full public access block. PR
[#1](https://github.com/mayank-dreamzonline/ai-devops-demo/pull/1)
reviewed, merged (squash, `ffab400`). Plan showed 4 to add, 0 change/
destroy both pre- and post-merge. Applied through Checker + Gate. Verified
live via `aws s3api`: versioning `Enabled`, SSE-S3 (`AES256`) applied, all
four public-access-block flags `true`.

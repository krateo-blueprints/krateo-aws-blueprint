---
type: ExampleIndex
title: krateo-aws-blueprint — examples
description: Index of the runnable examples — the reference aws-s3-bucket example and the per-blueprint quickstarts that provision real AWS resources end to end.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, examples, s3, quickstart]
timestamp: 2026-08-11T00:00:00Z
---

# Examples

- [examples/aws-s3-bucket](../examples/aws-s3-bucket/README.md) — the reference example:
  register the `aws-s3-bucket` blueprint and create an `AwsS3Bucket` Composition that
  provisions a real S3 bucket, with the exact `CompositionDefinition` and Composition
  manifests to apply. It points at the full end-to-end
  [quickstart](../blueprints/s3/bucket/quickstart.md) (kind cluster → controller install
  → credentials → verify in AWS → cleanup).

## Per-blueprint quickstarts

Several blueprints ship their own runnable `quickstart.md` beside the chart:

- [`blueprints/s3/bucket/quickstart.md`](../blueprints/s3/bucket/quickstart.md) — the
  reference single-resource run: a real S3 bucket on kind.
- [`blueprints/_stacks/alb/quickstart.md`](../blueprints/_stacks/alb/quickstart.md) — the
  reference composite stack: a real ALB (`LoadBalancer` + `TargetGroup` + `Listener`).

Every blueprint under `blueprints/<service>/<resource>/` also has a `README.md` with its
install snippet and a Composition skeleton. The full catalog is in
[`CATALOG.md`](../CATALOG.md).

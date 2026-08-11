---
type: Example
title: aws-s3-bucket — register a blueprint and create a Composition
description: The reference example — register the aws-s3-bucket blueprint with a CompositionDefinition, then create an AwsS3Bucket Composition that provisions a real S3 bucket through the ACK s3 controller.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [example, aws, s3, ack, compositiondefinition]
timestamp: 2026-08-11T00:00:00Z
---

# aws-s3-bucket

The exact shape every blueprint follows, on the reference `aws-s3-bucket`: a
`CompositionDefinition` registers the chart, then an `AwsS3Bucket` Composition renders a
native `s3.services.k8s.aws/v1alpha1` `Bucket`, and the ACK s3 controller provisions the
real bucket in AWS.

This example is the two apply-able manifests. For a full run on a local kind cluster —
controller install, credentials, verify in the S3 console, cleanup — follow the
reference [quickstart](../../blueprints/s3/bucket/quickstart.md).

## Prerequisites

- The ACK **s3** controller installed and given AWS credentials — see
  [`docs/installing-controllers.md`](../../docs/installing-controllers.md) and
  [`docs/authentication.md`](../../docs/authentication.md).
- Krateo `core-provider` installed.

## 1. Register the blueprint

[`compositiondefinition.yaml`](./compositiondefinition.yaml) publishes the `AwsS3Bucket`
Composition type and pulls the chart from GHCR:

```sh
kubectl create namespace aws-s3-system
kubectl apply -f examples/aws-s3-bucket/compositiondefinition.yaml
```

Wait for it to be registered:

```sh
kubectl get compositiondefinitions.core.krateo.io -n aws-s3-system aws-s3-bucket
```

## 2. Create a Composition

[`composition.yaml`](./composition.yaml) creates one `AwsS3Bucket` — versioning enabled,
one tag, region `eu-west-1`:

```sh
kubectl apply -f examples/aws-s3-bucket/composition.yaml
```

## 3. Check status

```sh
# the Krateo Composition
kubectl get awss3buckets.composition.krateo.io -n aws-s3-system

# the native ACK Bucket it rendered
kubectl get buckets.s3.services.k8s.aws -A
```

The Composition reaches `Ready=True` once the ACK `Bucket` reports
`ACK.ResourceSynced=True` — the real bucket now exists in AWS.

## Notes

- The `region` field is Krateo wiring, not part of the ACK spec: it becomes the
  `services.k8s.aws/region` annotation on the ACK `Bucket`. Leave it empty to inherit the
  controller's default region.
- Every other `spec` field mirrors the ACK `Bucket` spec — see
  [`blueprints/s3/bucket/chart/values.schema.json`](../../blueprints/s3/bucket/chart/values.schema.json)
  for the full field list.

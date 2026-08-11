---
type: Usage
title: krateo-aws-blueprint — usage
description: The prerequisites and the steps to use a blueprint — install the ACK controller, configure AWS auth, register the CompositionDefinition, then create a Composition and check status.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, usage, compositiondefinition, quickstart]
timestamp: 2026-08-11T00:00:00Z
---

# Usage

Using a blueprint is a two-part story: cluster-admin **prerequisites** you set up once
per AWS service, then **registering** the blueprint and **creating** Compositions.

## Prerequisites (cluster-admin, once)

The blueprints render ACK custom resources; they do not install the controllers or
carry credentials. Before using a blueprint for service `<service>`:

1. **Install the ACK service controller** for that service. Each is a Helm OCI chart
   at `oci://public.ecr.aws/aws-controllers-k8s/<service>-chart`. Full instructions in
   [installing-controllers](./installing-controllers.md). For the `aws-s3-bucket`
   blueprint:

   ```sh
   helm install ack-s3-controller \
     oci://public.ecr.aws/aws-controllers-k8s/s3-chart \
     --namespace ack-system --create-namespace \
     --set aws.region=eu-west-1
   ```

2. **Configure AWS authentication** on that controller — IRSA / EKS Pod Identity
   (recommended) or a static shared-credentials Secret. See
   [authentication](./authentication.md).

3. **Krateo `core-provider`** installed in the cluster (it is what publishes and renders
   Compositions).

## Register a blueprint

Each blueprint ships a `compositiondefinition.yaml` (and an optional `customform.yaml`
for the portal card + form). Applying the `CompositionDefinition` publishes the
Composition type and pulls the chart from GHCR. For `aws-s3-bucket`:

```sh
kubectl create namespace aws-s3-system
kubectl apply -f blueprints/s3/bucket/compositiondefinition.yaml   # publishes AwsS3Bucket
kubectl apply -f blueprints/s3/bucket/customform.yaml              # optional: portal card + form
```

This publishes an `AwsS3Bucket` Composition type (`composition.krateo.io/v0-1-1`,
plural `awss3buckets`), pulling the chart from
`oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket`.

> If the GHCR package is private, add pull credentials under `spec.chart.credentials`
> in the `compositiondefinition.yaml` (a commented example is in the file).

## Create a Composition

Create a Composition of the published type. Its `spec` mirrors the ACK custom-resource
`spec` (full field list in the blueprint's `chart/values.schema.json`), plus the
`region` field:

```yaml
apiVersion: composition.krateo.io/v0-1-1
kind: AwsS3Bucket
metadata:
  name: my-bucket
  namespace: aws-s3-system
spec:
  region: eu-west-1
  name: my-unique-bucket-name
  versioning:
    status: Enabled
  tagging:
    tagSet:
      - key: owner
        value: platform
```

Or use the portal card the `customform.yaml` publishes, which renders a form from the
generated CRD schema.

## Check status

```sh
# the Krateo Composition
kubectl get awss3buckets.composition.krateo.io -n aws-s3-system

# the native ACK custom resource it rendered
kubectl get buckets.s3.services.k8s.aws -A
```

The Composition reaches `Ready=True` once the ACK resource reports
`ACK.ResourceSynced=True`, i.e. the real AWS resource exists.

## Composite stacks

Stacks under `blueprints/_stacks/<name>/` are used the same way — apply the
`compositiondefinition.yaml`, then create the Composition — but one Composition renders
several wired ACK resources and its input names mirror the equivalent Terraform module.
See the stack's own `README.md` and `quickstart.md` (for example
`blueprints/_stacks/alb/`).

## End to end

For a full walk-through that provisions a **real S3 bucket on a local kind cluster** —
controller install, credentials, register, create, verify in AWS, clean up — follow the
reference [quickstart](../blueprints/s3/bucket/quickstart.md).

## The full catalog

242 blueprints across 68 AWS services. The service → resource → chart → ACK/Composition
Kind → API group table is in [`CATALOG.md`](../CATALOG.md).

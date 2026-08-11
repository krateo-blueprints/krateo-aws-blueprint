---
type: API
title: krateo-aws-blueprint — API
description: The APIs this repo consumes and publishes — the CompositionDefinition CRD (core.krateo.io/v1alpha1) that registers each blueprint, the Composition API each blueprint publishes, and the native ACK custom resource each renders.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, api, compositiondefinition, crd]
timestamp: 2026-08-11T00:00:00Z
---

# API

Three API layers are in play: the **`CompositionDefinition`** this repo consumes to
register a blueprint, the **Composition** API each blueprint publishes, and the native
**ACK custom resource** the chart renders. This repo defines no CRDs of its own — it
consumes `core.krateo.io` (owned by Krateo `core-provider`) and produces
`*.services.k8s.aws` resources (owned by the ACK controllers).

## `CompositionDefinition` (consumed)

The CRD each blueprint's `compositiondefinition.yaml` is an instance of. It is owned by
Krateo's `core-provider`; this repo only creates instances of it.

- **Group / version:** `core.krateo.io/v1alpha1`
- **Kind:** `CompositionDefinition`

### Spec (the fields this repo sets)

| field | type | required | description |
|---|---|---|---|
| `spec.chart.url` | string | yes | OCI URL of the blueprint chart, e.g. `oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket`. |
| `spec.chart.version` | string | yes | chart version to pull, e.g. `"0.1.1"`. Also drives the published Composition `apiVersion` (`0.1.1` → `v0-1-1`). |
| `spec.chart.credentials.username` | string | no | username for a private GHCR package pull. |
| `spec.chart.credentials.passwordRef.name` | string | no | name of the Secret holding the pull token. |
| `spec.chart.credentials.passwordRef.namespace` | string | no | namespace of that Secret. |
| `spec.chart.credentials.passwordRef.key` | string | no | key within the Secret holding the token. |

### Example

```yaml
apiVersion: core.krateo.io/v1alpha1
kind: CompositionDefinition
metadata:
  name: aws-s3-bucket
  namespace: aws-s3-system
spec:
  chart:
    url: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
    version: "0.1.1"
```

Applying it makes `core-provider` pull the chart and publish the Composition type. Its
`status.conditions[type=Ready]` reflects whether the blueprint is registered — the
portal card reads exactly that condition.

## The Composition API (published)

From the chart's `Chart.yaml`, `core-provider` derives the published Composition API:

- **Kind** — from `name`, dashes dropped and CamelCased: `aws-s3-bucket` → `AwsS3Bucket`
  (plural `awss3buckets`).
- **apiVersion** — from `version`: `0.1.1` → `composition.krateo.io/v0-1-1`.
- **Schema** — from `chart/values.schema.json` only (never `values.yaml`).

So `aws-s3-bucket` publishes `composition.krateo.io/v0-1-1` `AwsS3Bucket`, whose `spec`
is the schema in `blueprints/s3/bucket/chart/values.schema.json`. Creating one:

```yaml
apiVersion: composition.krateo.io/v0-1-1
kind: AwsS3Bucket
metadata:
  name: my-bucket
  namespace: aws-s3-system
spec:
  region: eu-west-1
  name: my-unique-bucket-name
```

The service → resource → chart → **ACK Kind** → **Composition Kind** → API group table
for all 242 blueprints is in [`CATALOG.md`](../CATALOG.md).

## The ACK custom resource (rendered)

The chart template renders a native ACK custom resource that the ACK controller
reconciles. For `aws-s3-bucket`:

- **Group / version / Kind:** `s3.services.k8s.aws/v1alpha1` `Bucket`
- **metadata.name / namespace:** the Composition's release name / namespace.
- **spec:** the Composition `spec` passed through, minus `region` and `global`.
- **annotations:** `services.k8s.aws/region` from the Composition's `region` (present
  only when `region` is non-empty).

Rendered shape (`blueprints/s3/bucket/chart/templates/bucket.yaml`):

```yaml
apiVersion: s3.services.k8s.aws/v1alpha1
kind: Bucket
metadata:
  name: my-bucket
  namespace: aws-s3-system
  annotations:
    services.k8s.aws/region: "eu-west-1"
spec:
  name: my-unique-bucket-name
```

Each ACK resource carries its own `status.conditions` (notably
`ACK.ResourceSynced`), which the ACK controller writes and Krateo surfaces up through
the Composition. The ACK spec/status field reference for a service lives in the upstream
ACK docs and each controller's CRD.

## Composite stacks

A stack blueprint (e.g. `aws-alb-stack`) publishes one Composition type (`AwsAlbStack`)
whose `spec` mirrors the equivalent Terraform module's inputs, and renders **several**
wired ACK resources (a `LoadBalancer` + `TargetGroup`(s) + `Listener`(s) for the ALB
stack) connected through ACK `*Ref` fields. See the stack's `README.md` for its
composed-resource table and input reference.

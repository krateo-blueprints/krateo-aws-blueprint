---
type: Configuration
title: krateo-aws-blueprint — configuration
description: The configuration surface of a blueprint — the Composition spec that mirrors the ACK spec, the values.schema.json contract that drives the CRD and form, the region wiring field, and the CompositionDefinition registration knobs.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, configuration, values-schema, region]
timestamp: 2026-08-11T00:00:00Z
---

# Configuration

There are two configuration surfaces: the **Composition `spec`** (what a user sets when
creating a resource) and the **`CompositionDefinition`** (how an admin registers the
blueprint).

## The Composition spec

A Composition's `spec` **mirrors the ACK custom-resource `spec`** one-to-one, curated to
the fields worth exposing, plus one Krateo-wiring field. The authoritative, per-field
list for each blueprint is its `chart/values.schema.json` (for the reference,
`blueprints/s3/bucket/chart/values.schema.json`).

### `region` — the one wiring field

| field | type | default | effect |
|---|---|---|---|
| `region` | string | `""` | AWS region for this resource (e.g. `eu-west-1`). Rendered as the `services.k8s.aws/region` annotation on the ACK custom resource. Empty inherits the ACK controller's default region (`aws.region`, set when the controller was installed). |

`region` is **not** part of the ACK spec; the template omits it from the rendered
`spec` and emits it as the annotation instead.

### ACK spec fields

Every other field passes straight through to the ACK custom-resource `spec`. For
`aws-s3-bucket` the schema mirrors the `s3.services.k8s.aws/v1alpha1` `Bucket` spec —
`name` (the only required field), `versioning`, `tagging`, `encryption`, `lifecycle`,
`publicAccessBlock`, `cors`, `replication`, and so on. Consult the blueprint's
`chart/values.schema.json` for the exact set and shapes; it is the same schema
`core-provider` uses to generate the CRD and the portal form.

## The `values.schema.json` contract

`core-provider` builds the Composition CRD **only** from each chart's
`values.schema.json` — it never reads `values.yaml`. Consequences:

- **The schema is the API.** Adding, removing, or retyping a field in
  `values.schema.json` changes the generated CRD and the portal form.
- **Defaults must be scalar.** A non-empty object or array `default` in the schema
  breaks Krateo's CRD generation, so blueprint schemas keep defaults to scalars (the
  `region` default is `""`).
- **`values.yaml` is only an example.** It carries a minimal, schema-valid `spec` so
  `helm template` / `helm lint` render without overrides; it is not read by
  `core-provider` and is not the source of truth. Real Compositions supply the full
  spec.

The `lint` workflow renders every chart with `helm template`, which enforces
`values.schema.json` against `values.yaml`, so a schema-invalid example fails CI.

## The `CompositionDefinition` (registration)

Registering a blueprint is configured in its `compositiondefinition.yaml`:

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
    # If the GHCR package is private, provide pull credentials:
    # credentials:
    #   username: krateo
    #   passwordRef:
    #     key: token
    #     name: ghcr-credentials
    #     namespace: aws-s3-system
```

| field | effect |
|---|---|
| `spec.chart.url` | the blueprint chart's OCI URL on GHCR. |
| `spec.chart.version` | the chart version to pull. It also drives the published Composition `apiVersion` (`0.1.1` → `composition.krateo.io/v0-1-1`), so bumping it changes the served API version. |
| `spec.chart.credentials` | optional pull credentials for a private GHCR package (`username` + a `passwordRef` to a Secret key). |
| `metadata.namespace` | the namespace the blueprint is registered and created in. |

## Chart metadata

Each `chart/Chart.yaml` carries catalog metadata used by the portal and CI:

| key | meaning |
|---|---|
| `name` | `aws-<service>-<resource>`. Drives the Composition `Kind` (dashes dropped, CamelCased: `aws-s3-bucket` → `AwsS3Bucket`). |
| `version` | the placeholder `CHART_VERSION`, stamped by CI at tag time. Drives the Composition `apiVersion`. |
| `appVersion` | the ACK CRD version the blueprint targets (e.g. `v1alpha1`), or the Terraform module version for a stack. |
| `annotations.krateo.io/category` | catalog category (e.g. `storage`, `network`). |
| `annotations.krateo.io/maturity` | maturity tag (e.g. `beta`). |
| `annotations.krateoSupportedVersion` | the minimum Krateo version. |

## The portal card and form

`customform.yaml` (optional) publishes a portal card (a `Widget`) and a `CustomForm`
that renders the create form from the generated CRD's `openAPIV3Schema`. The card shows
the blueprint's `Ready` status and offers create / delete actions.

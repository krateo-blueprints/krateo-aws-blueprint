---
type: ChartRepo
title: krateo-aws-blueprint — index
description: The map of the krateo-aws-blueprint doc bundle — a catalog of Krateo blueprints that expose AWS resources as self-service Compositions on top of the AWS Controllers for Kubernetes (ACK).
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, blueprint, compositiondefinition, chart-repo]
timestamp: 2026-08-11T00:00:00Z
---

# krateo-aws-blueprint

This repository is a **catalog of Krateo blueprints** that turn AWS resources into
self-service Krateo Compositions. Each blueprint is a Helm chart whose templates render
a **native ACK custom resource** (for example `s3.services.k8s.aws/v1alpha1` `Bucket`);
the [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/)
service controller reconciles that resource into the real AWS resource and reports status
back. A sibling `CompositionDefinition` (`core.krateo.io/v1alpha1`) registers each chart
with Krateo so it can be created from the portal.

There are two kinds of blueprint:

- **Single-resource blueprints** under `blueprints/<service>/<resource>/` — one ACK
  `Kind` each (242 charts across 68 AWS services). The Composition `spec` mirrors the
  ACK custom-resource `spec`, curated to the fields worth exposing.
- **Composite stacks** under `blueprints/_stacks/<name>/` — one Composition that wires
  several ACK resources together (for example the `aws-alb-stack` renders a
  `LoadBalancer` + `TargetGroup`(s) + `Listener`(s)), with an input interface that
  mirrors the equivalent Terraform module.

Every chart is published to GHCR as an OCI Helm artifact:
`oci://ghcr.io/krateo-blueprints/charts/aws-<service>-<resource>:<version>`.

## The bundle (start here)

- [overview](./overview.md) — how a blueprint works end to end, the ACK
  reconciliation model, why there is no KOG / oasgen here, and the repository layout.
- [usage](./usage.md) — the prerequisites (install the ACK controller, configure AWS
  auth), then register a blueprint and create a Composition.
- [configuration](./configuration.md) — the Composition `spec`, the `values.schema.json`
  contract, the `region` wiring field, and per-blueprint conventions.
- [api](./api.md) — the `CompositionDefinition` CRD this repo consumes and the
  Composition API each blueprint publishes.
- [examples](./examples.md) — the runnable example plus the per-blueprint quickstarts.
- [release](./release.md) — how a semver tag packages and pushes every chart to GHCR.
- [log](./log.md) — curated history.
- [llms.txt](./llms.txt) — the doc index for LLM tooling.

## Prerequisites (cluster-admin, once)

- [installing-controllers](./installing-controllers.md) — install the ACK service
  controller for the AWS service you want.
- [authentication](./authentication.md) — give that controller AWS credentials
  (IRSA / EKS Pod Identity, or a static Secret).

## Layout

```
blueprints/<service>/<resource>/     one blueprint per ACK resource Kind
  chart/
    Chart.yaml                       name: aws-<service>-<resource>
    values.yaml                      minimal schema-valid example spec
    values.schema.json               curated projection of the ACK CRD spec — drives the CRD + form
    templates/<kind>.yaml            renders the ACK custom resource
  compositiondefinition.yaml         registers the blueprint with Krateo
  customform.yaml                    portal card + form
  README.md
blueprints/_stacks/<name>/           composite blueprints (several wired ACK resources)
tools/ackgen/                        Go generator that emits blueprints from ACK CRD schemas
docs/                                this bundle + the auth / controller-install prerequisites
CATALOG.md                           the full service → resource → chart → Kind table
```

The reference blueprint is `aws-s3-bucket` — the generator was built and validated
against it, and its [quickstart](../blueprints/s3/bucket/quickstart.md) provisions a
real S3 bucket end to end.

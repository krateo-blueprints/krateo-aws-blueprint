---
type: Architecture
title: krateo-aws-blueprint — overview
description: How an AWS blueprint works end to end — chart renders a native ACK custom resource, the ACK controller provisions the real AWS resource, and the values.schema.json is the contract that drives the Composition CRD and portal form.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, architecture, compositiondefinition, blueprint]
timestamp: 2026-08-11T00:00:00Z
---

# Overview

Each blueprint in this repository is a Helm chart that exposes an AWS resource as a
self-service Krateo Composition, backed by the
[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/).
The chart renders a **native ACK custom resource**; the ACK service controller
reconciles it into the real AWS resource. Krateo never talks to the AWS API — it only
creates and manages Kubernetes objects.

## The chain

```
CompositionDefinition (core.krateo.io)         registers the blueprint, pulls the chart
        │
        ▼  publishes a Composition type, e.g. composition.krateo.io/v0-1-1 AwsS3Bucket
User creates a Composition  ── Krateo renders the chart ──▶  ACK custom resource
                                                                    │
                                                              ACK controller
                                                                    │
                                                                    ▼
                                                              real AWS resource
```

1. A `CompositionDefinition` names the chart's OCI URL and version. Applying it makes
   Krateo's `core-provider` pull the chart and publish a Composition type — its `Kind`
   and `apiVersion` derived from `Chart.yaml` (see [api](./api.md)).
2. You create a Composition of that type. The composition-dynamic-controller renders
   the chart with your `spec` as the Helm values.
3. The chart template emits a native ACK custom resource (for the `aws-s3-bucket`
   blueprint, an `s3.services.k8s.aws/v1alpha1` `Bucket`).
4. The ACK controller for that service reconciles the custom resource — calling the AWS
   API — and writes status back onto it, which surfaces up through the Composition.

## The template is a thin pass-through

The chart template renders the ACK custom resource by passing the Composition `spec`
through verbatim (`blueprints/s3/bucket/chart/templates/bucket.yaml`):

- The Composition `spec` **mirrors the ACK custom-resource `spec`** one-to-one (curated
  to the fields worth exposing), so the values map straight onto the ACK `spec`.
- `region` is the one Krateo-wiring field that is **not** part of the ACK spec — it is
  omitted from the spec and rendered as the standard `services.k8s.aws/region`
  annotation instead. Empty inherits the controller's default region.
- `global` (injected by Krateo/Helm) is omitted so it never leaks into the ACK spec.

## The schema is the contract

Krateo's `core-provider` builds the Composition CRD **only** from each chart's
`values.schema.json` — it never reads `values.yaml`. So `values.schema.json` is the
contract that drives both the generated CRD and the portal form; `values.yaml` only
carries a minimal, schema-valid example so `helm template` / `helm lint` render without
overrides. Defaults in the schema must be scalar — a non-empty object or array default
breaks CRD generation.

## Composite stacks

Most blueprints render exactly one ACK resource. The blueprints under
`blueprints/_stacks/<name>/` are **composite**: one Composition renders several ACK
resources wired together through ACK `*Ref` fields. For example `aws-alb-stack` renders
a `LoadBalancer`, one `TargetGroup` per `target_groups` entry, and one `Listener` per
`listeners` entry, and their `*Ref` wiring makes them come up in strict dependency
order. A stack's input names mirror the equivalent Terraform module (a curated core
subset of its inputs) rather than the raw ACK spec.

## No KOG / oasgen here

ACK controllers already **are** Kubernetes controllers that ship their own CRDs and
reconcilers, so Krateo consumes them **directly** via `CompositionDefinition`s. The
Krateo Operator Generator (RestDefinition / oasgen) pattern — for wrapping raw REST APIs
that have no controller — is intentionally not used in this repo.

## What the blueprints do not do

These blueprints provision AWS resources; they do **not** install the ACK controllers
and do **not** configure AWS credentials. Both are cluster-admin prerequisites, set up
once (see [usage](./usage.md), [installing-controllers](./installing-controllers.md),
and [authentication](./authentication.md)).

## Repository layout

```
blueprints/<service>/<resource>/     one blueprint per ACK resource Kind
  chart/                             the Helm chart (Chart.yaml, values.yaml, values.schema.json, templates/)
  compositiondefinition.yaml         registers the blueprint with Krateo
  customform.yaml                    portal card + form
  README.md, quickstart.md
blueprints/_stacks/<name>/           composite blueprints (several wired ACK resources)
tools/ackgen/                        Go generator that emits blueprints from ACK CRD schemas
docs/                                this bundle + the auth / controller-install prerequisites
CATALOG.md                           the full service → resource → chart → Kind table
```

Every single-resource blueprint under `blueprints/<service>/<resource>/` is generated by
`tools/ackgen` from the upstream ACK CRD and validated with `helm template` (which
enforces `values.schema.json`). The full catalog — 242 blueprints across 68 AWS
services — is in [`CATALOG.md`](../CATALOG.md).

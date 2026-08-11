---
type: Runbook
title: krateo-aws-blueprint — release
description: How a release ships — one semver tag packages every blueprint chart under blueprints/**/chart and pushes each to GHCR as an OCI Helm artifact, plus the PR-time lint gate and the version-bump step.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, release, oci, ghcr]
timestamp: 2026-08-11T00:00:00Z
---

# Release

One plain-semver tag (`X.Y.Z`, **no** `v` prefix) releases the whole catalog. Pushing the
tag triggers `.github/workflows/release-tag.yaml`, which packages **every** chart under
`blueprints/*/*/chart` and pushes each to GHCR.

## What a tag ships

For each chart named `aws-<service>-<resource>`, pushing tag `X.Y.Z` publishes:

```
oci://ghcr.io/krateo-blueprints/charts/aws-<service>-<resource>:X.Y.Z
```

The workflow:

1. Resolves `VERSION` from the tag and `OCI_REPO` from the repository owner
   (`oci://ghcr.io/<owner>/charts`), so it always writes its own namespace —
   `GITHUB_TOKEN` can only push there.
2. Logs in to GHCR with `GITHUB_TOKEN`.
3. For each `blueprints/*/*/chart`: stamps the `CHART_VERSION` placeholder in
   `Chart.yaml` with the tag, `helm package`s the chart, and `helm push`es the `.tgz` to
   `OCI_REPO`.

The `CHART_VERSION` placeholder in each `Chart.yaml` drives both the chart version and,
downstream, the published Composition `apiVersion` (`0.1.0` → `composition.krateo.io/v0-1-0`).

## Steps

```console
$ git tag X.Y.Z && git push origin X.Y.Z
```

Then verify the workflow went green and an artifact exists, e.g. for the reference chart:

```console
$ helm show chart oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket --version X.Y.Z | head -3
```

After the charts are published, bump the `spec.chart.version` in the affected
`compositiondefinition.yaml` files (and the example under `examples/`) to the released
version so they point at a chart that exists.

## PR-time checks

Two workflows gate pull requests:

- **`lint.yaml`** — for every `blueprints/*/*/chart`, stamps a temporary version, then
  `helm template` (the authoritative gate: it renders the manifest **and** enforces
  `values.schema.json` against `values.yaml`) and an informational `helm lint`. It also
  runs the shared documentation-standard check (`lint-docs`).
- **`security.yml`** — the shared Krateo security scan.

## Regenerating a blueprint

Single-resource blueprints are generated from the upstream ACK CRD by `tools/ackgen`:

```sh
go run ./tools/ackgen \
  -crd https://raw.githubusercontent.com/aws-controllers-k8s/s3-controller/main/config/crd/bases/s3.services.k8s.aws_buckets.yaml \
  -out blueprints -lint
```

Regenerating rewrites the chart, `values.schema.json`, `compositiondefinition.yaml`, and
`customform.yaml` for that resource; commit the change and release it on the next tag.

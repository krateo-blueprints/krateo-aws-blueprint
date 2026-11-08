---
type: Runbook
title: krateo-aws-blueprint — release
description: How a release ships — one semver tag packages every blueprint chart under blueprints/**/chart, checks each archive against the organisation's publishing standard, pushes each to GHCR, attaches the stamped CompositionDefinitions to the tag's release, and publishes the charts to the Marketplace index; plus the PR-time gates.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, release, oci, ghcr]
timestamp: 2026-11-07T00:00:00Z
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

The workflow follows the organisation's publishing standard,
[krateo-blueprints/charts `PUBLISHING.md`](https://github.com/krateo-blueprints/charts/blob/main/PUBLISHING.md).
Nothing is pushed until every check before the push has passed:

1. Refuses a commit with no successful `lint.yaml` run, and refuses if the org secret
   `CHARTS_PUBLISH_TOKEN` is empty.
2. Runs `.github/scripts/publishing-gate.py tree .` over the committed charts.
3. Stamps the `CHART_VERSION` placeholder with the tag in every `compositiondefinition.yaml` and
   `Chart.yaml`, copies each blueprint's stamped `compositiondefinition.yaml` into its chart, and
   `helm package`s every chart.
4. Runs `publishing-gate.py archives` over the packaged `.tgz`: each must carry its
   CompositionDefinition, at the tag's version, with the canonical `spec.chart.url`.
5. Pushes each `.tgz` to `oci://ghcr.io/<owner>/charts` with `GITHUB_TOKEN`.
6. Attaches each stamped CompositionDefinition to the tag's GitHub release as
   `compositiondefinition-<chart>.yaml`, which is what the blueprint READMEs apply.
7. Hands the same `.tgz` to `krateo-blueprints/charts`' `publish-chart.yaml`, which publishes them
   to the Marketplace index and succeeds only when the Marketplace can install them.

The `CHART_VERSION` placeholder drives the chart version, the CompositionDefinition's
`spec.chart.version` and, downstream, the published Composition `apiVersion`
(`0.1.0` → `composition.krateo.io/v0-1-0`). Never commit a literal version there: the release
would pass it through unchanged, and `publishing-gate.py` refuses it on every pull request.

## Steps

```console
$ git tag X.Y.Z && git push origin X.Y.Z
```

Then verify the workflow went green and an artifact exists, e.g. for the reference chart:

```console
$ helm show chart oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket --version X.Y.Z | head -3
```

Nothing is bumped by hand afterwards: register a blueprint with the stamped asset on the
release, `https://github.com/krateo-blueprints/krateo-aws-blueprint/releases/download/X.Y.Z/compositiondefinition-<chart>.yaml`.

## PR-time checks

Two workflows gate pull requests:

- **`lint.yaml`** — for every `blueprints/*/*/chart`, stamps a temporary version, then
  `helm template` (the authoritative gate: it renders the manifest **and** enforces
  `values.schema.json` against `values.yaml`) and an informational `helm lint`. It also
  runs the shared documentation-standard check (`lint-docs`) and `publishing-gate.py tree .`
  (`publishing-standard`), and it runs on every push to `main` as well, because a release
  refuses a commit with no successful lint run.
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

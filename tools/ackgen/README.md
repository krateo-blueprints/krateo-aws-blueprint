# ackgen

A Go generator that emits Krateo AWS blueprints from ACK CRD schemas. It is how this repo
scales from the hand-built S3 pilot to broad ACK coverage.

## What it does

Given an ACK `CustomResourceDefinition` (local file or URL), for the served version it:

1. Extracts `openAPIV3Schema.properties.spec`.
2. Projects it into a crdgen-safe `values.schema.json` — keeping types, `required`,
   descriptions, enums, formats and bounds, while **dropping** `oneOf`/`anyOf`/`allOf`/`not`
   and every `x-kubernetes-*` extension (Krateo's crdgen can't express them). A
   `region` field is injected for ACK region selection.
3. Derives the chart name and Composition Kind/plural **exactly as core-provider does**
   (`flect.Pascalize(toGolangName(chartName))` and `flect.Pluralize(strings.ToLower(kind))`).
4. Renders a full blueprint directory from the embedded golden skeleton:
   `<out>/<service>/<resource>/{chart/,compositiondefinition.yaml,customform.yaml,README.md}`.
5. Seeds `values.yaml` with a minimal schema-valid instance so `helm lint`/`helm template`
   pass without overrides.

The generated Composition `spec` **mirrors the full ACK spec** (the chart template is a
passthrough), so blueprints are complete by default; the hand-built `blueprints/s3/bucket`
remains the curated reference the generator was validated against.

## Build

Pure Go; dependencies are `github.com/gobuffalo/flect` and `sigs.k8s.io/yaml`.

```sh
cd tools/ackgen
go build -o ackgen .
```

## Usage

```sh
# From a URL (ACK controller repos publish CRDs under config/crd/bases/)
./ackgen \
  -crd https://raw.githubusercontent.com/aws-controllers-k8s/s3-controller/main/config/crd/bases/s3.services.k8s.aws_buckets.yaml \
  -out ../../blueprints \
  -lint

# From a local file, pinning the CRD version
./ackgen -crd ./s3.services.k8s.aws_buckets.yaml -version v1alpha1 -out ../../blueprints
```

### Operator wrappers

A second, separate mode generates the `operator/` wrappers over the upstream ACK service-controller
charts — one per service, so every blueprint in this repo has an installable controller:

```sh
./ackgen -operators ack-controllers.yaml -out ../../operator
```

`-operators` and `-crd` are different modes, not modifiers: the input is the committed pin list
rather than a CRD, and the default output root becomes `operator`. The generator never resolves
"latest" from the registry — see the header of `ack-controllers.yaml` for why.

Each wrapper is metadata only (`Chart.yaml`, `values.yaml`, `values.schema.json`, `README.md`) with
no `templates/`: a single dependency on `oci://public.ecr.aws/aws-controllers-k8s/<service>-chart`,
aliased to `ack` so the values path is identical across the catalogue. The upstream chart ships its
service CRDs in its own `crds/`, so there is no companion `-crds` chart.

`-lint` in this mode runs `helm dependency update` + `helm template` per wrapper, which is the only
check that proves a pinned version actually exists upstream. It needs the network, and 67 serial
pulls are slow — CI does it in its own job.

### Flags

| Flag             | Default       | Description                                                        |
| ---------------- | ------------- | ------------------------------------------------------------------ |
| `-crd`           | _(required)_  | Path or URL to an ACK CustomResourceDefinition.                    |
| `-version`       | storage/served| CRD version to target.                                             |
| `-out`           | `blueprints`  | Output root; blueprint lands at `<out>/<service>/<resource>`.      |
| `-chart-version` | `0.1.0`       | Version stamped into CompositionDefinition and customform.         |
| `-operators`     | _(unset)_     | Path to the controller pin list; switches to operator-wrapper mode. |
| `-lint`          | `false`       | Run `helm lint` + `helm template` on the generated chart.          |

## Validated against

`s3.services.k8s.aws/Bucket` (reproduces the pilot), plus `dynamodb/Table`, `rds/DBInstance`,
`iam/Role`, and `ecr/Repository` — all generate and lint cleanly.

## Limitations

- The full ACK spec is mirrored as-is; especially large resources (e.g. RDS DBInstance) produce
  large forms. Hand-curation can follow generation where a smaller form is desired.
- `helm template` validates `values.yaml` against the schema; the minimal-valid seed uses
  `"example"` for required strings, which satisfies typical ACK name patterns but is not
  guaranteed for unusual `pattern` constraints — run with `-lint` to catch these.

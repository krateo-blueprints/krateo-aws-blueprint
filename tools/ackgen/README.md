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

### Flags

| Flag             | Default       | Description                                                        |
| ---------------- | ------------- | ------------------------------------------------------------------ |
| `-crd`           | _(required)_  | Path or URL to an ACK CustomResourceDefinition.                    |
| `-version`       | storage/served| CRD version to target.                                             |
| `-out`           | `blueprints`  | Output root; blueprint lands at `<out>/<service>/<resource>`.      |
| `-chart-version` | `0.1.0`       | Version stamped into CompositionDefinition and customform.         |
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

# ackgen

A Go generator (Phase 2) that emits Krateo AWS blueprints from ACK CRD schemas.

## What it will do

Given an ACK service controller (or its CRD YAML), for each resource Kind it will:

1. Fetch the CRD's `openAPIV3Schema` for the served version.
2. Project the CRD `spec` into a curated `values.schema.json` (drop status/read-only fields,
   surface `required`, carry titles/descriptions, strip constructs `crdgen` can't express such
   as `oneOf`/type-unions), and add the Krateo-wiring `region` field.
3. Render a blueprint directory from the golden skeleton:
   `blueprints/<service>/<resource>/{chart/,compositiondefinition.yaml,customform.yaml,README.md}`.

The hand-built `blueprints/s3/bucket` blueprint is the canonical reference the generator
reproduces — generator output for S3 should diff-match the pilot.

## Status

Not implemented yet. Phase 1 (the S3 pilot) establishes the golden template first.

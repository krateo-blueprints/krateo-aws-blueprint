#!/usr/bin/env python3
"""The organisation's publishing standard, checked here before krateo-blueprints/charts checks it.

krateo-blueprints/charts PUBLISHING.md is the standard, and its publish-chart.yaml refuses a chart
that breaks it. That refusal comes AFTER this repository's release has pushed to GHCR, so a chart
it refuses is left in GHCR and missing from the Marketplace index. This script applies the same
rules earlier, in two modes:

  tree      the committed checkout, on every pull request (lint.yaml) and before a release
            packages anything (release-tag.yaml):
              - every chart is at blueprints/<service>/<resource>/chart (blueprints channel) or
                operator/<name> (operators channel), the only places the release publishes from;
              - every Chart.yaml version is the CHART_VERSION placeholder (rule 4);
              - every blueprint has values.schema.json, an https icon, non-empty keywords, and
                ONE committed CompositionDefinition, beside the chart, whose spec.chart.url is
                oci://ghcr.io/krateo-blueprints/charts/<name> and whose spec.chart.version is the
                CHART_VERSION placeholder (rules 3 and 4). A literal there is how the published
                gcp-storage-bucket 0.1.5 and azure-storage-account 0.1.3 shipped a
                CompositionDefinition that installs 0.1.0: the release stamps the placeholder,
                and a file without one went out unchanged;
              - no operator chart is a blueprint (rule 2).

  archives  the packaged .tgz files of one channel, after `helm package` and before any push.
            The same content gate publish-chart.yaml applies, plus: every archive is at the
            version being released. `helm package` exits 0 whether or not the
            CompositionDefinition was copied into the chart, so only the archive can say.

Usage:
  publishing-gate.py tree <repo-root>
  publishing-gate.py archives <blueprints|operators> <dir-of-tgz> <version>

Exits 1 on any violation, and also when it finds nothing to check: a gate with no input passes
nothing.
"""
import glob
import os
import sys
import tarfile

import yaml

PLACEHOLDER = "CHART_VERSION"
URL_PREFIX = "oci://ghcr.io/krateo-blueprints/charts/"

errors = []


def error(msg):
    errors.append(msg)
    print(f"::error::{msg}")


def composition_definitions(text):
    return [d for d in yaml.safe_load_all(text) if isinstance(d, dict) and d.get("kind") == "CompositionDefinition"]


def check_listing_metadata(where, chart):
    icon = chart.get("icon") or ""
    if not isinstance(icon, str) or not icon.startswith("https://"):
        error(f"{where}: icon must be an absolute https URL, got {icon!r}")
    keywords = chart.get("keywords")
    if not isinstance(keywords, list) or not keywords or not all(isinstance(k, str) and k for k in keywords):
        error(f"{where}: Chart.yaml needs a non-empty keywords list, the Marketplace's tags")


def check_cd(where, cds, name, want_version):
    if len(cds) != 1:
        error(f"{where}: expected exactly one CompositionDefinition, found {len(cds)}")
        return
    chart_ref = (cds[0].get("spec") or {}).get("chart") or {}
    url = chart_ref.get("url")
    version = chart_ref.get("version")
    if url != URL_PREFIX + name:
        error(f"{where}: CompositionDefinition installs {url!r}, not {URL_PREFIX + name}")
    if str(version) != want_version:
        error(f"{where}: CompositionDefinition spec.chart.version is {version!r}, must be {want_version!r}")


def tree(root):
    os.chdir(root)
    charts = sorted(
        os.path.dirname(p)
        for p in glob.glob("**/Chart.yaml", recursive=True)
        if "/charts/" not in "/" + p
    )
    counts = {"blueprints": 0, "operators": 0}
    for d in charts:
        parts = d.split("/")
        if len(parts) == 4 and parts[0] == "blueprints" and parts[3] == "chart":
            channel = "blueprints"
        elif len(parts) == 2 and parts[0] == "operator":
            channel = "operators"
        else:
            error(f"{d}: a chart outside blueprints/<service>/<resource>/chart and operator/<name> is never published")
            continue
        counts[channel] += 1
        with open(os.path.join(d, "Chart.yaml")) as f:
            chart = yaml.safe_load(f) or {}
        name = chart.get("name")
        if str(chart.get("version")) != PLACEHOLDER:
            error(f"{d}/Chart.yaml: version is {chart.get('version')!r}; commit the {PLACEHOLDER} placeholder, the release stamps it from the tag")
        has_schema = os.path.isfile(os.path.join(d, "values.schema.json"))
        inner_cd = os.path.join(d, "compositiondefinition.yaml")
        if channel == "operators":
            if has_schema and os.path.isfile(inner_cd):
                error(f"{d}: has values.schema.json and a CompositionDefinition, so it is a blueprint; it cannot go to operators")
            continue
        if not has_schema:
            error(f"{d}: no values.schema.json; a blueprint needs one")
        if os.path.exists(inner_cd):
            error(f"{inner_cd}: do not commit a copy inside the chart; the release copies the stamped {os.path.dirname(d)}/compositiondefinition.yaml there")
        outer_cd = os.path.join(os.path.dirname(d), "compositiondefinition.yaml")
        if not os.path.isfile(outer_cd):
            error(f"{outer_cd}: missing; a blueprint needs its CompositionDefinition")
        else:
            with open(outer_cd) as f:
                check_cd(outer_cd, composition_definitions(f.read()), name, PLACEHOLDER)
        check_listing_metadata(d, chart)
    print(f"checked {counts['blueprints']} blueprint chart(s) and {counts['operators']} operator chart(s), {len(errors)} violation(s)")
    if counts["blueprints"] == 0:
        error("no blueprint charts found under blueprints/*/*/chart; refusing to report a pass over nothing")


def archives(channel, directory, version):
    if channel not in ("blueprints", "operators"):
        error(f"channel must be blueprints or operators, got {channel!r}")
        return
    tgzs = sorted(glob.glob(os.path.join(directory, "*.tgz")))
    for tgz in tgzs:
        base = os.path.basename(tgz)
        with tarfile.open(tgz, "r:gz") as tar:
            members = set(tar.getnames())
            # The chart's own Chart.yaml is the one at depth 1; vendored charts/<dep>/ have their own.
            top = [m for m in members if m.count("/") == 1 and m.endswith("/Chart.yaml")]
            if len(top) != 1:
                error(f"{base}: expected one top-level Chart.yaml, found {len(top)}")
                continue
            chart = yaml.safe_load(tar.extractfile(top[0]).read()) or {}
            name = chart.get("name")
            chart_version = str(chart.get("version"))
            if base != f"{name}-{chart_version}.tgz":
                error(f"{base}: Chart.yaml says {name} {chart_version}")
                continue
            if chart_version != version:
                error(f"{base}: packaged at {chart_version}, but this release is {version}")
            has_schema = f"{name}/values.schema.json" in members
            cd_member = f"{name}/compositiondefinition.yaml"
            has_cd = cd_member in members
            if channel == "operators":
                if has_schema and has_cd:
                    error(f"{base}: is a blueprint (schema and CompositionDefinition); publish it to blueprints")
                continue
            if not has_schema:
                error(f"{base}: no {name}/values.schema.json")
            if not has_cd:
                error(f"{base}: no {cd_member}; copy the stamped CompositionDefinition into the chart before helm package")
            else:
                check_cd(f"{base}:{cd_member}", composition_definitions(tar.extractfile(cd_member).read()), name, version)
            check_listing_metadata(base, chart)
    print(f"checked {len(tgzs)} {channel} archive(s) at {version}, {len(errors)} violation(s)")
    if not tgzs:
        error(f"no .tgz in {directory}; refusing to report a pass over nothing")


def main(argv):
    if len(argv) == 3 and argv[1] == "tree":
        tree(argv[2])
    elif len(argv) == 5 and argv[1] == "archives":
        archives(argv[2], argv[3], argv[4])
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

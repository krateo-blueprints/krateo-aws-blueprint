package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"sigs.k8s.io/yaml"
)

// The operator/ wrappers are generated, so the only way a drift between the pin list and the
// committed charts can be caught is a test that regenerates and compares. Without this, a
// hand-edited Chart.yaml (a version bumped in place, an alias changed, a dependency repointed)
// renders fine, lints fine, publishes fine — and the next regeneration silently reverts it.
//
// Everything here is offline: no registry is contacted. Whether a pinned version actually EXISTS
// upstream is proven by the lint job's `helm dependency update`, which is the only check that can
// prove it.
//
// RUN THESE WITH -count=1. Every test in this file reads files OUTSIDE its own package
// (../../operator), which `go test`'s cache key does not cover: change a committed wrapper, re-run,
// and Go replays the previous PASS without executing anything. Verified while building this — four
// deliberate breaks all reported "ok (cached)". A fresh CI runner has no cache so the workflow is
// safe either way, but it passes -count=1 explicitly rather than relying on that.

const pinFile = "ack-controllers.yaml"

// operatorRoot is the committed wrapper directory, relative to this package.
const operatorRoot = "../../operator"

type chartYAML struct {
	Name         string `json:"name"`
	Version      string `json:"version"`
	AppVersion   string `json:"appVersion"`
	Dependencies []struct {
		Name       string `json:"name"`
		Alias      string `json:"alias"`
		Version    string `json:"version"`
		Repository string `json:"repository"`
	} `json:"dependencies"`
}

func loadPins(t *testing.T) *operatorList {
	t.Helper()
	l, err := loadOperatorList(pinFile)
	if err != nil {
		t.Fatalf("loading %s: %v", pinFile, err)
	}
	return l
}

// TestPinListIsWellFormed covers the validation loadOperatorList performs, so a malformed pin file
// fails here with a clear message rather than halfway through a generation run.
func TestPinListIsWellFormed(t *testing.T) {
	l := loadPins(t)
	if len(l.Controllers) == 0 {
		t.Fatal("pin list is empty")
	}
	for _, c := range l.Controllers {
		if c.Service != strings.ToLower(c.Service) {
			t.Errorf("service %q is not lowercase; it becomes part of a chart name and an OCI path", c.Service)
		}
		if strings.ContainsAny(c.Version, "v ") {
			t.Errorf("service %s: version %q should be a bare semver with no leading v", c.Service, c.Version)
		}
	}
}

// TestEveryPinnedServiceHasAWrapper and its converse pin the 1:1 relationship. A pin with no
// wrapper means someone added a controller and forgot to regenerate; a wrapper with no pin means a
// controller was dropped from the list but its chart still publishes, so it would keep shipping at
// a version nothing records.
func TestEveryPinnedServiceHasAWrapper(t *testing.T) {
	l := loadPins(t)
	for _, c := range l.Controllers {
		dir := filepath.Join(operatorRoot, operatorChartName(c.Service))
		if _, err := os.Stat(filepath.Join(dir, "Chart.yaml")); err != nil {
			t.Errorf("service %s is pinned but %s has no Chart.yaml — regenerate", c.Service, dir)
		}
	}
}

func TestEveryWrapperHasAPin(t *testing.T) {
	l := loadPins(t)
	pinned := map[string]bool{}
	for _, c := range l.Controllers {
		pinned[operatorChartName(c.Service)] = true
	}
	entries, err := os.ReadDir(operatorRoot)
	if err != nil {
		t.Fatalf("reading %s: %v", operatorRoot, err)
	}
	n := 0
	for _, e := range entries {
		if !e.IsDir() || !strings.HasPrefix(e.Name(), "krateo-aws-ack-") {
			continue
		}
		n++
		if !pinned[e.Name()] {
			t.Errorf("%s has no entry in %s — either add the pin or delete the wrapper", e.Name(), pinFile)
		}
	}
	if n == 0 {
		t.Fatalf("found no wrappers under %s; the glob or the path is wrong, and an empty check passes vacuously", operatorRoot)
	}
	if n != len(l.Controllers) {
		t.Errorf("wrapper count %d != pin count %d", n, len(l.Controllers))
	}
}

// TestCommittedChartsMatchPins is the hand-edit guard: it reads each committed Chart.yaml and
// asserts every field the generator derives from the pin list.
func TestCommittedChartsMatchPins(t *testing.T) {
	l := loadPins(t)
	for _, c := range l.Controllers {
		name := operatorChartName(c.Service)
		path := filepath.Join(operatorRoot, name, "Chart.yaml")
		raw, err := os.ReadFile(path)
		if err != nil {
			t.Errorf("%s: %v", path, err)
			continue
		}
		var ch chartYAML
		if err := yaml.Unmarshal(raw, &ch); err != nil {
			t.Errorf("%s: %v", path, err)
			continue
		}
		if ch.Name != name {
			t.Errorf("%s: name is %q, want %q", path, ch.Name, name)
		}
		// The release workflow substitutes CHART_VERSION from the git tag. A concrete version here
		// means someone pinned the wrapper's own version by hand, and the release would ship it
		// under the wrong tag.
		if ch.Version != "CHART_VERSION" {
			t.Errorf("%s: version is %q, want the literal CHART_VERSION placeholder", path, ch.Version)
		}
		if ch.AppVersion != c.Version {
			t.Errorf("%s: appVersion is %q, want the pinned %q", path, ch.AppVersion, c.Version)
		}
		if len(ch.Dependencies) != 1 {
			t.Errorf("%s: %d dependencies, want exactly 1", path, len(ch.Dependencies))
			continue
		}
		d := ch.Dependencies[0]
		if want := c.Service + "-chart"; d.Name != want {
			t.Errorf("%s: dependency name is %q, want %q (helm resolves the UPSTREAM chart name under the OCI repo)", path, d.Name, want)
		}
		if d.Alias != depAlias {
			t.Errorf("%s: dependency alias is %q, want %q — the alias is what keeps the values key uniform across wrappers", path, d.Alias, depAlias)
		}
		if d.Version != c.Version {
			t.Errorf("%s: dependency version is %q, want the pinned %q", path, d.Version, c.Version)
		}
		if d.Repository != ackChartRepo {
			t.Errorf("%s: dependency repository is %q, want %q", path, d.Repository, ackChartRepo)
		}
	}
}

// TestWrapperShapeIsUniform asserts the property that makes one schema cover the catalogue: every
// wrapper forwards under the same top-level key, and none of them smuggles in templates of its own
// (a wrapper that renders its own resources is no longer a pure dependency wrapper, and whatever it
// renders would be invisible to the upstream chart's schema).
func TestWrapperShapeIsUniform(t *testing.T) {
	l := loadPins(t)
	for _, c := range l.Controllers {
		dir := filepath.Join(operatorRoot, operatorChartName(c.Service))

		if _, err := os.Stat(filepath.Join(dir, "templates")); err == nil {
			t.Errorf("%s has a templates/ directory; wrappers are metadata only", dir)
		}

		var vals map[string]interface{}
		raw, err := os.ReadFile(filepath.Join(dir, "values.yaml"))
		if err != nil {
			t.Errorf("%s: %v", dir, err)
			continue
		}
		if err := yaml.Unmarshal(raw, &vals); err != nil {
			t.Errorf("%s/values.yaml: %v", dir, err)
			continue
		}
		if len(vals) != 1 {
			t.Errorf("%s/values.yaml has %d top-level keys, want exactly %q", dir, len(vals), depAlias)
		}
		if _, ok := vals[depAlias]; !ok {
			t.Errorf("%s/values.yaml has no %q key; the dependency alias and the values key must agree or nothing is forwarded", dir, depAlias)
		}

		schemaRaw, err := os.ReadFile(filepath.Join(dir, "values.schema.json"))
		if err != nil {
			t.Errorf("%s: %v", dir, err)
			continue
		}
		var schema map[string]interface{}
		if err := json.Unmarshal(schemaRaw, &schema); err != nil {
			t.Errorf("%s/values.schema.json: %v", dir, err)
			continue
		}
		// A root-level `required` in a blueprint chart's schema becomes a mandatory field on every
		// Composition CR of this type and stalls the Installer composition's own reconcile. The
		// generator never emits one; this makes a hand-added one fail.
		if _, bad := schema["required"]; bad {
			t.Errorf("%s/values.schema.json has a root-level `required`, which wedges the installer", dir)
		}
		props, _ := schema["properties"].(map[string]interface{})
		if _, ok := props[depAlias]; !ok {
			t.Errorf("%s/values.schema.json does not declare the %q property, so forwarded values are unvalidated", dir, depAlias)
		}
	}
}

// TestGeneratorIsDeterministic regenerates every wrapper into a temp dir and compares byte-for-byte
// with what is committed. This is the check that actually catches a hand-edit anywhere in any of the
// four files, not just the fields enumerated above.
func TestGeneratorIsDeterministic(t *testing.T) {
	l := loadPins(t)
	tmp := t.TempDir()

	for _, c := range l.Controllers {
		data := operatorDataFor(c.Service, c.Version)
		dir := filepath.Join(tmp, data.ChartName)
		if err := writeOperator(dir, data); err != nil {
			t.Fatalf("regenerating %s: %v", data.ChartName, err)
		}
	}

	for _, c := range l.Controllers {
		name := operatorChartName(c.Service)
		for _, f := range []string{"Chart.yaml", "values.yaml", "values.schema.json", "README.md"} {
			got, err := os.ReadFile(filepath.Join(operatorRoot, name, f))
			if err != nil {
				t.Errorf("committed %s/%s: %v", name, f, err)
				continue
			}
			want, err := os.ReadFile(filepath.Join(tmp, name, f))
			if err != nil {
				t.Fatalf("regenerated %s/%s: %v", name, f, err)
			}
			if string(got) != string(want) {
				t.Errorf("%s/%s differs from what the generator produces — re-run the generator instead of editing it by hand", name, f)
			}
		}
	}
}

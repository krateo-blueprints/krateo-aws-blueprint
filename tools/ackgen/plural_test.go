// Guard for the Composition plural this catalogue reproduces.
//
// The plural is not ours to choose. plumbing/crdgen stamps it into the generated Composition
// CRD's spec.names.plural (crdgen/transpile.go:660, Pluralize-then-Lower), core-provider reads it
// back from apiserver discovery, and this generator only RE-DERIVES it to write the customform's
// `resource:` path and the getCRD API path. Re-derive it differently and the chart still builds,
// still lints, still publishes -- and the portal form 404s against a resource path that does not
// exist. Nothing fails at the point of the mistake.
//
// So this walks every generated blueprint in the repo and asserts two things:
//
//  1. the generator's derivation agrees with crdgen's order for every Kind in the catalogue, and
//  2. every plural actually COMMITTED into each blueprint agrees too -- the customform's
//     `resource:` path and the <plural>.composition.krateo.io CRD name the getCRD step addresses
//     -- because (1) passing says nothing about blueprints generated before a fix.
//
// plumbing#47 pins crdgen's side of this contract. This is the downstream half it asks for.
package main

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/gobuffalo/flect"
)

// crdgenPlural is plumbing/crdgen's derivation, transcribed. Kept separate from the generator's
// own compositionPlural so a future edit to one does not silently redefine the thing it is
// checked against.
func crdgenPlural(kind string) string { return strings.ToLower(flect.Pluralize(kind)) }

var (
	chartNameRe = regexp.MustCompile(`(?m)^name:\s*(\S+)\s*$`)
	resourceRe  = regexp.MustCompile(`(?m)^\s*resource:\s*(\S+)\s*$`)
	// The getCRD step addresses the Composition CRD by name, which is <plural>.composition.krateo.io.
	crdRefRe = regexp.MustCompile(`([a-z0-9]+)\.composition\.krateo\.io`)
	prefixRe = regexp.MustCompile(`^(aws|gcp|azure)-`)
)

func TestCompositionPluralMatchesCrdgen(t *testing.T) {
	root := filepath.Join("..", "..", "blueprints")

	var scanned, diverged, committedWrong int
	err := filepath.Walk(root, func(p string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() || info.Name() != "Chart.yaml" {
			return err
		}
		b, err := os.ReadFile(p)
		if err != nil {
			return err
		}
		m := chartNameRe.FindSubmatch(b)
		if m == nil {
			return nil
		}
		chart := string(m[1])
		prefix := prefixRe.FindString(chart)
		if prefix == "" {
			// Not a generated provider blueprint (operator wrappers, stacks).
			return nil
		}
		scanned++

		kind := compositionKind(chart)
		want := crdgenPlural(kind)
		if got := compositionPlural(kind); got != want {
			diverged++
			t.Errorf("derivation: chart %s (Kind %s) -> %q, crdgen stamps %q", chart, kind, got, want)
		}

		// The committed artifacts are what users actually hit. Walk the WHOLE blueprint rather
		// than a list of known filenames: the plural reaches every file that addresses the
		// Composition -- customform.yaml today, portal/ widget and RESTAction manifests as the
		// catalogue grows -- and a guard that enumerates filenames stops covering the files added
		// after it was written, silently.
		blueprintDir := filepath.Dir(filepath.Dir(p))
		provider := strings.TrimSuffix(prefix, "-")
		return filepath.Walk(blueprintDir, func(f string, fi os.FileInfo, ferr error) error {
			if ferr != nil || fi.IsDir() {
				return ferr
			}
			switch filepath.Ext(f) {
			case ".yaml", ".yml", ".md":
			default:
				return nil
			}
			cb, err := os.ReadFile(f)
			if err != nil {
				return err
			}
			for _, mm := range resourceRe.FindAllSubmatch(cb, -1) {
				got := string(mm[1])
				if !strings.HasPrefix(got, provider) {
					// customforms, compositiondefinitions -- platform resources, not ours.
					continue
				}
				if got != want {
					committedWrong++
					t.Errorf("committed: %s references resource %q, but the Composition CRD for Kind %s is %q",
						f, got, kind, want)
				}
			}
			for _, mm := range crdRefRe.FindAllSubmatch(cb, -1) {
				got := string(mm[1])
				if !strings.HasPrefix(got, provider) || got == want {
					continue
				}
				committedWrong++
				t.Errorf("committed: %s addresses CRD %q.composition.krateo.io, but Kind %s is stamped %q",
					f, got, kind, want)
			}
			return nil
		})
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}

	// Assert the walk found the catalogue. A passing test over zero blueprints is the failure
	// mode this guard is most likely to decay into -- a moved directory makes it vacuous.
	if scanned == 0 {
		t.Fatalf("walked %s and matched no provider blueprint: this test proved nothing", root)
	}
	t.Logf("checked %d blueprints: %d derivation divergences, %d wrong plurals committed",
		scanned, diverged, committedWrong)
}

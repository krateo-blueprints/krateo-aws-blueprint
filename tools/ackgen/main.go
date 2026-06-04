// Command ackgen generates a Krateo AWS blueprint from an ACK CRD.
//
// It reads a CustomResourceDefinition (file or URL), projects its served-version spec schema
// into a crdgen-safe values.schema.json, and renders a full blueprint directory
// (chart + CompositionDefinition + customform + README) under <out>/<service>/<resource>.
//
// Usage:
//
//	ackgen -crd <file|url> [-version v1alpha1] [-out blueprints] [-chart-version 0.1.0] [-lint]
package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	crdSrc := flag.String("crd", "", "path or URL to an ACK CustomResourceDefinition (required)")
	version := flag.String("version", "", "CRD version to target (default: storage/served version)")
	outRoot := flag.String("out", "blueprints", "output root directory for blueprints")
	chartVersion := flag.String("chart-version", "0.1.0", "chart/Composition version to stamp into CompositionDefinition and customform")
	doLint := flag.Bool("lint", false, "run `helm lint` + `helm template` on the generated chart (requires helm)")
	flag.Parse()

	if *crdSrc == "" {
		fmt.Fprintln(os.Stderr, "error: -crd is required")
		flag.Usage()
		os.Exit(2)
	}

	if err := run(*crdSrc, *version, *outRoot, *chartVersion, *doLint); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run(crdSrc, version, outRoot, chartVersion string, doLint bool) error {
	c, err := loadCRD(crdSrc)
	if err != nil {
		return err
	}
	ver, err := c.pickVersion(version)
	if err != nil {
		return err
	}
	spec, err := ver.specSchema()
	if err != nil {
		return err
	}

	service := serviceFromGroup(c.Spec.Group)
	kind := c.Spec.Names.Kind
	cn := chartName(service, kind)
	compKind := compositionKind(cn)
	title := fmt.Sprintf("AWS %s %s", titleCaseService(service), kind)

	data := blueprintData{
		Group:        c.Spec.Group,
		AckVersion:   ver.Name,
		AckKind:      kind,
		AckKindLower: strings.ToLower(kind),
		Service:      service,
		ServiceTitle: titleCaseService(service),
		ChartName:    cn,
		CompKind:     compKind,
		CompPlural:   compositionPlural(compKind),
		CompVersion:  compositionVersion(chartVersion),
		ChartVersion: chartVersion,
		Namespace:    "aws-" + service + "-system",
		Title:        title,
	}

	schema := buildValuesSchema(spec, title,
		fmt.Sprintf("Provision an AWS %s %s via the ACK %s controller. Fields mirror the %s/%s %s spec.",
			data.ServiceTitle, kind, service, data.Group, data.AckVersion, kind))
	schemaJSON, err := marshalSchema(schema)
	if err != nil {
		return err
	}

	// Seed values.yaml from a minimal-valid instance of the curated spec, plus region.
	values, _ := minimalValid(curate(spec)).(map[string]interface{})
	if values == nil {
		values = map[string]interface{}{}
	}
	values["region"] = ""
	valuesYAML, err := marshalValues(values, data)
	if err != nil {
		return err
	}

	outDir := filepath.Join(outRoot, service, data.AckKindLower)
	if err := writeBlueprint(outDir, data, schemaJSON, valuesYAML); err != nil {
		return err
	}
	fmt.Printf("generated %s\n  chart=%s kind=%s plural=%s version=%s\n",
		outDir, cn, compKind, data.CompPlural, data.CompVersion)

	if doLint {
		if err := lintChart(filepath.Join(outDir, "chart")); err != nil {
			return fmt.Errorf("lint failed: %w", err)
		}
		fmt.Println("  helm lint + template: OK")
	}
	return nil
}

// lintChart stamps a temp version into a copy of the chart and runs helm lint + template.
func lintChart(chartDir string) error {
	helm, err := exec.LookPath("helm")
	if err != nil {
		return fmt.Errorf("helm not found in PATH")
	}

	tmp, err := os.MkdirTemp("", "ackgen-lint-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmp)
	dst := filepath.Join(tmp, "chart")
	if out, err := exec.Command("cp", "-r", chartDir, dst).CombinedOutput(); err != nil {
		return fmt.Errorf("copy chart: %v: %s", err, out)
	}

	chartYaml := filepath.Join(dst, "Chart.yaml")
	b, err := os.ReadFile(chartYaml)
	if err != nil {
		return err
	}
	if err := os.WriteFile(chartYaml, []byte(strings.ReplaceAll(string(b), "CHART_VERSION", "0.0.0-ci")), 0o644); err != nil {
		return err
	}

	for _, args := range [][]string{
		{"lint", dst},
		{"template", "release", dst, "--namespace", "ackgen-test"},
	} {
		cmd := exec.Command(helm, args...)
		if out, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("helm %s: %v\n%s", args[0], err, out)
		}
	}
	return nil
}

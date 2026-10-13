package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"sigs.k8s.io/yaml"
)

// operatorList is the committed pin file (tools/ackgen/ack-controllers.yaml). It is the input of
// record for every wrapper under operator/: the generator never resolves "latest" from the
// registry, so two runs produce identical bytes and a regeneration diff is reviewable.
type operatorList struct {
	Controllers []struct {
		Service string `json:"service"`
		Version string `json:"version"`
	} `json:"controllers"`
}

// operatorData is the substitution context for the operator-wrapper templates.
type operatorData struct {
	Service      string // s3
	ServiceTitle string // S3
	ChartName    string // krateo-aws-ack-s3
	DepName      string // s3-chart  (the upstream chart's own metadata.name)
	DepRepo      string // oci://public.ecr.aws/aws-controllers-k8s
	DepVersion   string // 1.13.0
	DepAlias     string // ack
	Namespace    string // ack-system
}

// depAlias is the Helm dependency alias every wrapper uses, and the single reason the 67 wrappers
// can share one values shape.
//
// Without it the values key would be the upstream chart's own name — `s3-chart:`, `ec2-chart:` —
// so every wrapper would need a different schema and a different values path, and a Composition
// author moving between services would have to re-learn the key each time. Aliasing to `ack:`
// makes `ack.aws.region` mean the same thing in all of them, which is what lets one template and
// one schema cover the catalogue. (Same idiom as the kagent wrappers, which alias their deps.)
const depAlias = "ack"

// ackChartRepo is the anonymous-pullable OCI registry AWS publishes the controller charts to.
// Helm resolves `oci://<registry>/<path>` + dependency name, so the dependency's `name` must be
// the upstream chart's real name (`<service>-chart`), not the service.
const ackChartRepo = "oci://public.ecr.aws/aws-controllers-k8s"

// loadOperatorList reads and validates the pin file.
func loadOperatorList(path string) (*operatorList, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("reading controller pin list: %w", err)
	}
	var l operatorList
	if err := yaml.Unmarshal(raw, &l); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	if len(l.Controllers) == 0 {
		return nil, fmt.Errorf("%s declares no controllers", path)
	}
	seen := map[string]string{}
	for _, c := range l.Controllers {
		switch {
		case c.Service == "":
			return nil, fmt.Errorf("%s: an entry has no service", path)
		case c.Version == "":
			return nil, fmt.Errorf("%s: service %q has no version", path, c.Service)
		}
		if prev, dup := seen[c.Service]; dup {
			return nil, fmt.Errorf("%s: service %q listed twice (%s and %s)", path, c.Service, prev, c.Version)
		}
		seen[c.Service] = c.Version
	}
	sort.Slice(l.Controllers, func(i, j int) bool {
		return l.Controllers[i].Service < l.Controllers[j].Service
	})
	return &l, nil
}

// operatorDataFor builds the template context for one service.
func operatorDataFor(service, version string) operatorData {
	return operatorData{
		Service:      service,
		ServiceTitle: titleCaseService(service),
		ChartName:    operatorChartName(service),
		DepName:      service + "-chart",
		DepRepo:      ackChartRepo,
		DepVersion:   version,
		DepAlias:     depAlias,
		Namespace:    "ack-system",
	}
}

// operatorChartName builds the wrapper chart name, e.g. krateo-aws-ack-s3. The krateo- prefix and
// the provider segment match the sibling catalogues (krateo-azure-aso, krateo-gcp-configconnector).
func operatorChartName(service string) string {
	return "krateo-aws-ack-" + service
}

// runOperators generates every wrapper listed in the pin file.
func runOperators(listPath, outRoot string, doLint bool) error {
	list, err := loadOperatorList(listPath)
	if err != nil {
		return err
	}
	for _, c := range list.Controllers {
		data := operatorDataFor(c.Service, c.Version)
		dir := filepath.Join(outRoot, data.ChartName)
		if err := writeOperator(dir, data); err != nil {
			return fmt.Errorf("%s: %w", data.ChartName, err)
		}
		fmt.Printf("generated %s\n  dep=%s/%s:%s alias=%s\n",
			dir, data.DepRepo, data.DepName, data.DepVersion, data.DepAlias)
	}
	fmt.Printf("%d operator wrappers written to %s/\n", len(list.Controllers), outRoot)

	// Linting is opt-in because it needs the network: `helm template` on a wrapper must first pull
	// the upstream dependency, and a 67-chart pull is slow enough that CI lints these in its own
	// job rather than inside generation.
	if doLint {
		for _, c := range list.Controllers {
			dir := filepath.Join(outRoot, operatorChartName(c.Service))
			if err := lintOperator(dir); err != nil {
				return fmt.Errorf("lint %s: %w", dir, err)
			}
			fmt.Printf("  lint %s: OK\n", dir)
		}
	}
	return nil
}

// writeOperator materializes one wrapper chart directory. A wrapper is metadata only — Chart.yaml,
// values.yaml, values.schema.json, README.md — with no templates/ of its own: everything it
// deploys comes from the upstream dependency.
//
// There is deliberately NO companion -crds chart. The upstream ACK chart ships its service CRDs in
// its own crds/ directory (s3-chart/crds/ holds s3.services.k8s.aws_buckets.yaml plus the shared
// services.k8s.aws fieldexports/iamroleselectors), so helm installs them with the controller. This
// matches krateo-azure-aso, where ASO installs its resource CRDs at runtime, and differs from
// krateo-gcp-configconnector, which needs a -crds chart only because Config Connector's own
// operator CRDs arrive in a plain YAML bundle.
func writeOperator(dir string, data operatorData) error {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	files := []struct{ tmpl, dst string }{
		{"operator-chart.yaml.tmpl", filepath.Join(dir, "Chart.yaml")},
		{"operator-values.yaml.tmpl", filepath.Join(dir, "values.yaml")},
		{"operator-values.schema.json.tmpl", filepath.Join(dir, "values.schema.json")},
		{"operator-readme.md.tmpl", filepath.Join(dir, "README.md")},
	}
	for _, f := range files {
		if err := renderAny(f.tmpl, f.dst, data); err != nil {
			return err
		}
	}
	return nil
}

// lintOperator stamps a temp version and runs `helm dependency update` + `helm template`. The
// dependency pull is what makes this authoritative: it proves the pinned upstream version exists
// and that the forwarded values satisfy the UPSTREAM chart's own values.schema.json, which a
// wrapper cannot check by itself.
func lintOperator(dir string) error {
	tmp, err := os.MkdirTemp("", "ackgen-op-lint-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmp)
	dst := filepath.Join(tmp, filepath.Base(dir))
	if err := copyTree(dir, dst); err != nil {
		return err
	}
	chartYaml := filepath.Join(dst, "Chart.yaml")
	b, err := os.ReadFile(chartYaml)
	if err != nil {
		return err
	}
	if err := os.WriteFile(chartYaml, []byte(strings.ReplaceAll(string(b), "CHART_VERSION", "0.0.0-ci")), 0o644); err != nil {
		return err
	}
	if out, err := runHelm("dependency", "update", dst); err != nil {
		return fmt.Errorf("helm dependency update: %v\n%s", err, out)
	}
	if out, err := runHelm("template", "release", dst, "--namespace", "ack-system"); err != nil {
		return fmt.Errorf("helm template: %v\n%s", err, out)
	}
	return nil
}

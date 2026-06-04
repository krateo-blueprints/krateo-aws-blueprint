package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	"sigs.k8s.io/yaml"
)

// crd is the slice of a CustomResourceDefinition we need.
type crd struct {
	Spec struct {
		Group string `json:"group"`
		Names struct {
			Kind     string `json:"kind"`
			Plural   string `json:"plural"`
			Singular string `json:"singular"`
		} `json:"names"`
		Versions []crdVersion `json:"versions"`
	} `json:"spec"`
}

type crdVersion struct {
	Name    string `json:"name"`
	Served  bool   `json:"served"`
	Storage bool   `json:"storage"`
	Schema  struct {
		OpenAPIV3Schema map[string]interface{} `json:"openAPIV3Schema"`
	} `json:"schema"`
}

// readSource loads a CRD document from a local path or an http(s) URL.
func readSource(src string) ([]byte, error) {
	if strings.HasPrefix(src, "http://") || strings.HasPrefix(src, "https://") {
		resp, err := http.Get(src)
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("GET %s: %s", src, resp.Status)
		}
		return io.ReadAll(resp.Body)
	}
	return os.ReadFile(src)
}

// loadCRD parses a single-document CRD YAML/JSON.
func loadCRD(src string) (*crd, error) {
	raw, err := readSource(src)
	if err != nil {
		return nil, err
	}
	var c crd
	if err := yaml.Unmarshal(raw, &c); err != nil {
		return nil, fmt.Errorf("parse CRD: %w", err)
	}
	if c.Spec.Group == "" || c.Spec.Names.Kind == "" {
		return nil, fmt.Errorf("document does not look like a CRD (missing spec.group / spec.names.kind)")
	}
	return &c, nil
}

// pickVersion chooses the served version to target: an explicit name if given, else the
// storage version, else the first served version.
func (c *crd) pickVersion(want string) (*crdVersion, error) {
	var firstServed *crdVersion
	for i := range c.Spec.Versions {
		v := &c.Spec.Versions[i]
		if want != "" && v.Name == want {
			return v, nil
		}
		if want == "" {
			if v.Storage && v.Served {
				return v, nil
			}
			if firstServed == nil && v.Served {
				firstServed = v
			}
		}
	}
	if want != "" {
		return nil, fmt.Errorf("version %q not found in CRD", want)
	}
	if firstServed != nil {
		return firstServed, nil
	}
	return nil, fmt.Errorf("no served version found in CRD")
}

// specSchema returns the openAPIV3Schema.properties.spec subschema for a version.
func (v *crdVersion) specSchema() (map[string]interface{}, error) {
	props, _ := v.Schema.OpenAPIV3Schema["properties"].(map[string]interface{})
	spec, ok := props["spec"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("openAPIV3Schema has no properties.spec object")
	}
	return spec, nil
}

package main

import (
	"bytes"
	"strings"
	"unicode"

	"github.com/gobuffalo/flect"
)

// toGolangName mirrors krateoplatformops core-provider's internal strutil.ToGolangName so the
// Kind we compute matches the one core-provider derives from the chart name.
func toGolangName(s string) string {
	buf := bytes.NewBuffer([]byte{})
	for i, v := range splitOnAll(s, isNotAGoNameCharacter) {
		if i == 0 && strings.IndexAny(v, "0123456789") == 0 {
			buf.WriteRune('_')
		}
		buf.WriteString(capitaliseFirstLetter(v))
	}
	return buf.String()
}

func capitaliseFirstLetter(s string) string {
	if s == "" {
		return s
	}
	return strings.ToUpper(s[0:1]) + s[1:]
}

func splitOnAll(s string, shouldSplit func(r rune) bool) []string {
	rv := []string{}
	buf := bytes.NewBuffer([]byte{})
	for _, c := range s {
		if shouldSplit(c) {
			rv = append(rv, buf.String())
			buf.Reset()
		} else {
			buf.WriteRune(c)
		}
	}
	if buf.Len() > 0 {
		rv = append(rv, buf.String())
	}
	return rv
}

func isNotAGoNameCharacter(r rune) bool {
	return !(unicode.IsLetter(r) || unicode.IsDigit(r))
}

// compositionKind reproduces core-provider's gvr.go: flect.Pascalize(toGolangName(chartName)).
func compositionKind(chartName string) string {
	return flect.Pascalize(toGolangName(chartName))
}

// compositionPlural reproduces core-provider: flect.Pluralize(strings.ToLower(kind)).
func compositionPlural(kind string) string {
	return flect.Pluralize(strings.ToLower(kind))
}

// serviceFromGroup turns an ACK API group like "s3.services.k8s.aws" into "s3".
func serviceFromGroup(group string) string {
	if i := strings.Index(group, "."); i > 0 {
		return group[:i]
	}
	return group
}

// chartName builds the blueprint chart name, e.g. aws-s3-bucket.
func chartName(service, kind string) string {
	return "aws-" + service + "-" + strings.ToLower(kind)
}

// compositionVersion maps a chart semver (0.1.0) to the Composition CRD version (v0-1-0).
func compositionVersion(chartVersion string) string {
	return "v" + strings.ReplaceAll(chartVersion, ".", "-")
}

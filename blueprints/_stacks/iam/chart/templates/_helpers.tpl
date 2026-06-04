{{/* Common labels for every ACK resource in the stack. */}}
{{- define "aws-iam-stack.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}

{{/* Render an ACK tag list from a Terraform-style map(string). Use with `nindent`. */}}
{{- define "aws-iam-stack.tags" -}}
{{- range $k, $v := . }}
- key: {{ $k | quote }}
  value: {{ $v | quote }}
{{- end }}
{{- end -}}

{{/*
Build a sts:AssumeRole trust policy document (JSON string) from a list of AWS service
principals (trusted_role_services). Mirrors terraform-aws-modules/iam assume_role_policy
generation. Call with the services list.
*/}}
{{- define "aws-iam-stack.assumeRolePolicy" -}}
{{- $services := . -}}
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":[{{- range $i, $s := $services }}{{ if $i }},{{ end }}{{ $s | quote }}{{- end }}]},"Action":"sts:AssumeRole"}]}
{{- end -}}

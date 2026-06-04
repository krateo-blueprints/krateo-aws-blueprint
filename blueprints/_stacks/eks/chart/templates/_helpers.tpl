{{/* Common labels for every ACK resource in the stack. */}}
{{- define "aws-eks-stack.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}

{{/* Render an ACK tag map (object) from a Terraform-style map(string). Use with `nindent`. */}}
{{- define "aws-eks-stack.tags" -}}
{{- range $k, $v := . }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{- end -}}

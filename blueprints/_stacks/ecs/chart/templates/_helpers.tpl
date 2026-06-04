{{/* Common labels for every ACK resource in the stack. */}}
{{- define "aws-ecs-stack.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}

{{/* Render an ACK tag list from a Terraform-style map(string). Use with `nindent`. */}}
{{- define "aws-ecs-stack.tags" -}}
{{- range $k, $v := . }}
- key: {{ $k | quote }}
  value: {{ $v | quote }}
{{- end }}
{{- end -}}
